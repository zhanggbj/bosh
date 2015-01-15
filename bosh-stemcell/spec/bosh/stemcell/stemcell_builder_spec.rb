require 'spec_helper'
require 'bosh/stemcell/stemcell_builder'
require 'bosh/dev/gem_components'
require 'bosh/stemcell/build_environment'
require 'bosh/stemcell/stage_collection'
require 'bosh/stemcell/stage_runner'

describe Bosh::Stemcell::StemcellBuilder do
  subject(:builder) do
    described_class.new(
      gem_components: gem_components,
      environment: environment,
      runner: runner,
      definition: definition,
    )
  end

  let(:env) { {} }
  let(:infrastructure) { Bosh::Stemcell::Infrastructure.for('null') }
  let(:operating_system) { Bosh::Stemcell::OperatingSystem.for('centos') }
  let(:definition) { Bosh::Stemcell::Definition.new(infrastructure, 'fake_hypervisor', operating_system, Bosh::Stemcell::Agent.for('go'), false) }
  let(:version) { 1 }
  let(:release_tarball_path) { '/path/to/release.tgz' }
  let(:os_image_tarball_path) { '/path/to/os-img.tgz' }
  let(:gem_components) { instance_double('Bosh::Dev::GemComponents', build_release_gems: nil) }
  let(:environment) { Bosh::Stemcell::BuildEnvironment.new(env, definition, version, release_tarball_path, os_image_tarball_path) }
  let(:collection) do
    instance_double(
      'Bosh::Stemcell::StageCollection',
      extract_operating_system_stages: [:extract_stage],
      build_stemcell_image_stages: [:build_stage],
      package_stemcell_stages: [:package_stage],
      agent_stages: [:agent_stage],
    )
  end
  let(:runner) { instance_double('Bosh::Stemcell::StageRunner', configure_and_apply: nil) }
  before do
    allow(Bosh::Stemcell::StageCollection).to receive(:new).and_return(collection)
    allow(environment).to receive(:prepare_build)
    allow(infrastructure).to receive(:disk_formats).and_return(['raw'])
  end

  describe '#build' do
    it 'builds the gem components' do
      expect(gem_components).to receive(:build_release_gems)
      builder.build
    end

    it 'prepares the build environment' do
      expect(environment).to receive(:prepare_build)
      builder.build
    end

    it 'runs the extract OS, agent, and infrastructure stages' do
      expect(runner).to receive(:configure_and_apply).with([:extract_stage, :agent_stage, :build_stage])
      expect(runner).to receive(:configure_and_apply).with([:package_stage])

      builder.build
    end

    context 'for infrastructures that require multiple disk formats to be produced' do
      before do
        allow(infrastructure).to receive(:disk_formats).and_return(["qcow2", "raw"])
        allow(collection).to receive(:package_stemcell_stages).with("qcow2").and_return([:package_qcow2_stage])
        allow(collection).to receive(:package_stemcell_stages).with("raw").and_return([:package_raw_stage])
      end

      it 'runs multiple package stages' do
        expect(runner).to receive(:configure_and_apply).with([:extract_stage, :agent_stage, :build_stage])
        expect(runner).to receive(:configure_and_apply).with([:package_qcow2_stage])
        expect(runner).to receive(:configure_and_apply).with([:package_raw_stage])

        builder.build
      end
    end
  end
end
