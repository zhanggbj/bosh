require 'spec_helper'
require 'bosh/cpi/compatibility_helpers/delete_vm'
require 'tempfile'
require 'yaml'

describe VSphereCloud::Cloud, external_cpi: false do
  before(:all) do
    @host          = ENV['BOSH_VSPHERE_CPI_HOST']     || raise('Missing BOSH_VSPHERE_CPI_HOST')
    @user          = ENV['BOSH_VSPHERE_CPI_USER']     || raise('Missing BOSH_VSPHERE_CPI_USER')
    @password      = ENV['BOSH_VSPHERE_CPI_PASSWORD'] || raise('Missing BOSH_VSPHERE_CPI_PASSWORD')
    @vlan          = ENV['BOSH_VSPHERE_VLAN']         || raise('Missing BOSH_VSPHERE_VLAN')
    @stemcell_path = ENV['BOSH_VSPHERE_STEMCELL']     || raise('Missing BOSH_VSPHERE_STEMCELL')

    @datacenter_name              = ENV.fetch('BOSH_VSPHERE_CPI_DATACENTER', 'BOSH_DC')
    @vm_folder                    = ENV.fetch('BOSH_VSPHERE_CPI_VM_FOLDER', 'ACCEPTANCE_BOSH_VMs')
    @template_folder              = ENV.fetch('BOSH_VSPHERE_CPI_TEMPLATE_FOLDER', 'ACCEPTANCE_BOSH_Templates')
    @disk_path                    = ENV.fetch('BOSH_VSPHERE_CPI_DISK_PATH', 'ACCEPTANCE_BOSH_Disks')
    @datastore_pattern            = ENV.fetch('BOSH_VSPHERE_CPI_DATASTORE_PATTERN', 'jalapeno')
    @persistent_datastore_pattern = ENV.fetch('BOSH_VSPHERE_CPI_PERSISTENT_DATASTORE_PATTERN', 'jalapeno')
    @cluster                      = ENV.fetch('BOSH_VSPHERE_CPI_CLUSTER', 'BOSH_CL')
    @resource_pool_name           = ENV.fetch('BOSH_VSPHERE_CPI_RESOURCE_POOL', 'ACCEPTANCE_RP')
    @second_cluster               = ENV.fetch('BOSH_VSPHERE_CPI_SECOND_CLUSTER', 'BOSH_CL2')
    @second_resource_pool_name    = ENV.fetch('BOSH_VSPHERE_CPI_SECOND_RESOURCE_POOL', 'ACCEPTANCE_RP')
  end

  def build_cpi
    described_class.new(
      'soap_log' => '/tmp/cpi.log',
      'agent' => {
        'ntp' => ['10.80.0.44'],
      },
      'vcenters' => [{
        'host' => @host,
        'user' => @user,
        'password' => @password,
        'datacenters' => [{
          'name' => @datacenter_name,
          'vm_folder' => @vm_folder,
          'template_folder' => @template_folder,
          'disk_path' => @disk_path,
          'datastore_pattern' => @datastore_pattern,
          'datastore_cluster' => 'BOSH_CL',
          'persistent_datastore_pattern' => @persistent_datastore_pattern,
          'persistent_datastore_cluster' => 'BOSH_CL',
          'allow_mixed_datastores' => true,
          'clusters' => [{
              @cluster => { 'resource_pool' => @resource_pool_name },
            },
            {
              @second_cluster  => { 'resource_pool' => @second_resource_pool_name }
            }],
        }]
      }]
    )
  end

  before(:all) { @cpi = build_cpi }

  subject(:cpi) { @cpi }

  before(:all) do
    Dir.mktmpdir do |temp_dir|
      output = `tar -C #{temp_dir} -xzf #{@stemcell_path} 2>&1`
      raise "Corrupt image, tar exit status: #{$?.exitstatus} output: #{output}" if $?.exitstatus != 0
      @stemcell_id = @cpi.create_stemcell("#{temp_dir}/image", nil)
    end
  end

  after(:all) { @cpi.delete_stemcell(@stemcell_id) if @stemcell_id }

  let(:network_spec) do
    {
      'static' => {
        'ip' => '169.254.1.1', #172.16.69.102",
        'netmask' => '255.255.254.0',
        'cloud_properties' => { 'name' => @vlan},
        'default' => ['dns', 'gateway'],
        'dns' => ['169.254.1.2'],  #["172.16.69.100"],
        'gateway' => '169.254.1.3' #"172.16.68.1"
      }
    }
  end

  let(:resource_pool) {
    {
      'ram' => 1024,
      'disk' => 2048,
      'cpu' => 1,
    }
  }

  it 'creates vm' do
    @vm_id = @cpi.create_vm(
      'agent-007',
      @stemcell_id,
      resource_pool,
      network_spec,
      [],
      {'key' => 'value'}
    )
  end
end
