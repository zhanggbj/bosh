module Bosh::Director
  class VmDeleter
    def initialize(cloud, logger, options={})
      @cloud = cloud
      @logger = logger

      force = options.fetch(:force, false)
      @error_ignorer = ErrorIgnorer.new(force, @logger)
    end

    def delete_for_instance_plan(instance_plan)
      instance_model = instance_plan.existing_instance

      if instance_model.vm_cid
        delete_vm(instance_model.vm_cid)
      end

      instance_model.update(vm_cid: nil, agent_id: nil)
    end

    def delete_vm(vm_cid)
      @error_ignorer.with_force_check do
        @cloud.delete_vm(vm_cid)
      end
    end
  end
end
