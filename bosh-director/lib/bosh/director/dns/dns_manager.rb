module Bosh::Director
  class DnsManagerProvider
    def self.create
      dns_config = Config.dns || {}

      logger = Config.logger
      dns_domain_name = Canonicalizer.canonicalize(dns_config.fetch('domain_name', 'bosh'), :allow_dots => true)
      local_dns_repo = LocalDnsRepo.new(logger)

      dns_publisher = BlobstoreDnsPublisher.new(App.instance.blobstores.blobstore, dns_domain_name) if Config.local_dns
      dns_provider = PowerDns.new(dns_domain_name, logger) if !!Config.dns_db

      DnsManager.new(dns_domain_name, dns_config, dns_provider, dns_publisher, local_dns_repo, logger)
    end
  end

  public

  class DnsManager
    attr_reader :dns_domain_name

    def initialize(dns_domain_name, dns_config, dns_provider, dns_publisher, local_dns_repo, logger)
      @dns_domain_name = dns_domain_name
      @dns_provider = dns_provider
      @dns_publisher = dns_publisher
      @default_server = dns_config['server']
      @flush_command = dns_config['flush_command']
      @ip_address = dns_config['address']
      @local_dns_repo = local_dns_repo
      @logger = logger
    end

    def dns_enabled?
      !@dns_provider.nil?
    end

    def publisher_enabled?
      !@dns_publisher.nil?
    end

    def configure_nameserver
      @dns_provider.create_or_update_nameserver(@ip_address) if dns_enabled?
    end

    def find_dns_record(dns_record_name, ip_address)
      @dns_provider.find_dns_record(dns_record_name, ip_address)
    end

    def update_dns_record_for_instance(instance_model, dns_names_to_ip)
      current_dns_records = @local_dns_repo.find(instance_model)
      new_dns_records = []
      dns_names_to_ip.each do |record_name, ip_address|
        new_dns_records << record_name
        if dns_enabled?
          @logger.info("Updating DNS for: #{record_name} to #{ip_address}")
          @dns_provider.create_or_update_dns_records(record_name, ip_address)
        end
      end
      dns_records = (current_dns_records + new_dns_records).uniq
      @local_dns_repo.create_or_update(instance_model, dns_records)
    end

    def migrate_legacy_records(instance_model)
      return if @local_dns_repo.find(instance_model).any?
      return unless dns_enabled?

      index_pattern_for_all_networks = dns_record_name(
        instance_model.index,
        instance_model.job,
        '%',
        instance_model.deployment.name
      )
      uuid_pattern_for_all_networks = dns_record_name(
        instance_model.uuid,
        instance_model.job,
        '%',
        instance_model.deployment.name
      )

      legacy_record_names = [index_pattern_for_all_networks, uuid_pattern_for_all_networks]
        .map { |pattern| @dns_provider.find_dns_records_by_pattern(pattern) }
        .flatten
        .map(&:name)

      @local_dns_repo.create_or_update(instance_model, legacy_record_names)
    end

    def delete_dns_for_instance(instance_model)
      return if !dns_enabled?

      current_dns_records = @local_dns_repo.find(instance_model)
      if current_dns_records.empty?
        # for backwards compatibility when old instances
        # did not have records in local repo
        # we cannot migrate them because powerdns can be different database
        # those instance only had index-based dns records (before global-net)
        index_record_pattern = dns_record_name(instance_model.index, instance_model.job, '%', instance_model.deployment.name)
        @dns_provider.delete(index_record_pattern)
        return
      end

      current_dns_records.each do |record_name|
        @logger.info("Removing DNS for: #{record_name}")
        @dns_provider.delete(record_name)
      end

      @local_dns_repo.delete(instance_model)
    end

    # build a list of dns servers to use
    def dns_servers(network, dns_spec, add_default_dns = true)
      servers = nil

      if dns_spec
        servers = []
        dns_spec.each do |dns|
          dns = NetAddr::CIDR.create(dns)
          unless dns.size == 1
            raise NetworkInvalidDns,
              "Invalid DNS for network '#{network}': must be a single IP"
          end

          servers << dns.ip
        end
      end

      return servers unless add_default_dns
      add_default_dns_server(servers)
    end

    # Purge cached DNS records
    def flush_dns_cache
      if @flush_command && !@flush_command.empty?
        stdout, stderr, status = Open3.capture3(@flush_command)
        if status == 0
          @logger.debug("Flushed #{stdout.chomp} records from DNS cache")
        else
          @logger.warn("Failed to flush DNS cache: #{stderr.chomp}")
        end
      end
      publish_dns_records
    end

    def publish_dns_records
      if publisher_enabled?
        dns_records = @dns_publisher.export_dns_records
        @dns_publisher.publish(dns_records)
      end
    end

    def cleanup_dns_records
      if publisher_enabled?
        @dns_publisher.cleanup_blobs
      end
    end

    def find_dns_record_names_by_instance(instance_model)
      instance_model.nil? ? [] : instance_model.dns_record_names.to_a.compact
    end

    def dns_record_name(hostname, job_name, network_name, deployment_name)
      network_name = Canonicalizer.canonicalize(network_name) unless network_name == '%'

      [ hostname,
        Canonicalizer.canonicalize(job_name),
        network_name,
        Canonicalizer.canonicalize(deployment_name),
        @dns_domain_name
      ].join('.')
    end

    private

    # add default dns server to an array of dns servers
    def add_default_dns_server(servers)
      unless @default_server.to_s.empty? || @default_server == '127.0.0.1'
        (servers ||= []) << @default_server
        servers.uniq!
      end

      servers
    end
  end
end
