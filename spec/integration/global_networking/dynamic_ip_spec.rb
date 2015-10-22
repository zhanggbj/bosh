require 'spec_helper'

describe 'DynamicIPChange', type: :integration, dns: true do
  with_reset_sandbox_before_each

  it 'keeps IP when reservation is changed to dynamic' do
    cloud_config_hash = {
      'availability_zones' => [
        {
          'name' => 'z1',
          'cloud_properties' => {
            'availability_zone' => 'us-east-1b'
          }
        },
        {
          'name' => 'z2',
          'cloud_properties' => {
            'availability_zone' => 'us-east-1c'
          }
        },
        {
          'name' => 'z3',
          'cloud_properties' => {
            'availability_zone' => 'us-east-1c'
          }
        }
      ],
      'resource_pools' => [
        {
          'network' => 'private',
          'stemcell' => {
            'version' => 1,
            'name' => 'ubuntu-stemcell'
          },
          'cloud_properties' => {
            'instance_type' => 't2.micro',
            'ephemeral_disk' => {
              'type' => 'gp2',
              'size' => 3000
            }
          },
          'name' => 'lol'
        }
      ],
      'compilation' => {
        'workers' => 1,
        'network' => 'private',
        'cloud_properties' => {},
      },
      'networks' => [
        {
          'subnets' => [
            {
              'range' => '10.10.0.0/24',
              'reserved' => [
                '10.10.0.2 - 10.10.0.61',
                '10.10.0.120 - 10.10.0.254'
              ],
              'dns' => [
                '10.10.0.2'
              ],
              'availability_zone' => 'z1',
              'static' => [
                '10.10.0.62',
                '10.10.0.64'
              ],
              'cloud_properties' => {
                'subnet' => 'subnet-f2744a86'
              },
              'gateway' => '10.10.0.1'
            },
            {
              'range' => '10.10.64.0/24',
              'reserved' => [
                '10.10.64.2 - 10.10.64.120',
                '10.10.64.130 - 10.10.64.254'
              ],
              'dns' => [
                '10.10.0.2'
              ],
              'availability_zone' => 'z3',
              'static' => [
                '10.10.64.121',
                '10.10.64.122',
                '10.10.64.123'
              ],
              'cloud_properties' => {
                'subnet' => 'subnet-eb8bd3ad'
              },
              'gateway' => '10.10.64.1'
            }
          ],
          'type' => 'manual',
          'name' => 'private'
        },
        {
          'subnets' => [
            {
              'availability_zones' => [
                'z3',
                'z2'
              ],
              'cloud_properties' => {
                'subnet' => 'subnet-eb8bd3ad'
              }
            },
            {
              'cloud_properties' => {
                'subnet' => 'subnet-f2744a86'
              },
              'availability_zone' => 'z1'
            }
          ],
          'type' => 'dynamic',
          'name' => 'private-dyn'
        }
      ]
    }

    manifest_hash = Bosh::Spec::Deployments.simple_manifest
    manifest_hash['jobs'] = [
      {
        'templates' => [
          {
            'name' => 'foobar'
          }
        ],
        'resource_pool' => 'lol',
        'availability_zones' => [
          'z1'
        ],
        'name' => 'db',
        'migrated_from' => [
          {
            'name' => 'db_z1',
            'availability_zone' => 'z1'
          }
        ],
        'instances' => 1,
        'networks' => [
          {
            'static_ips' => [
              '10.10.0.62'
            ],
            'name' => 'private'
          }
        ]
      }
    ]
    deploy_from_scratch(manifest_hash: manifest_hash, cloud_config_hash: cloud_config_hash)

    output = bosh_runner.run('vms --dns')
    expect(output).to include('10.10.0.62')
    expect(output).to include('0.db.private.simple.bosh')

    manifest_hash['jobs'] = [
      {
        'templates' => [
          {
            'name' => 'foobar'
          }
        ],
        'resource_pool' => 'lol',
        'availability_zones' => [
          'z1'
        ],
        'name' => 'db',
        'migrated_from' => [
          {
            'name' => 'db_z1',
            'availability_zone' => 'z1'
          }
        ],
        'instances' => 1,
        'networks' => [
          {
            'name' => 'private-dyn'
          }
        ]
      }
    ]
    deploy_simple_manifest(manifest_hash: manifest_hash)

    output = bosh_runner.run('vms --dns')
    expect(output).to include('0.db.private-dyn.simple.bosh')
  end
end
