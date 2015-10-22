require 'spec_helper'
require 'cli'

describe Bosh::Cli::Command::CloudCheck do
  let(:command) { described_class.new }
  let(:director) { instance_double('Bosh::Cli::Client::Director') }
  let(:target) { 'http://example.org' }

  before(:each) do
    allow(command).to receive(:director).and_return(director)
    allow(command).to receive(:nl)
    allow(command).to receive(:logged_in?).and_return(true)
    command.options[:target] = target
    allow(command).to receive(:show_current_state)
  end

  describe 'perform' do
    with_deployment

    context 'when the status does not report as "done"' do
      it 'exits with a non-zero status code' do
        # allow(director).to receive(:perform_cloud_scan)
        expect(director).to receive(:perform_cloud_scan).and_return([:done,nil])
        allow(command).to receive(:prepare_deployment_manifest).and_return(double(:manifest, name: 'fake-deployment'))
        command.perform
      end
    end
  end
end
