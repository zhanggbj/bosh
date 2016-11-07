require 'spec_helper'

module Bosh::Director::DeploymentPlan
  describe InstanceSpec do
    include Support::StemcellHelpers
    subject(:instance_spec) { described_class.create_from_instance_plan(instance_plan)}
    let(:job_spec) { {'name' => 'job', 'release' => 'release', 'templates' => []} }
    let(:packages) { {'pkg' => {'name' => 'package', 'version' => '1.0'}} }
    let(:properties) { {'key' => 'value'} }
    let(:links) { {'link_name' => LinkInfo.new('dep1', {'stuff' => 'foo'})} }
    let(:expected_links) {{'link_name' => {'stuff' => 'foo'}}}
    let(:lifecycle) { InstanceGroup::DEFAULT_LIFECYCLE_PROFILE }
    let(:network_spec) do
      {'name' => 'default', 'subnets' => [{'cloud_properties' => {'foo' => 'bar'}, 'az' => 'foo-az'}]}
    end
    let(:network) { DynamicNetwork.parse(network_spec, [AvailabilityZone.new('foo-az', {})], logger) }
    let(:job) {
      job = instance_double('Bosh::Director::DeploymentPlan::InstanceGroup',
        name: 'fake-job',
        spec: job_spec,
        canonical_name: 'job',
        instances: ['instance0'],
        default_network: {"gateway" => "default"},
        vm_type: vm_type,
        vm_extensions: [],
        stemcell: stemcell,
        env: env,
        package_spec: packages,
        persistent_disk_collection: persistent_disk_collection,
        is_errand?: false,
        resolved_links: links,
        compilation?: false,
        update_spec: {},
        properties: properties,
        lifecycle: lifecycle,
      )
    }
    let(:index) { 0 }
    let(:instance_state) { {} }
    let(:instance) { Instance.create_from_job(job, index, 'started', plan, instance_state, availability_zone, logger) }
    let(:vm_type) { VmType.new({'name' => 'fake-vm-type'}) }
    let(:availability_zone) { Bosh::Director::DeploymentPlan::AvailabilityZone.new('foo-az', {'a' => 'b'}) }
    let(:stemcell) { make_stemcell({:name => 'fake-stemcell-name', :version => '1.0'}) }
    let(:env) { Env.new({'key' => 'value'}) }
    let(:plan) do
      instance_double('Bosh::Director::DeploymentPlan::Planner', {
          name: 'fake-deployment',
          model: deployment,
        })
    end
    let(:deployment) { Bosh::Director::Models::Deployment.make(name: 'fake-deployment') }
    let(:instance_model) { Bosh::Director::Models::Instance.make(deployment: deployment, bootstrap: true, uuid: 'uuid-1') }
    let(:instance_plan) { InstancePlan.new(existing_instance: nil, desired_instance: DesiredInstance.new(job), instance: instance) }
    let(:persistent_disk_collection) { PersistentDiskCollection.new(logger) }

    before do
      persistent_disk_collection.add_by_disk_size(0)

      reservation = Bosh::Director::DesiredNetworkReservation.new_dynamic(instance.model, network)
      reservation.resolve_ip('192.168.0.10')

      instance_plan.network_plans << NetworkPlanner::Plan.new(reservation: reservation)
      instance.bind_existing_instance_model(instance_model)
    end

    describe '#apply_spec' do
      it 'returns a valid instance apply_spec' do
        network_name = network_spec['name']
        spec = instance_spec.as_apply_spec
        expect(spec['deployment']).to eq('fake-deployment')
        expect(spec['name']).to eq('fake-job')
        expect(spec['job']).to eq(job_spec)
        expect(spec['az']).to eq('foo-az')
        expect(spec['index']).to eq(index)
        expect(spec['networks']).to include(network_name)

        expect(spec['networks'][network_name]).to eq({
            'type' => 'dynamic',
            'cloud_properties' => network_spec['subnets'].first['cloud_properties'],
            'default' => ['gateway']
            })

        expect(spec['packages']).to eq(packages)
        expect(spec['persistent_disk']).to eq(0)
        expect(spec['configuration_hash']).to be_nil
        expect(spec['dns_domain_name']).to eq('bosh')
        expect(spec['id']).to eq('uuid-1')
      end

      it 'includes rendered_templates_archive key after rendered templates were archived' do
        instance.rendered_templates_archive =
          Bosh::Director::Core::Templates::RenderedTemplatesArchive.new('fake-blobstore-id', 'fake-sha1')

        expect(instance_spec.as_apply_spec['rendered_templates_archive']).to eq(
            'blobstore_id' => 'fake-blobstore-id',
            'sha1' => 'fake-sha1',
          )
      end

      it 'does not include rendered_templates_archive key before rendered templates were archived' do
        expect(instance_spec.as_apply_spec).to_not have_key('rendered_templates_archive')
      end
    end

    describe '#template_spec' do
      context 'properties interpolation' do
        let(:client_factory) { double(Bosh::Director::ConfigServer::ClientFactory) }
        let(:config_server_client) { double(Bosh::Director::ConfigServer::EnabledClient) }

        let(:properties) do
          {
            'smurf_1' => '((smurf_placeholder_1))',
            'smurf_2' => '((smurf_placeholder_2))'
          }
        end

        let(:links) do
          {
            'link_1' => LinkInfo.new('dep1', first_link),
            'link_2' => LinkInfo.new('dep2', second_link)
          }
        end

        let(:first_link) do
          {'networks' => 'foo', 'properties' => {'smurf' => '((smurf_val1))'}}
        end

        let(:second_link) do
          {'netwroks' => 'foo2', 'properties' => {'smurf' => '((smurf_val2))'}}
        end

        let(:resolved_properties) do
          {
            'smurf_1' => 'lazy smurf',
            'smurf_2' => 'happy smurf'
          }
        end

        let(:resolved_first_link) do
          {'networks' => 'foo', 'properties' => {'smurf' => 'strong smurf'}}
        end

        let(:resolved_second_link) do
          {'netwroks' => 'foo2', 'properties' => {'smurf' => 'sleepy smurf'}}
        end

        let(:resolved_links) do
          {
            'link_1' => resolved_first_link,
            'link_2' => resolved_second_link,
          }
        end

        before do
          allow(Bosh::Director::ConfigServer::ClientFactory).to receive(:create).and_return(client_factory)
          allow(client_factory).to receive(:create_client).and_return(config_server_client)
        end

        it 'resolves properties and links properties' do
          expect(config_server_client).to receive(:interpolate).with(properties).and_return(resolved_properties)
          expect(config_server_client).to receive(:interpolate).with(first_link).and_return(resolved_first_link)
          expect(config_server_client).to receive(:interpolate).with(second_link).and_return(resolved_second_link)

          spec = instance_spec.as_template_spec
          expect(spec['properties']).to eq(resolved_properties)
          expect(spec['links']).to eq(resolved_links)
        end
      end

      context 'when job has a manual network' do
        let(:subnet_spec) do
          {
            'range' => '192.168.0.0/24',
            'gateway' => '192.168.0.254',
            'cloud_properties' => {'foo' => 'bar'}
          }
        end
        let(:subnet) { ManualNetworkSubnet.parse(network_spec['name'], subnet_spec, [availability_zone], []) }
        let(:network) { ManualNetwork.new(network_spec['name'], [subnet], logger) }

        it 'returns a valid instance template_spec' do
          network_name = network_spec['name']
          spec = instance_spec.as_template_spec

          expect(spec['deployment']).to eq('fake-deployment')
          expect(spec['name']).to eq('fake-job')
          expect(spec['job']).to eq(job_spec)
          expect(spec['index']).to eq(index)
          expect(spec['networks']).to include(network_name)

          expect(spec['networks'][network_name]).to include({
                'ip' => '192.168.0.10',
                'netmask' => '255.255.255.0',
                'cloud_properties' => {'foo' => 'bar'},
                'dns_record_name' => '0.job.default.fake-deployment.bosh',
                'gateway' => '192.168.0.254'
                })

          expect(spec['persistent_disk']).to eq(0)
          expect(spec['configuration_hash']).to be_nil
          expect(spec['properties']).to eq(properties)
          expect(spec['dns_domain_name']).to eq('bosh')
          expect(spec['links']).to eq(expected_links)
          expect(spec['id']).to eq('uuid-1')
          expect(spec['az']).to eq('foo-az')
          expect(spec['bootstrap']).to eq(true)
          expect(spec['resource_pool']).to eq('fake-vm-type')
          expect(spec['address']).to eq('192.168.0.10')
          expect(spec['ip']).to eq('192.168.0.10')
        end
      end

      context 'when job has dynamic network' do
        context 'when vm does not have network ip assigned' do
          it 'returns a valid instance template_spec' do
            network_name = network_spec['name']
            spec = instance_spec.as_template_spec
            expect(spec['deployment']).to eq('fake-deployment')
            expect(spec['name']).to eq('fake-job')
            expect(spec['job']).to eq(job_spec)
            expect(spec['index']).to eq(index)
            expect(spec['networks']).to include(network_name)

            expect(spec['networks'][network_name]).to include(
                  'type' => 'dynamic',
                  'ip' => '127.0.0.1',
                  'netmask' => '127.0.0.1',
                  'gateway' => '127.0.0.1',
                  'dns_record_name' => '0.job.default.fake-deployment.bosh',
                  'cloud_properties' => network_spec['subnets'].first['cloud_properties'],
                  )

            expect(spec['persistent_disk']).to eq(0)
            expect(spec['configuration_hash']).to be_nil
            expect(spec['properties']).to eq(properties)
            expect(spec['dns_domain_name']).to eq('bosh')
            expect(spec['links']).to eq(expected_links)
            expect(spec['id']).to eq('uuid-1')
            expect(spec['az']).to eq('foo-az')
            expect(spec['bootstrap']).to eq(true)
            expect(spec['resource_pool']).to eq('fake-vm-type')
            expect(spec['address']).to eq('uuid-1.fake-job.default.fake-deployment.bosh')
            expect(spec['ip']).to eq(nil)
          end
        end
        context 'when vm has network ip assigned' do
          let(:instance_state) do
            {
                'networks' => {
                    'default' => {
                        'type' => 'dynamic',
                        'ip' => '192.0.2.19',
                        'netmask' => '255.255.255.0',
                        'gateway' => '192.0.2.1',
                    }
                }
            }
          end
          it 'returns a valid instance template_spec' do
            network_name = network_spec['name']
            spec = instance_spec.as_template_spec
            expect(spec['deployment']).to eq('fake-deployment')
            expect(spec['name']).to eq('fake-job')
            expect(spec['job']).to eq(job_spec)
            expect(spec['index']).to eq(index)
            expect(spec['networks']).to include(network_name)

            expect(spec['networks'][network_name]).to include(
                        'type' => 'dynamic',
                        'ip' => '192.0.2.19',
                        'netmask' => '255.255.255.0',
                        'gateway' => '192.0.2.1',
                        'dns_record_name' => '0.job.default.fake-deployment.bosh',
                        'cloud_properties' => network_spec['subnets'].first['cloud_properties'],
                    )

            expect(spec['persistent_disk']).to eq(0)
            expect(spec['configuration_hash']).to be_nil
            expect(spec['properties']).to eq(properties)
            expect(spec['dns_domain_name']).to eq('bosh')
            expect(spec['links']).to eq(expected_links)
            expect(spec['id']).to eq('uuid-1')
            expect(spec['az']).to eq('foo-az')
            expect(spec['bootstrap']).to eq(true)
            expect(spec['resource_pool']).to eq('fake-vm-type')
            expect(spec['address']).to eq('uuid-1.fake-job.default.fake-deployment.bosh')
            expect(spec['ip']).to eq('192.0.2.19')
          end
        end
      end
    end
    describe '#full_spec' do
      context 'when CompilationJobs' do
        let(:lifecycle) { nil }
        context 'lifecycle is not set' do
          it "contains 'nil' for 'lifecycle'" do
            expect(instance_spec.full_spec['lifecycle']).to be_nil
          end
        end
      end

      InstanceGroup::VALID_LIFECYCLE_PROFILES.each do |lifecycle_value|
        context "when 'lifecycle' is set to '#{lifecycle_value}'" do
          let(:lifecycle) { lifecycle_value }

          it "contains '#{lifecycle_value}' for 'lifecycle'" do
            expect(instance_spec.full_spec['lifecycle']).to eq(lifecycle_value)
          end
        end
      end
    end
  end
end
