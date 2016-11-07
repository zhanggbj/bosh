require_relative '../spec_helper'

describe 'cli: deploy uploading', type: :integration do
  include Bosh::Spec::CreateReleaseOutputParsers
  with_reset_sandbox_before_each
  let(:stemcell_filename) { spec_asset('valid_stemcell.tgz') }

  let(:cloud_config_manifest) { yaml_file('cloud_manifest', Bosh::Spec::Deployments.simple_cloud_config) }

  before do
    target_and_login
    bosh_runner.run("update-cloud-config #{cloud_config_manifest.path}")
    bosh_runner.run("upload-stemcell #{stemcell_filename}")
  end

  context 'with a remote release' do
    let(:file_server) { Bosh::Spec::LocalFileServer.new(spec_asset(''), file_server_port, logger) }
    let(:file_server_port) { current_sandbox.port_provider.get_port(:releases_repo) }

    before { file_server.start }
    after { file_server.stop }

    let(:release_url) { file_server.http_url('compiled_releases/test_release/releases/test_release/test_release-1.tgz') }
    let(:release_sha) { '14ab572f7d00333d8e528ab197a513d44c709257' }

    it 'uploads the release from the remote url in the manifest' do
      deployment_manifest = yaml_file('deployment_manifest', Bosh::Spec::Deployments.remote_release_manifest(release_url, release_sha, 1))

      output = bosh_runner.run("deploy #{deployment_manifest.path}", deployment_name: 'minimal')
      expect(output).to match /Using deployment 'minimal'/
      expect(output).to match /Release has been created: test_release\/1/
      expect(output).to match /Succeeded/

      expect(bosh_runner.run('cloud-check --report', deployment_name: 'minimal')).to match(/0 problems/)
    end

    it 'does not upload the same release twice' do
      deployment_manifest = yaml_file('deployment_manifest', Bosh::Spec::Deployments.remote_release_manifest(release_url, release_sha, 1))

      output = bosh_runner.run("deploy #{deployment_manifest.path}", deployment_name: 'minimal')
      expect(output).to match /Using deployment 'minimal'/
      expect(output).to match /Release has been created: test_release\/1/
      expect(output).to match /Succeeded/
      expect(bosh_runner.run('cloud-check --report', deployment_name: 'minimal')).to match(/0 problems/)

      output = bosh_runner.run("deploy #{deployment_manifest.path}", deployment_name: 'minimal')
      expect(output).to match /Release 'test_release\/1' already exists/
      expect(output).to match /Succeeded/

      expect(bosh_runner.run('cloud-check --report', deployment_name: 'minimal')).to match(/0 problems/)
    end

    it 'fails when the sha1 does not match' do
      pending('cli2: #130881395: deploy of manifest with invalid release sha1 should fail')

      deployment_manifest = yaml_file('deployment_manifest', Bosh::Spec::Deployments.remote_release_manifest(release_url, 'abcd1234', 1))

      output = bosh_runner.run("deploy #{deployment_manifest.path}", deployment_name: 'minimal', failure_expected: true)
      expect(output).to match /Release SHA1 '#{release_sha}' does not match the expected SHA1 'abcd1234'/
      expect(output).not_to match /Succeeded/
    end

    it 'fails to deploy when the url is provided, but sha is not' do
      pending('cli2: #130881395: deploy of manifest with invalid release sha1 should fail')
      deployment_manifest = yaml_file('deployment_manifest', Bosh::Spec::Deployments.remote_release_manifest(release_url, '', 1))

      output = bosh_runner.run("deploy #{deployment_manifest.path}", deployment_name: 'minimal', failure_expected: true)
      expect(output).to match /Expected SHA1 when specifying remote URL for release 'test_release'/
      expect(output).not_to match /Succeeded/
    end
  end

  context 'with a local release tarball' do
    let(:release_path) { spec_asset('compiled_releases/test_release/releases/test_release/test_release-1.tgz') }

    it 'uploads the release from the local file path in the manifest' do
      deployment_manifest = yaml_file('deployment_manifest', Bosh::Spec::Deployments.local_release_manifest('file://' + release_path, 1))

      output = bosh_runner.run("deploy #{deployment_manifest.path}", deployment_name: 'minimal')
      expect(output).to match /Using deployment 'minimal'/
      expect(output).to match /Release has been created: test_release\/1/
      expect(output).to match /Succeeded/

      expect(bosh_runner.run('cloud-check --report', deployment_name: 'minimal')).to match(/0 problems/)
    end

    context 'when name and version are specified' do
      let(:release2_path) { spec_asset('compiled_releases/test_release/releases/test_release/test_release-2-pkg2-updated.tgz') }

      it 'does not upload the same release twice' do
        pending('cli2: #130928119 cli2 should not upload release if already on director')
        deployment_manifest = yaml_file('deployment_manifest', Bosh::Spec::Deployments.local_release_manifest('file://' + release_path, 1))

        output = bosh_runner.run("deploy #{deployment_manifest.path}", deployment_name: 'minimal')
        expect(output).to match /Using deployment 'minimal'/
        expect(output).to match /Release has been created: test_release\/1/
        expect(output).to match /Succeeded/
        expect(bosh_runner.run('cloud-check --report', deployment_name: 'minimal')).to match(/0 problems/)

        output = bosh_runner.run("deploy #{deployment_manifest.path}", deployment_name: 'minimal')
        expect(output).to match /Release 'test_release\/1' already exists/
        expect(output).to match /Succeeded/
        expect(bosh_runner.run('cloud-check --report', deployment_name: 'minimal')).to match(/0 problems/)
      end

      it 'ignores the tarball if the director has the same name and version' do
        pending('cli2: #130928119 cli2 should not upload release if already on director')
        deployment_manifest = yaml_file('deployment_manifest', Bosh::Spec::Deployments.local_release_manifest('file://' + release2_path, 1))

        bosh_runner.run("upload-release #{release_path}")

        output = bosh_runner.run("deploy #{deployment_manifest.path}", deployment_name: 'minimal')
        expect(output).to match /Release 'test_release\/1' already exists/
        expect(bosh_runner.run('cloud-check --report', deployment_name: 'minimal')).to match(/0 problems/)
      end
    end

    it 'fails to deploy when the url is invalid' do
      deployment_manifest = yaml_file('deployment_manifest', Bosh::Spec::Deployments.local_release_manifest('goobers', 1))

      output = bosh_runner.run("deploy #{deployment_manifest.path}", deployment_name: 'minimal', failure_expected: true)
      expect(output).to match /stat goobers: no such file or directory/
      expect(output).not_to match /Succeeded/
    end

    it 'fails to deploy when the path is not a release' do
      deployment_manifest = yaml_file('deployment_manifest', Bosh::Spec::Deployments.local_release_manifest('file:///goobers', 1))

      output = bosh_runner.run("deploy #{deployment_manifest.path}", deployment_name: 'minimal', failure_expected: true)
      expect(output).to match /stat \/goobers: no such file or directory/
      expect(output).not_to match /Succeeded/
    end
  end

  context 'with a local release directory' do
    let(:release_path) { spec_asset('compiled_releases/test_release') }
    let(:release_tar) { spec_asset('compiled_releases/test_release/releases/test_release/test_release-1.tgz') }

    before {
      FileUtils.rm_rf("#{release_path}/.dev_builds")
    }

    it 'creates, uploads and deploys release from local folder' do
      deployment_manifest = yaml_file('deployment_manifest', Bosh::Spec::Deployments.local_release_manifest('file://' + release_path, 'create'))

      output = bosh_runner.run("deploy #{deployment_manifest.path}", deployment_name: 'minimal')
      expect(output).to match /Using deployment 'minimal'/
      expect(output).to match /Added dev release 'test_release/
      expect(output).to match /Succeeded/
      expect(bosh_runner.run('cloud-check --report', deployment_name: 'minimal')).to match(/0 problems/)
    end

    it 'requires that the path is to a directory' do
      deployment_manifest = yaml_file('deployment_manifest', Bosh::Spec::Deployments.local_release_manifest('file://' + release_tar, 'create'))

      output = bosh_runner.run("deploy #{deployment_manifest.path}", deployment_name: 'minimal', failure_expected: true)
      expect(output).to match /Processing release 'test_release\/create'/
      expect(output).to match /not a directory/
      expect(output).not_to match /Succeeded/
    end

    it 'rejects paths that are not local files' do
      deployment_manifest = yaml_file('deployment_manifest', Bosh::Spec::Deployments.local_release_manifest('http://goobers.com/zakrulez', 'create'))

      output = bosh_runner.run("deploy #{deployment_manifest.path}", deployment_name: 'minimal', failure_expected: true)
      expect(output).to match /Processing release 'test_release\/create'/
      expect(output).to match /no such file or directory/
      expect(output).not_to match /Succeeded/
    end
  end
end
