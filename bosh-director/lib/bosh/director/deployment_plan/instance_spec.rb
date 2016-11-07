module Bosh::Director
  module DeploymentPlan
    class InstanceSpec
      def self.create_empty
        EmptyInstanceSpec.new
      end

      def self.create_from_database(spec, instance)
        new(spec, instance)
      end

      def self.create_from_instance_plan(instance_plan)
        instance = instance_plan.instance
        deployment_name = instance.deployment_model.name
        instance_group = instance_plan.desired_instance.instance_group
        instance_plan = instance_plan
        dns_manager = DnsManagerProvider.create

        spec = {
          'deployment' => deployment_name,
          'job' => instance_group.spec,
          'index' => instance.index,
          'bootstrap' => instance.bootstrap?,
          'lifecycle' => instance_group.lifecycle,
          'name' => instance.job_name,
          'id' => instance.uuid,
          'az' => instance.availability_zone_name,
          'networks' => instance_plan.network_settings_hash,
          'vm_type' => instance_group.vm_type.spec,
          'stemcell' => instance_group.stemcell.spec,
          'env' => instance_group.env.spec,
          'packages' => instance_group.package_spec,
          'properties' => instance_group.properties,
          'properties_need_filtering' => true,
          'dns_domain_name' => dns_manager.dns_domain_name,
          'links' => instance_group.resolved_links,
          'address' => instance_plan.network_settings.network_address,
          'update' => instance_group.update_spec
        }

        disk_spec = instance_group.persistent_disk_collection.generate_spec

        spec.merge!(disk_spec)

        new(spec, instance)
      end

      def initialize(full_spec, instance)
        @full_spec = full_spec
        @instance = instance

        @config_server_client_factory = ConfigServer::ClientFactory.create(Config.logger)
      end

      def as_template_spec
        TemplateSpec.new(full_spec, @config_server_client_factory).spec
      end

      def as_apply_spec
        ApplySpec.new(full_spec).spec
      end

      def full_spec
        # re-generate spec with rendered templates info
        # since job renderer sets it directly on instance
        spec = @full_spec

        if @instance.template_hashes
          spec['template_hashes'] = @instance.template_hashes
        end

        if @instance.rendered_templates_archive
          spec['rendered_templates_archive'] = @instance.rendered_templates_archive.spec
        end

        if @instance.configuration_hash
          spec['configuration_hash'] = @instance.configuration_hash
        end

        spec
      end
    end

    private

    class EmptyInstanceSpec < InstanceSpec
      def initialize
      end

      def full_spec
        {}
      end
    end

    class TemplateSpec
      def initialize(full_spec, config_server_client_factory)
        @full_spec = full_spec
        @dns_manager = DnsManagerProvider.create
        @config_server_client_factory = config_server_client_factory
      end

      def spec
        keys = [
          'deployment',
          'job',
          'index',
          'bootstrap',
          'name',
          'id',
          'az',
          'networks',
          'properties_need_filtering',
          'dns_domain_name',
          'persistent_disk',
          'address',
          'ip'
        ]
        template_hash = @full_spec.select {|k,v| keys.include?(k) }

        template_hash['properties'] = resolve_uninterpolated_values(@full_spec['deployment'], @full_spec['properties'])
        template_hash['links'] = {}

        @full_spec.fetch('links', {}).each do |link_name, link_info|
          template_hash['links'][link_name] = resolve_uninterpolated_values(link_info.deployment_name, link_info.spec)
        end

        networks_hash = template_hash['networks']

        ip = nil
        modified_networks_hash = networks_hash.each_pair do |network_name, network_settings|
          if @full_spec['job'] != nil
            settings_with_dns = network_settings.merge({'dns_record_name' => @dns_manager.dns_record_name(@full_spec['index'], @full_spec['job']['name'], network_name, @full_spec['deployment'])})
            networks_hash[network_name] = settings_with_dns
          end

          defaults = network_settings['default'] || []

          if defaults.include?('addressable') || (!ip && defaults.include?('gateway'))
            ip = network_settings['ip']
          end

          if network_settings['type'] == 'dynamic'
            # Templates may get rendered before we know dynamic IPs from the Agent.
            # Use valid IPs so that templates don't have to write conditionals around nil values.
            networks_hash[network_name]['ip'] ||= '127.0.0.1'
            networks_hash[network_name]['netmask'] ||= '127.0.0.1'
            networks_hash[network_name]['gateway'] ||= '127.0.0.1'
          end
        end

        template_hash.merge({
        'ip' => ip,
        'resource_pool' => @full_spec['vm_type']['name'],
        'networks' => modified_networks_hash
        })
      end

      private

      def resolve_uninterpolated_values(director_name, to_be_resolved_hash)
        config_server_client = @config_server_client_factory.create_client(director_name)
        config_server_client.interpolate(to_be_resolved_hash)
      end
    end

    class ApplySpec
      def initialize(full_spec)
        @full_spec = full_spec
      end

      def spec
        keys = [
          'deployment',
          'job',
          'index',
          'name',
          'id',
          'az',
          'networks',
          'packages',
          'dns_domain_name',
          'configuration_hash',
          'persistent_disk',
          'template_hashes',
          'rendered_templates_archive',
        ]
        @full_spec.select {|k,_| keys.include?(k) }
      end
    end
  end
end
