require 'spec_helper'

describe 'using director with config server', type: :integration do

  let (:manifest_hash) { Bosh::Spec::Deployments.simple_manifest }
  let (:cloud_config)  { Bosh::Spec::Deployments.simple_cloud_config }
  let(:config_server_helper) { Bosh::Spec::ConfigServerHelper.new(current_sandbox.port_provider.get_port(:config_server_port)) }

  context 'when config server cretificates are not trusted' do
    with_reset_sandbox_before_each(config_server_enabled: true, with_config_server_trusted_certs: false)

    before do
      target_and_login
      upload_stemcell
    end

    it 'throws certificate validator error' do
      manifest_hash['jobs'].first['properties'] = {'test_property' => '((test_property))'}
      output, exit_code = deploy_from_scratch(manifest_hash: manifest_hash, cloud_config_hash: cloud_config, failure_expected: true, return_exit_code: true)

      expect(exit_code).to_not eq(0)
      expect(output).to include('Error 100: SSL certificate verification failed')
    end

  end

  context 'when config server certificates are trusted' do
    with_reset_sandbox_before_each(config_server_enabled: true)

    before do
      target_and_login
      upload_stemcell
    end

    context 'when deployment manifest has placeholders' do
      it 'raises an error when config server does not have values for placeholders' do
        manifest_hash['jobs'].first['properties'] = {'test_property' => '((test_property))'}
        output, exit_code = deploy_from_scratch(manifest_hash: manifest_hash, cloud_config_hash: cloud_config, failure_expected: true, return_exit_code: true)

        expect(exit_code).to_not eq(0)
        expect(output).to include('Failed to find keys in the config server: test_property')
      end

      it 'replaces placeholders in the manifest when config server has value for placeholders' do
        config_server_helper.put_value('test_property', 'cats are happy')

        manifest_hash['jobs'].first['properties'] = {'test_property' => '((test_property))'}
        deploy_from_scratch(manifest_hash: manifest_hash, cloud_config_hash: cloud_config)
        vm = director.vm('foobar', '0')

        template = vm.read_job_template('foobar', 'bin/foobar_ctl')
        expect(template).to include('test_property=cats are happy')
      end
    end

    context 'when runtime manifest has placeholders' do
      it 'replaces placeholders in the addons' do
        config_server_helper.put_value('release_name', 'dummy2')

        Dir.mktmpdir do |tmpdir|
          runtime_config_filename = File.join(tmpdir, 'runtime_config.yml')
          File.write(runtime_config_filename, Psych.dump(Bosh::Spec::Deployments.runtime_config_with_addon_placeholders))
          expect(bosh_runner.run("update runtime-config #{runtime_config_filename}")).to include("Successfully updated runtime config")
        end
      end
    end
  end
end
