require 'spec_helper'

require 'cli'

describe Bosh::Cli::Command::JobManagement do
  include FakeFS::SpecHelpers

  let(:command) { described_class.new }
  let(:director) { instance_double('Bosh::Cli::Client::Director', uuid: 'uuid') }
  let(:deployment) { 'deployment' }
  let(:manifest) do
    {
      'name' => deployment,
      'director_uuid' => director.uuid,
      'releases' => [],
      'jobs' => [{'name' => 'dea', 'instances' => instances}]
    }.to_yaml
  end

  before(:each) do
    allow(director).to receive(:change_job_state).and_return(:done, nil, '')
    allow(command).to receive_messages(target: 'http://bosh.example.com')
    allow(command).to receive_messages(logged_in?: true)
    allow(command).to receive_messages(inspect_deployment_changes: false)
    allow(command).to receive(:nl)
    allow(command).to receive_messages(confirmed?: true)
    allow(command).to receive(:director).and_return(director)

    allow(command).to receive(:deployment).and_return(deployment)
    File.open(deployment, 'w') { |f| f.write(manifest) }

    allow(command).to receive(:show_current_state)
  end

  shared_examples_for 'a state change command' do |options|
    verb     = options[:verb]
    job      = options[:job]
    index    = options[:index]
    desc     = job ? [job, (index || 'ALL')].join('/') : 'all jobs'
    method   = :"#{verb}_job"
    message  = options[:message] || verb

    results = {
      default: verb.to_s,
      start:   'started',
      stop:    'stopped',
      detach:  'detached'
    }
    warnings = {
      default: "You are about to #{verb} #{desc}",
      detach:  "You are about to stop #{desc} and power off its VM(s)"
    }
    performs = {
      default: "Performing '#{verb} #{desc}'...",
      detach:  "Performing 'stop #{desc} and power off its VM(s)'..."
    }
    confirmations = {
      default:  "#{desc} #{verb}ed",
      detach:   "#{desc} detached, VM(s) powered off",
      recreate: "#{desc} recreated",
      stop:     "#{desc} stopped, VM(s) still running"
    }

    result  = results[message] || results[:default]
    warning = warnings[message] || warnings[:default]
    perform = performs[message] || performs[:default]
    confirmation = confirmations[message] || confirmations[:default]

    it_requires_logged_in_user ->(command) { command.public_send(method, job) }

    context 'given --hard or --soft options' do
      it 'does not allow both' do
        command.options[:hard] = true
        command.options[:soft] = true

        expect {
          command.public_send(method, job, index)
        }.to raise_error(Bosh::Cli::CliError, 'Cannot handle both --hard and --soft options, please choose one')
      end

      it 'errors if unsupported for the operation' do
        next if method == :stop_job

        command.options[:hard] = true

        expect {
          command.public_send(method, job, index)
        }.to raise_error(Bosh::Cli::CliError, "--hard and --soft options only make sense for 'stop' operation")
      end
    end

    context 'given a job' do
      it 'reports on the pending action' do
        expect(command).to receive(:say).with(warning)
        expect(command).to receive(:say).with(perform)
        expect(command).to receive(:say).with("\n#{confirmation}")

        command.public_send(method, job, index)
      end

      it 'changes the job state' do
        expect(director).to receive(:change_job_state).with(deployment, manifest, result, job, index)

        command.public_send(method, job, index)
      end

      it 'reports on the task result' do
        allow(director).to receive_messages(change_job_state: %w(done 23))
        expect(command).to receive(:task_report).with('done', '23', confirmation)

        command.public_send(method, job, index)
      end
    end

    context 'running interactively' do
      before do
        command.options[:non_interactive] = false
      end

      context 'without command confirmation' do
        before do
          allow(command).to receive(:say)
          allow(command).to receive_messages(confirmed?: false)
          # ???
          # allow(command).to receive_messages(inspect_deployment_changes: false)
        end

        it 'cancels the operation' do
          expect {
            command.public_send(method, job, index)
          }.to raise_error(Bosh::Cli::GracefulExit, 'Deployment canceled')
        end
      end

      context 'when the manifest has changed and --force is not provided' do
        before do
          allow(command).to receive_messages(inspect_deployment_changes: true)
        end

        it 'cancels the operation' do
          expect {
            command.public_send(method, job, index)
          }.to raise_error(Bosh::Cli::CliError, "Cannot perform job management when other deployment " +
              "changes are present. Please use '--force' to override.")
        end
      end
    end
  end

  # ---

  describe 'starting jobs' do
    context 'given no job name' do
      let(:instances) { 3 }

      it_behaves_like 'a state change command',
        verb: :start
    end

    context 'given a job and one instance' do
      let(:instances) { 1 }

      it_behaves_like 'a state change command',
        verb: :start, job: 'jobName'
    end

    context 'given a job and many instances' do
      let(:instances) { 3 }

      context 'and an index is provided' do
        it_behaves_like 'a state change command',
          verb: :start, job: 'jobName', index: 0
      end

      context 'and an index is not provided' do
        it_behaves_like 'a state change command',
          verb: :start, job: 'jobName'
      end
    end
  end

  describe 'stopping jobs' do
    context 'given no job name' do
      let(:instances) { 3 }

      it_behaves_like 'a state change command',
        verb: :stop
    end

    context 'given a job and one instance' do
      let(:instances) { 1 }

      it_behaves_like 'a state change command',
        verb: :stop, job: 'jobName'
    end

    context 'given a job and many instances' do
      let(:instances) { 3 }

      context 'and an index is provided' do
        it_behaves_like 'a state change command',
          verb: :stop, job: 'jobName', index: 0
      end

      context 'and an index is not provided' do
        it_behaves_like 'a state change command',
          verb: :stop, job: 'jobName'
      end
    end
  end

  describe 'restarting jobs' do
    context 'given no job name' do
      let(:instances) { 3 }

      it_behaves_like 'a state change command',
        verb: :restart
    end

    context 'given a job and one instance' do
      let(:instances) { 1 }

      it_behaves_like 'a state change command',
        verb: :restart, job: 'jobName'
    end

    context 'given a job and many instances' do
      let(:instances) { 3 }

      context 'and an index is provided' do
        it_behaves_like 'a state change command',
          verb: :restart, job: 'jobName', index: 0
      end

      context 'and an index is not provided' do
        it_behaves_like 'a state change command',
          verb: :restart, job: 'jobName'
      end
    end
  end

  describe 'recreating jobs' do
    context 'given no job name' do
      let(:instances) { 3 }

      it_behaves_like 'a state change command',
        verb: :recreate
    end

    context 'given a job and one instance' do
      let(:instances) { 1 }

      it_behaves_like 'a state change command',
        verb: :recreate, job: 'jobName'
    end

    context 'given a job and many instances' do
      let(:instances) { 3 }

      context 'and an index is provided' do
        it_behaves_like 'a state change command',
          verb: :recreate, job: 'jobName', index: 0
      end

      context 'and an index is not provided' do
        it_behaves_like 'a state change command',
          verb: :recreate, job: 'jobName'
      end
    end
  end
end
