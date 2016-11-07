require 'spec_helper'

module Bosh::Director
  describe DeploymentPlan::Assembler do
    subject(:assembler) { DeploymentPlan::Assembler.new(deployment_plan, stemcell_manager, dns_manager, cloud, logger) }
    let(:deployment_plan) { instance_double('Bosh::Director::DeploymentPlan::Planner',
      name: 'simple',
      using_global_networking?: false,
      skip_drain: BD::DeploymentPlan::AlwaysSkipDrain.new,
      recreate: false,
      model: BD::Models::Deployment.make,

    ) }
    let(:stemcell_manager) { nil }
    let(:dns_manager) { DnsManagerProvider.create }
    let(:event_log) { Config.event_log }

    let(:cloud) { instance_double('Bosh::Cloud') }

    describe '#bind_models' do
      let(:instance_model) { Models::Instance.make(job: 'old-name') }
      let(:instance_group) { instance_double(DeploymentPlan::InstanceGroup) }

      before do
        allow(deployment_plan).to receive(:instance_models).and_return([instance_model])
        allow(deployment_plan).to receive(:instance_groups).and_return([])
        allow(deployment_plan).to receive(:existing_instances).and_return([])
        allow(deployment_plan).to receive(:candidate_existing_instances).and_return([])
        allow(deployment_plan).to receive(:resource_pools).and_return(nil)
        allow(deployment_plan).to receive(:stemcells).and_return({})
        allow(deployment_plan).to receive(:jobs_starting_on_deploy).and_return([])
        allow(deployment_plan).to receive(:releases).and_return([])
        allow(deployment_plan).to receive(:uninterpolated_manifest_text).and_return({})
        allow(deployment_plan).to receive(:mark_instance_plans_for_deletion)
      end

      it 'should bind releases and their templates' do
        r1 = instance_double('Bosh::Director::DeploymentPlan::ReleaseVersion', name: 'r1')
        r2 = instance_double('Bosh::Director::DeploymentPlan::ReleaseVersion', name: 'r2')

        allow(deployment_plan).to receive(:releases).and_return([r1, r2])

        expect(r1).to receive(:bind_model)
        expect(r2).to receive(:bind_model)

        expect(r1).to receive(:bind_templates)
        expect(r2).to receive(:bind_templates)

        expect(assembler).to receive(:with_release_locks).with(['r1', 'r2']).and_yield
        assembler.bind_models
      end

      describe 'migrate_legacy_dns_records' do
        it 'migrates legacy dns records' do
          expect(dns_manager).to receive(:migrate_legacy_records).with(instance_model)
          assembler.bind_models
        end
      end

      it 'should bind stemcells' do
        sc1 = instance_double('Bosh::Director::DeploymentPlan::Stemcell')
        sc2 = instance_double('Bosh::Director::DeploymentPlan::Stemcell')

        expect(deployment_plan).to receive(:stemcells).and_return({ 'sc1' => sc1, 'sc2' => sc2})

        expect(sc1).to receive(:bind_model)
        expect(sc2).to receive(:bind_model)

        assembler.bind_models
      end

      it 'passes tags to instance plan factory' do
        expected_options = {'recreate' => false, 'tags' => {'key1' => 'value1'}}
        expect(DeploymentPlan::InstancePlanFactory).to receive(:new).with(anything, anything, anything, anything, anything, expected_options).and_call_original
        assembler.bind_models({tags: {'key1' => 'value1'}})
      end

      context 'when there are desired instance_groups' do
        def make_instance_group(name, template_name)
          instance_group = DeploymentPlan::InstanceGroup.new(logger)
          instance_group.name = name
          instance_group.deployment_name = 'simple'
          template_model = Models::Template.make(name: template_name)
          release_version = instance_double(DeploymentPlan::ReleaseVersion)
          allow(release_version).to receive(:get_template_model_by_name).and_return(template_model)
          job = DeploymentPlan::Job.new(release_version, template_name)
          job.bind_models
          instance_group.jobs = [job]
          allow(instance_group).to receive(:validate_package_names_do_not_collide!)
          instance_group
        end

        let(:instance_group_1) { make_instance_group('ig-1', 'fake-instance-group-1') }
        let(:instance_group_2) { make_instance_group('ig-2', 'fake-instance-group-2') }

        let(:instance_group_network) { double(DeploymentPlan::JobNetwork) }

        before do
          allow(instance_group_network).to receive(:name).and_return('my-network-name')
          allow(instance_group_network).to receive(:vip?).and_return(false)
          allow(instance_group_network).to receive(:static_ips)
          allow(instance_group_1).to receive(:networks).and_return([instance_group_network])
          allow(instance_group_2).to receive(:networks).and_return([instance_group_network])

          allow(deployment_plan).to receive(:instance_groups).and_return([instance_group_1, instance_group_2])
          allow(deployment_plan).to receive(:name).and_return([instance_group_1, instance_group_2])
        end

        it 'validates the instance_groups' do
          expect(instance_group_1).to receive(:validate_package_names_do_not_collide!).once
          expect(instance_group_2).to receive(:validate_package_names_do_not_collide!).once

          assembler.bind_models
        end

        context 'links binding' do
          let(:links_resolver) { double(DeploymentPlan::LinksResolver)}

          before do
            allow(DeploymentPlan::LinksResolver).to receive(:new).with(deployment_plan, logger).and_return(links_resolver)
          end

          it 'should bind links by default' do
            expect(links_resolver).to receive(:resolve).with(instance_group_1)
            expect(links_resolver).to receive(:resolve).with(instance_group_2)

            assembler.bind_models
          end

          it 'should skip links binding when should_bind_links flag is passed as false' do
            expect(links_resolver).to_not receive(:resolve)

            assembler.bind_models({:should_bind_links => false})
          end
        end

        context 'properties binding' do
          it 'should bind properties by default' do
            expect(instance_group_1).to receive(:bind_properties)
            expect(instance_group_2).to receive(:bind_properties)

            assembler.bind_models
          end

          it 'should skip links binding when should_bind_properties flag is passed as false' do
            expect(instance_group_1).to_not receive(:bind_properties)
            expect(instance_group_2).to_not receive(:bind_properties)

            assembler.bind_models({:should_bind_properties => false})
          end
        end

        context 'when the instance_group validation fails' do
          it 'propagates the exception' do
            expect(instance_group_1).to receive(:validate_package_names_do_not_collide!).once
            expect(instance_group_2).to receive(:validate_package_names_do_not_collide!).once.and_raise('Unable to deploy manifest')

            expect { assembler.bind_models }.to raise_error('Unable to deploy manifest')
          end
        end
      end

      it 'configures dns' do
        expect(dns_manager).to receive(:configure_nameserver)
        assembler.bind_models
      end
    end
  end
end
