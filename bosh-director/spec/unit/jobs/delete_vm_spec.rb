require 'spec_helper'

module Bosh::Director
  describe Jobs::DeleteVm do
    subject(:job) { described_class.new(vm_cid) }
    before do
      allow(Bosh::Director::Config).to receive(:record_events).and_return(true)
      allow(job).to receive(:task_id).and_return(task.id)
      allow(Bosh::Director::Config).to receive(:current_job).and_return(delete_vm_job)
    end

    let(:vm_cid) { 'vm_cid' }
    let(:task) { Bosh::Director::Models::Task.make(:id => 42, :username => 'user') }
    let(:event_manager) { Bosh::Director::Api::EventManager.new(true) }
    let(:delete_vm_job) { instance_double(Bosh::Director::Jobs::DeleteVm, username: 'user', task_id: task.id, event_manager: event_manager) }
    let(:cloud) { Config.cloud }

    shared_examples_for 'vm delete' do
      it 'should delete vm' do
        expect(cloud).to receive(:delete_vm).with(vm_cid)
        expect(job.perform).to eq 'vm vm_cid deleted'
      end

      it 'should not raise error' do
        expect(cloud).to receive(:delete_vm).with(vm_cid).and_raise(Bosh::Clouds::VMNotFound)
        expect(job.perform).to eq 'vm vm_cid deleted'
      end

      it 'should raise error' do
        expect(cloud).to receive(:delete_vm).with(vm_cid).and_raise(Exception)
        expect { job.perform }.to raise_error(Exception)
      end
    end

    describe 'perform' do
      describe 'DJ job class expectations' do
        let(:job_type) { :delete_vm }
        let(:queue) { :normal }
        it_behaves_like 'a DJ job'
      end

      context 'when instance has reference to vm' do
        before do
          deployment = Bosh::Director::Models::Deployment.make(name: 'test_deployment')
          BD::Models::Instance.make(deployment: deployment, job: 'foo-job', uuid: 'instance_id', index: 0, vm_cid: vm_cid, ignore: true)
        end

        it_behaves_like 'vm delete'

        it 'should store event' do
          expect(cloud).to receive(:delete_vm).with(vm_cid)
          job.perform
          event_1 = Bosh::Director::Models::Event.first
          expect(event_1.user).to eq(task.username)
          expect(event_1.action).to eq('delete')
          expect(event_1.object_type).to eq('vm')
          expect(event_1.object_name).to eq('vm_cid')
          expect(event_1.instance).to eq('foo-job/instance_id')
          expect(event_1.deployment).to eq('test_deployment')
          expect(event_1.task).to eq("#{task.id}")

          event_2 = Bosh::Director::Models::Event.all.last
          expect(event_2.parent_id).to eq(event_1.id)
          expect(event_2.user).to eq(task.username)
          expect(event_2.action).to eq('delete')
          expect(event_2.object_type).to eq('vm')
          expect(event_2.object_name).to eq('vm_cid')
          expect(event_2.instance).to eq('foo-job/instance_id')
          expect(event_2.deployment).to eq('test_deployment')
          expect(event_2.task).to eq("#{task.id}")
        end

        it 'should update instance' do
          expect(cloud).to receive(:delete_vm).with(vm_cid)
          job.perform
          expect(BD::Models::Instance.all.first.vm_cid).to be_nil
        end
      end

      context 'when instance does not have reference to vm' do
        it_behaves_like 'vm delete'

        it 'should store event' do
          expect(cloud).to receive(:delete_vm).with(vm_cid)
          job.perform
          event_1 = Bosh::Director::Models::Event.first
          expect(event_1.user).to eq(task.username)
          expect(event_1.action).to eq('delete')
          expect(event_1.object_type).to eq('vm')
          expect(event_1.object_name).to eq('vm_cid')
          expect(event_1.instance).to be_nil
          expect(event_1.deployment).to be_nil
          expect(event_1.task).to eq("#{task.id}")

          event_2 = Bosh::Director::Models::Event.all.last
          expect(event_2.parent_id).to eq(event_1.id)
          expect(event_2.user).to eq(task.username)
          expect(event_2.action).to eq('delete')
          expect(event_2.object_type).to eq('vm')
          expect(event_2.object_name).to eq('vm_cid')
          expect(event_2.instance).to be_nil
          expect(event_2.deployment).to be_nil
          expect(event_2.task).to eq("#{task.id}")
        end
      end
    end
  end
end
