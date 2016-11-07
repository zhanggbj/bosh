require_relative '../../spec_helper'
require 'bosh/dev/table_parser'

describe 'upload release', type: :integration do
  include Bosh::Spec::CreateReleaseOutputParsers
  with_reset_sandbox_before_each

  it 'can upload a release' do
    release_filename = spec_asset('test_release.tgz')

    target_and_login
    bosh_runner.run("upload-release #{release_filename}")

    table_output = table(bosh_runner.run('releases', json: true))
    expect(table_output).to include({'Name' => 'test_release', 'Version' => '1', 'Commit Hash' => String})
    expect(table_output.length).to eq(1)
  end

  context 'when release tarball contents are not sorted' do
    it 'updates job successfully' do
      target_and_login
      bosh_runner.run("upload-release #{spec_asset('unsorted-release-0+dev.1.tgz')}")

      out = bosh_runner.run("upload-release #{spec_asset('unsorted-release-0+dev.2.tgz')}")

      expect(out).to include('Creating new jobs: foobar/')
      expect(out).to include('Processing 2 existing packages')
    end
  end

  it 'can upload a release without any package changes when using --rebase option' do
    Dir.chdir(ClientSandbox.test_release_dir) do
      FileUtils.rm_rf('dev_releases')

      out = bosh_runner.run_in_current_dir('create-release --tarball')
      release_tarball = parse_release_tarball_path(out)

      target_and_login

      # upload the release for the first time
      bosh_runner.run("upload-release #{release_tarball}")

      # upload the same release with --rebase option
      bosh_runner.run("upload-release #{release_tarball} --rebase")

      # bosh should be able to generate the next version of the release
      table_output = table(bosh_runner.run('releases', json: true))
      expect(table_output).to include({'Name'=> 'bosh-release', 'Version'=> '0+dev.2', 'Commit Hash'=> String})
      expect(table_output).to include({'Name'=> 'bosh-release', 'Version'=> '0+dev.1', 'Commit Hash'=> String})
      expect(table_output.length).to eq(2)
    end
  end

  context 'when uploading a compiled release without "./" prefix in the tarball' do
    before {
      target_and_login
      bosh_runner.run("upload-stemcell #{spec_asset('light-bosh-stemcell-3001-aws-xen-hvm-centos-7-go_agent.tgz')}")

      cloud_config_with_centos = Bosh::Spec::Deployments.simple_cloud_config
      cloud_config_with_centos['resource_pools'][0]['stemcell']['name'] = 'bosh-aws-xen-hvm-centos-7-go_agent'
      cloud_config_with_centos['resource_pools'][0]['stemcell']['version'] = '3001'
      upload_cloud_config(:cloud_config_hash => cloud_config_with_centos)
    }

    it 'should upload successfully and not raise an error' do
      bosh_runner.run("upload-release #{spec_asset('compiled_releases/release-test_release-1-on-centos-7-stemcell-3001_without_dot_slash_prefix.tgz')}")
    end
  end

  it 'uploads the latest generated release if no release path given' do
    Dir.chdir(ClientSandbox.test_release_dir) do
      FileUtils.rm_rf('dev_releases')

      bosh_runner.run_in_current_dir('create-release')
      target_and_login
      bosh_runner.run_in_current_dir('upload-release')
    end
    table_output = table(bosh_runner.run('releases', json: true))
    expect(table_output).to include({'Name'=> 'bosh-release', 'Version'=> '0+dev.1', 'Commit Hash'=> String})
    expect(table_output.length).to eq(1)
  end

  it 'sparsely uploads the release' do
    Dir.chdir(ClientSandbox.test_release_dir) do
      FileUtils.rm_rf('dev_releases')

      out = bosh_runner.run_in_current_dir('create-release --tarball')
      release_tarball_1 = parse_release_tarball_path(out)
      expect(File).to exist(release_tarball_1)

      target_and_login
      bosh_runner.run("upload-release #{release_tarball_1}")

      new_file = File.join('src', 'bar', 'bla')
      begin
        FileUtils.touch(new_file)

        out = bosh_runner.run_in_current_dir('create-release --force --tarball')
        release_tarball_2 = parse_release_tarball_path(out)
        expect(File).to exist(release_tarball_2)
      ensure
        FileUtils.rm_rf(new_file)
      end

      out = bosh_runner.run("upload-release #{release_tarball_2}")
      expect(out).to match /Creating new packages: bar\//
      expect(out).to match /Processing 17 existing packages/
      expect(out).to match /Processing 22 existing jobs/

      table_output = table(bosh_runner.run('releases', json: true))
      expect(table_output).to include({'Name'=> 'bosh-release', 'Version'=> '0+dev.2', 'Commit Hash'=> String})
      expect(table_output).to include({'Name'=> 'bosh-release', 'Version'=> '0+dev.1', 'Commit Hash'=> String})
      expect(table_output.length).to eq(2)
    end
  end

  it 'cannot upload malformed release', no_reset: true do
    target_and_login

    release_filename = spec_asset('release_invalid_checksum.tgz')
    out = bosh_runner.run("upload-release #{release_filename}", failure_expected: true)
    expect(out).to match /Error: version presence, version format/
  end

  it 'marks releases that have uncommitted changes' do
    commit_hash = ''

    Dir.chdir(ClientSandbox.test_release_dir) do
      commit_hash = `git show-ref --head --hash=7 2> /dev/null`.split.first

      new_file = File.join('src', 'bar', 'bla')
      begin
        FileUtils.touch(new_file)

        bosh_runner.run_in_current_dir('create-release --force')
        release_manifest_1 = "#{Dir.pwd}/dev_releases/bosh-release/bosh-release-0+dev.1.yml"
      ensure
        FileUtils.rm_rf(new_file)
      end
      release_manifest = Psych.load_file(release_manifest_1)
      expect(release_manifest['commit_hash']).to eq commit_hash
      expect(release_manifest['uncommitted_changes']).to be(true)

      target_and_login
      bosh_runner.run_in_current_dir('upload-release')
    end

    table_output = table(bosh_runner.run('releases', json: true))
    expect(table_output).to include({'Name'=> 'bosh-release', 'Version'=> '0+dev.1', 'Commit Hash'=> "#{commit_hash}+"})
  end

  it 'raises an error when --sha1 is used when uploading a local release' do
    pending('cli2: #132688541')
    target_and_login
    expect {
      bosh_runner.run("upload-release #{spec_asset('test_release.tgz')} --sha1 abcd1234")
    }.to raise_error(RuntimeError, /Option '--sha1' is not supported for uploading local release/)
  end

  describe 'uploading a release that already exists' do
    before { target_and_login }

    context 'when the release is local' do
      let(:local_release_path) { spec_asset('compiled_releases/test_release/releases/test_release/test_release-1.tgz') }
      before { bosh_runner.run("upload-release #{local_release_path}") }

      it 'includes no package blobs in the repacked release and uploads it to the director' do
        output = bosh_runner.run("upload-release #{local_release_path}")
        expect(output).to include('Processing 5 existing packages')
        expect(output).to include('Processing 6 existing jobs')
      end
    end

    context 'when the release is remote' do
      let(:file_server) { Bosh::Spec::LocalFileServer.new(spec_asset(''), file_server_port, logger) }
      let(:file_server_port) { current_sandbox.port_provider.get_port(:releases_repo) }

      before { file_server.start }
      after { file_server.stop }

      let(:release_url) { file_server.http_url('compiled_releases/test_release/releases/test_release/test_release-1.tgz') }

      before { bosh_runner.run("upload-release #{release_url}") }

      it 'tells the user and does not exit as a failure' do
        output = bosh_runner.run("upload-release #{release_url}")

        expect(output).to_not include('Creating new packages')
        expect(output).to_not include('Creating new jobs')
        expect(output).to include('Processing 5 existing packages')
        expect(output).to include('Processing 6 existing jobs')
      end

      it 'does not affect the blobstore ids of the source package blobs' do
        inspect1 = bosh_runner.run('inspect-release test_release/1')
        bosh_runner.run("upload-release #{release_url}")
        inspect2 = bosh_runner.run('inspect-release test_release/1')

        expect(inspect1).to eq(inspect2)
      end
    end
  end

  describe 'when the release is remote' do

    before { target_and_login }
    let(:file_server) { Bosh::Spec::LocalFileServer.new(spec_asset(''), file_server_port, logger) }
    let(:file_server_port) { current_sandbox.port_provider.get_port(:releases_repo) }

    before { file_server.start }
    after { file_server.stop }

    let(:release_url) { file_server.http_url('compiled_releases/test_release/releases/test_release/test_release-1.tgz') }
    let(:sha1) { '14ab572f7d00333d8e528ab197a513d44c709257' }

    it 'accepts the release when the sha1 matches' do
      output = bosh_runner.run("upload-release #{release_url} --sha1 #{sha1}")

      expect(output).to include('Creating new packages')
      expect(output).to include('Creating new jobs')
    end

    it 'rejects the release when the sha1 does not match' do
      pending('cli2: #130881395')
      expect {
        bosh_runner.run("upload-release #{release_url} --sha1 abcd1234")
      }.to raise_error(RuntimeError, /Error: Release SHA1 '#{sha1}' does not match the expected SHA1 'abcd1234'/)
    end
  end

  describe 're-uploading a release after it fails in a previous attempt' do
    before { target_and_login }

    it 'should not throw an error, and should backfill missing items while not uploading already uploaded packages' do
      bosh_runner.run("upload-release #{spec_asset('compiled_releases/test_release-1-corrupted.tgz')}")
      clean_release_out = bosh_runner.run("upload-release #{spec_asset('compiled_releases/test_release/releases/test_release/test_release-1.tgz')}")

      expect(clean_release_out).to include('Creating new packages: pkg_5_depends_on_4_and_1/3cacf579322370734855c20557321dadeee3a7a4')
      expect(clean_release_out).to include('Processing 4 existing packages')
      expect(clean_release_out).to include('Creating new jobs: job_using_pkg_5/fb41300edf220b1823da5ab4c243b085f9f249af')
      expect(clean_release_out).to include('Processing 5 existing jobs')

      bosh_releases_out = table(bosh_runner.run('releases', json: true))
      expect(bosh_releases_out).to include({'Name' => 'test_release', 'Version' => '1', 'Commit Hash' => '50e58513+'})

      inspect_release_out = table(bosh_runner.run('inspect-release test_release/1', json: true))
      expect(inspect_release_out).to include({'Job' => 'job_using_pkg_1/9a5f09364b2cdc18a45172c15dca21922b3ff196', 'Blobstore ID' => String, 'SHA1' => 'a7d51f65cda79d2276dc9cc254e6fec523b07b02'})
      expect(inspect_release_out).to include({'Job' => 'job_using_pkg_1_and_2/673c3689362f2adb37baed3d8d4344cf03ff7637', 'Blobstore ID' => String, 'SHA1' => 'c9acbf245d4b4721141b54b26bee20bfa58f4b54'})
      expect(inspect_release_out).to include({'Job' => 'job_using_pkg_2/8e9e3b5aebc7f15d661280545e9d1c1c7d19de74', 'Blobstore ID' => String, 'SHA1' => '79475b0b035fe70f13a777758065210407170ec3'})
      expect(inspect_release_out).to include({'Job' => 'job_using_pkg_3/54120dd68fab145433df83262a9ba9f3de527a4b', 'Blobstore ID' => String, 'SHA1' => 'ab4e6077ecf03399f215e6ba16153fd9ebbf1b5f'})
      expect(inspect_release_out).to include({'Job' => 'job_using_pkg_4/0ebdb544f9c604e9a3512299a02b6f04f6ea6d0c', 'Blobstore ID' => String, 'SHA1' => '1ff32a12e0c574720dd8e5111834bac67229f5c1'})
      expect(inspect_release_out).to include({'Job' => 'job_using_pkg_5/fb41300edf220b1823da5ab4c243b085f9f249af', 'Blobstore ID' => String, 'SHA1' => '37350e20c6f78ab96a1191e5d97981a8d2831665'})

      expect(inspect_release_out).to include( {'Package' => 'pkg_1/16b4c8ef1574b3f98303307caad40227c208371f', 'Compiled for' => '(source)', 'Blobstore ID' => String, 'SHA1'=> '93fade7dd8950d8a1dd2bf5ec751e478af3150e9'})
      expect(inspect_release_out).to include( {'Package' => 'pkg_2/f5c1c303c2308404983cf1e7566ddc0a22a22154', 'Compiled for' => '(source)', 'Blobstore ID' => String, 'SHA1'=> 'b2751daee5ef20b3e4f3ebc3452943c28f584500'})
      expect(inspect_release_out).to include( {'Package' => 'pkg_3_depends_on_2/413e3e9177f0037b1882d19fb6b377b5b715be1c', 'Compiled for' => '(source)', 'Blobstore ID' => String, 'SHA1'=> '62fff2291aac72f5bd703dba0c5d85d0e23532e0'})
      expect(inspect_release_out).to include( {'Package' => 'pkg_4_depends_on_3/9207b8a277403477e50cfae52009b31c840c49d4', 'Compiled for' => '(source)', 'Blobstore ID' => String, 'SHA1'=> '603f212d572b0307e4c51807c5e03c47944bb9c3'})
      expect(inspect_release_out).to include( {'Package' => 'pkg_5_depends_on_4_and_1/3cacf579322370734855c20557321dadeee3a7a4', 'Compiled for' => '(source)', 'Blobstore ID' => String, 'SHA1'=> 'ad733ca76ab4747747d8f9f1ddcfa568519a2e00'})
    end

    it 'does not allow uploading same release version with different commit hash' do
      bosh_runner.run("upload-release #{spec_asset('compiled_releases/test_release-1-corrupted_with_different_commit.tgz')}")
      expect {
        bosh_runner.run("upload-release #{spec_asset('compiled_releases/test_release/releases/test_release/test_release-1.tgz')}")
      }.to raise_error(RuntimeError, /Error: release 'test_release\/1' has already been uploaded with commit_hash as '50e58513' and uncommitted_changes as 'true'/)
    end
  end

  describe 'uploading a release with the same packages as some other release' do
    before { target_and_login }

    it 'omits identical packages from the repacked tarball and creates new copies of the blobstore entries under the new release' do
      bosh_runner.run("upload-release #{spec_asset('compiled_releases/test_release/releases/test_release/test_release-1.tgz')}")
      bosh_runner.run("upload-release #{spec_asset('compiled_releases/test_release/releases/release_with_shared_blobs/release_with_shared_blobs-1.tgz')}")

      test_release_desc = table(bosh_runner.run('inspect-release test_release/1', json: true))
      shared_release_desc = table(bosh_runner.run('inspect-release release_with_shared_blobs/1', json: true))

      test_release_blobstore_ids = test_release_desc.map do |item|
        item['Blobstore ID']
      end

      shared_release_blobstore_ids = shared_release_desc.map do |item|
        item['Blobstore ID']
      end

      expect(shared_release_blobstore_ids & test_release_blobstore_ids).to eq([])

      test_release_artifacts = test_release_desc.map do |item|
        { 'Artifact' => item.fetch('Package', item['Job']), 'SHA1' => item['SHA1'] }
      end
      shared_release_artifacts = shared_release_desc.map do |item|
        { 'Artifact' => item.fetch('Package', item['Job']), 'SHA1' => item['SHA1'] }
      end

      expect((shared_release_artifacts & test_release_artifacts).length).to eq(test_release_artifacts.length)
    end

    it 'raises an error if the uploaded release version already exists but there are packages with different fingerprints' do
      bosh_runner.run("upload-release #{spec_asset('compiled_releases/test_release/releases/test_release/test_release-1.tgz')}")

      expect {
        bosh_runner.run("upload-release #{spec_asset('compiled_releases/test_release/releases/test_release/test_release-1-pkg2-updated.tgz')}")
      }.to raise_error(RuntimeError, /Error: package 'pkg_2' had different fingerprint in previously uploaded release 'test_release\/1'/)
    end

    it 'raises an error if the uploaded release version already exists but there are jobs with different fingerprints' do
      bosh_runner.run("upload-release #{spec_asset('compiled_releases/test_release/releases/test_release/test_release-1.tgz')}")

      expect {
        bosh_runner.run("upload-release #{spec_asset('compiled_releases/test_release/releases/test_release/test_release-1-job1-updated.tgz')}")
      }.to raise_error(RuntimeError, /Error: job 'job_using_pkg_1' had different fingerprint in previously uploaded release 'test_release\/1'/)
    end

    it 'allows sharing of packages across releases when the original packages does not have source' do
      bosh_runner.run("upload-stemcell #{spec_asset('light-bosh-stemcell-3001-aws-xen-hvm-centos-7-go_agent.tgz')}")
      bosh_runner.run("upload-release #{spec_asset('compiled_releases/release-test_release-1-on-centos-7-stemcell-3001.tgz')}")
      output = bosh_runner.run("upload-release #{spec_asset('compiled_releases/test_release/releases/release_with_shared_blobs/release_with_shared_blobs-1.tgz')}")
      expect(output).to include('Creating new packages: pkg_1/16b4c8ef1574b3f98303307caad40227c208371f')
      expect(output).to include('Release has been created: release_with_shared_blobs/1')
    end
  end

  describe 'uploading compiled releases' do
    before { target_and_login }

    it 'should not raise an error if no stemcell matched the criteria' do
      expect {
        bosh_runner.run("upload-release #{spec_asset('release-hello-go-50-on-centos-7-stemcell-3001.tgz')}")
      }.not_to raise_error
    end

    it 'should populate compiled packages for one stemcell' do
      bosh_runner.run("upload-stemcell #{spec_asset('light-bosh-stemcell-3001-aws-xen-hvm-centos-7-go_agent.tgz')}")
      output = bosh_runner.run("upload-release #{spec_asset('release-hello-go-50-on-centos-7-stemcell-3001.tgz')}")

      expect(output).to include('Creating new packages: go-lang-1.4.2/7d4bf6e5267a46d414af2b9a62e761c2e5f33a8d')
      expect(output).to include('Creating new compiled packages: go-lang-1.4.2/7d4bf6e5267a46d414af2b9a62e761c2e5f33a8d for centos-7/3001')
      expect(output).to include('Creating new compiled packages: hello-go/03df8c27c4525622aacc0d7013af30a9f2195393 for centos-7/3001')
      expect(output).to include('Creating new jobs: hello-go/0cf937b9a063cf96bd7506fa31699325b40d2d08')
    end

    it 'should populate compiled packages for two matching stemcells' do
      bosh_runner.run("upload-stemcell #{spec_asset('light-bosh-stemcell-3001-aws-xen-centos-7-go_agent.tgz')}")
      bosh_runner.run("upload-stemcell #{spec_asset('light-bosh-stemcell-3001-aws-xen-hvm-centos-7-go_agent.tgz')}")
      output = bosh_runner.run("upload-release #{spec_asset('release-hello-go-50-on-centos-7-stemcell-3001.tgz')}")

      expect(output).to include('Creating new packages: go-lang-1.4.2/7d4bf6e5267a46d414af2b9a62e761c2e5f33a8d')
      expect(output).to include('Creating new compiled packages: go-lang-1.4.2/7d4bf6e5267a46d414af2b9a62e761c2e5f33a8d for centos-7/3001')
      expect(output).to include('Creating new compiled packages: hello-go/03df8c27c4525622aacc0d7013af30a9f2195393 for centos-7/3001')
      expect(output).to include('Creating new jobs: hello-go/0cf937b9a063cf96bd7506fa31699325b40d2d08')
    end

    it 'upload a compiled release tarball' do
      bosh_runner.run("upload-stemcell #{spec_asset('valid_stemcell.tgz')}")
      output = bosh_runner.run("upload-release #{spec_asset('release-hello-go-50-on-toronto-os-stemcell-1.tgz')}")
      expect(output).to include('Creating new packages: hello-go/b3df8c27c4525622aacc0d7013af30a9f2195393')
      expect(output).to include('Creating new compiled packages: hello-go/b3df8c27c4525622aacc0d7013af30a9f2195393 for toronto-os/1')
      expect(output).to include('Creating new jobs: hello-go/0cf937b9a063cf96bd7506fa31699325b40d2d08')
    end

    it 'should not do any expensive operations for 2nd upload of a compiled release tarball' do
      bosh_runner.run("upload-stemcell #{spec_asset('valid_stemcell.tgz')}")
      output = bosh_runner.run("upload-release #{spec_asset('release-hello-go-50-on-toronto-os-stemcell-1.tgz')}")
      expect(output).to include('Creating new packages: hello-go/')
      expect(output).to include('Creating new compiled packages: hello-go/')
      expect(output).to include('Creating new jobs: hello-go/')

      output = bosh_runner.run("upload-release #{spec_asset('release-hello-go-50-on-toronto-os-stemcell-1.tgz')}")
      #expect(output).to include('Processing 1 existing compiled package')
      expect(output).to include('Processing 1 existing job')
      expect(output).to include('Compiled Release has been created')
    end

    it 'should use dependencies in matching for 2nd upload of a compiled release tarball' do
      bosh_runner.run("upload-stemcell #{spec_asset('light-bosh-stemcell-3001-aws-xen-hvm-centos-7-go_agent.tgz')}")
      output = bosh_runner.run("upload-release #{spec_asset('compiled_releases/release-test_release-1-on-centos-7-stemcell-3001.tgz')}")
      expect(output).to include('Creating new packages')
      expect(output).to include('Creating new compiled packages')
      expect(output).to include('Creating new jobs')

      output = bosh_runner.run("upload-release #{spec_asset('compiled_releases/release-test_release-1-on-centos-7-stemcell-3001.tgz')}")
      expect(output).to include('Processing 6 existing job')
    end

    it 'upload a new version of compiled release tarball when the compiled release is already uploaded' do
      bosh_runner.run("upload-stemcell #{spec_asset('valid_stemcell.tgz')}")
      bosh_runner.run("upload-release #{spec_asset('release-hello-go-50-on-toronto-os-stemcell-1.tgz')}")

      output = bosh_runner.run("upload-release #{spec_asset('release-hello-go-51-on-toronto-os-stemcell-1.tgz')}")
      expect(output).to include('Processing 1 existing package')
      expect(output).to include('Processing 1 existing job')
    end

    it 'backfills the source code for an already exisiting compiled release' do
      bosh_runner.run("upload-stemcell #{spec_asset('light-bosh-stemcell-3001-aws-xen-hvm-centos-7-go_agent.tgz')}")
      bosh_runner.run("upload-release #{spec_asset('compiled_releases/release-test_release-1-on-centos-7-stemcell-3001.tgz')}")

      bosh_runner.run("upload-release #{spec_asset('compiled_releases/test_release/releases/test_release/test_release-1.tgz')}")

      output = table(bosh_runner.run('inspect-release test_release/1', json: true))
      output.select{|item| item.has_key? 'Package'}.each do |item|
        expect(['(source)', 'centos-7/3001']).to include(item['Compiled for'])
      end
    end

    it 'backfill source of an already exisitng compiled release when there is another release that has exactly same contents' do
      bosh_runner.run("upload-stemcell #{spec_asset('light-bosh-stemcell-3001-aws-xen-hvm-centos-7-go_agent.tgz')}")

      bosh_runner.run("upload-release #{spec_asset('compiled_releases/test_release/releases/test_release/test_release_with_different_name.tgz')}")
      bosh_runner.run("upload-release #{spec_asset('compiled_releases/release-test_release-1-on-centos-7-stemcell-3001.tgz')}")
      bosh_runner.run("upload-release #{spec_asset('compiled_releases/test_release/releases/test_release/test_release-1.tgz')}")

      inspect_release_with_other_name_out = table(bosh_runner.run('inspect-release test_release_with_other_name/1', json: true))
      inspect_release_out = table(bosh_runner.run('inspect-release test_release/1', json: true))

      expect(inspect_release_out).to include({'Package'=> 'pkg_1/16b4c8ef1574b3f98303307caad40227c208371f', 'Compiled for'=> '(source)', 'Blobstore ID'=> String, 'SHA1'=> '93fade7dd8950d8a1dd2bf5ec751e478af3150e9'})
      expect(inspect_release_out).to include({'Package'=> 'pkg_1/16b4c8ef1574b3f98303307caad40227c208371f', 'Compiled for'=> 'centos-7/3001', 'Blobstore ID'=> String, 'SHA1'=> '735987b52907d970106f38413825773eec7cc577'})
      expect(inspect_release_out).to include({'Package'=> 'pkg_2/f5c1c303c2308404983cf1e7566ddc0a22a22154', 'Compiled for'=> '(source)', 'Blobstore ID'=> String, 'SHA1'=> 'b2751daee5ef20b3e4f3ebc3452943c28f584500'})
      expect(inspect_release_out).to include({'Package'=> 'pkg_2/f5c1c303c2308404983cf1e7566ddc0a22a22154', 'Compiled for'=> 'centos-7/3001', 'Blobstore ID'=> String, 'SHA1'=> '5b21895211d8592c129334e3d11bd148033f7b82'})
      expect(inspect_release_out).to include({'Package'=> 'pkg_3_depends_on_2/413e3e9177f0037b1882d19fb6b377b5b715be1c', 'Compiled for'=> '(source)', 'Blobstore ID'=> String, 'SHA1'=> '62fff2291aac72f5bd703dba0c5d85d0e23532e0'})
      expect(inspect_release_out).to include({'Package'=> 'pkg_3_depends_on_2/413e3e9177f0037b1882d19fb6b377b5b715be1c', 'Compiled for'=> 'centos-7/3001', 'Blobstore ID'=> String, 'SHA1'=> 'f5cc94a01d2365bbeea00a4765120a29cdfb3bd7'})
      expect(inspect_release_out).to include({'Package'=> 'pkg_4_depends_on_3/9207b8a277403477e50cfae52009b31c840c49d4', 'Compiled for'=> '(source)', 'Blobstore ID'=> String, 'SHA1'=> '603f212d572b0307e4c51807c5e03c47944bb9c3'})
      expect(inspect_release_out).to include({'Package'=> 'pkg_4_depends_on_3/9207b8a277403477e50cfae52009b31c840c49d4', 'Compiled for'=> 'centos-7/3001', 'Blobstore ID'=> String, 'SHA1'=> 'f21275861158ad864951faf76da0dce9c1b5f215'})
      expect(inspect_release_out).to include({'Package'=> 'pkg_5_depends_on_4_and_1/3cacf579322370734855c20557321dadeee3a7a4', 'Compiled for'=> '(source)', 'Blobstore ID'=> String, 'SHA1'=> 'ad733ca76ab4747747d8f9f1ddcfa568519a2e00'})
      expect(inspect_release_out).to include({'Package'=> 'pkg_5_depends_on_4_and_1/3cacf579322370734855c20557321dadeee3a7a4', 'Compiled for'=> 'centos-7/3001', 'Blobstore ID'=> String, 'SHA1'=> '002deec46961440df01c620be491e5b12246c5df'})

      # make sure the the blobstore_ids of the packages in the 2 releases are different
      inspect_release_with_other_name_packages = inspect_release_with_other_name_out.map{|item| item['Blobstore ID']}
      inspect_release_packages = inspect_release_out.map{|item| item['Blobstore ID']}

      expect((inspect_release_with_other_name_packages & inspect_release_packages).length).to eq(0)
    end

    it 'allows uploading a compiled release after its source release has been uploaded' do
      bosh_runner.run("upload-stemcell #{spec_asset('light-bosh-stemcell-3001-aws-xen-centos-7-go_agent.tgz')}")
      bosh_runner.run("upload-stemcell #{spec_asset('light-bosh-stemcell-3001-aws-xen-hvm-centos-7-go_agent.tgz')}")
      bosh_runner.run("upload-release #{spec_asset('compiled_releases/test_release/releases/test_release/test_release-1.tgz')}")

      bosh_runner.run("upload-release #{spec_asset('compiled_releases/release-test_release-1-on-centos-7-stemcell-3001.tgz')}")

      output = table(bosh_runner.run('inspect-release test_release/1', json: true))
      expect(output).to include({'Job'=> 'job_using_pkg_1/9a5f09364b2cdc18a45172c15dca21922b3ff196', 'Blobstore ID'=> String, 'SHA1'=> 'a7d51f65cda79d2276dc9cc254e6fec523b07b02'})
      expect(output).to include({'Job'=> 'job_using_pkg_1_and_2/673c3689362f2adb37baed3d8d4344cf03ff7637', 'Blobstore ID'=> String, 'SHA1'=> 'c9acbf245d4b4721141b54b26bee20bfa58f4b54'})
      expect(output).to include({'Job'=> 'job_using_pkg_2/8e9e3b5aebc7f15d661280545e9d1c1c7d19de74', 'Blobstore ID'=> String, 'SHA1'=> '79475b0b035fe70f13a777758065210407170ec3'})
      expect(output).to include({'Job'=> 'job_using_pkg_3/54120dd68fab145433df83262a9ba9f3de527a4b', 'Blobstore ID'=> String, 'SHA1'=> 'ab4e6077ecf03399f215e6ba16153fd9ebbf1b5f'})
      expect(output).to include({'Job'=> 'job_using_pkg_4/0ebdb544f9c604e9a3512299a02b6f04f6ea6d0c', 'Blobstore ID'=> String, 'SHA1'=> '1ff32a12e0c574720dd8e5111834bac67229f5c1'})
      expect(output).to include({'Job'=> 'job_using_pkg_5/fb41300edf220b1823da5ab4c243b085f9f249af', 'Blobstore ID'=> String, 'SHA1'=> '37350e20c6f78ab96a1191e5d97981a8d2831665'})

      expect(output).to include({'Package'=> 'pkg_1/16b4c8ef1574b3f98303307caad40227c208371f', 'Compiled for'=> '(source)', 'Blobstore ID'=> String, 'SHA1'=> '93fade7dd8950d8a1dd2bf5ec751e478af3150e9' })
      expect(output).to include({'Package'=> 'pkg_1/16b4c8ef1574b3f98303307caad40227c208371f', 'Compiled for'=> 'centos-7/3001', 'Blobstore ID'=> String, 'SHA1'=> '735987b52907d970106f38413825773eec7cc577' })
      expect(output).to include({'Package'=> 'pkg_2/f5c1c303c2308404983cf1e7566ddc0a22a22154', 'Compiled for'=> '(source)', 'Blobstore ID'=> String, 'SHA1'=> 'b2751daee5ef20b3e4f3ebc3452943c28f584500' })
      expect(output).to include({'Package'=> 'pkg_2/f5c1c303c2308404983cf1e7566ddc0a22a22154', 'Compiled for'=> 'centos-7/3001', 'Blobstore ID'=> String, 'SHA1'=> '5b21895211d8592c129334e3d11bd148033f7b82' })
      expect(output).to include({'Package'=> 'pkg_3_depends_on_2/413e3e9177f0037b1882d19fb6b377b5b715be1c', 'Compiled for'=> '(source)', 'Blobstore ID'=> String, 'SHA1'=> '62fff2291aac72f5bd703dba0c5d85d0e23532e0' })
      expect(output).to include({'Package'=> 'pkg_3_depends_on_2/413e3e9177f0037b1882d19fb6b377b5b715be1c', 'Compiled for'=> 'centos-7/3001', 'Blobstore ID'=> String, 'SHA1'=> 'f5cc94a01d2365bbeea00a4765120a29cdfb3bd7' })
      expect(output).to include({'Package'=> 'pkg_4_depends_on_3/9207b8a277403477e50cfae52009b31c840c49d4', 'Compiled for'=> '(source)', 'Blobstore ID'=> String, 'SHA1'=> '603f212d572b0307e4c51807c5e03c47944bb9c3' })
      expect(output).to include({'Package'=> 'pkg_4_depends_on_3/9207b8a277403477e50cfae52009b31c840c49d4', 'Compiled for'=> 'centos-7/3001', 'Blobstore ID'=> String, 'SHA1'=> 'f21275861158ad864951faf76da0dce9c1b5f215' })
      expect(output).to include({'Package'=> 'pkg_5_depends_on_4_and_1/3cacf579322370734855c20557321dadeee3a7a4', 'Compiled for'=> '(source)', 'Blobstore ID'=> String, 'SHA1'=> 'ad733ca76ab4747747d8f9f1ddcfa568519a2e00' })
      expect(output).to include({'Package'=> 'pkg_5_depends_on_4_and_1/3cacf579322370734855c20557321dadeee3a7a4', 'Compiled for'=> 'centos-7/3001', 'Blobstore ID'=> String, 'SHA1'=> '002deec46961440df01c620be491e5b12246c5df' })
    end

    it 'allows uploading two source releases with different version numbers but identical contents' do
      bosh_runner.run("upload-release #{spec_asset('compiled_releases/test_release/releases/test_release/test_release-1.tgz')}")
      bosh_runner.run("upload-release #{spec_asset('compiled_releases/test_release/releases/test_release/test_release-4-same-packages-as-1.tgz')}")
    end
  end

  describe 'uploading release with --fix' do
    def get_blob_ids(table_string)
      table_string.lines.inject([]) do |result, line|
        match = line.match(/\|\s(\S+)\s\|\s\S+\s\|$/)
        result << match[1] if match
        result
      end
    end

    def search_and_delete_files(file_path, blob_files)
      if File.directory? file_path
        Dir.foreach(file_path) do |file|
          if file !='.' and file !='..'
            search_and_delete_files(file_path+'/'+file, blob_files)
          end
        end
      else
        if blob_files.include? File.basename(file_path)
          FileUtils.rm_rf(File.realpath(file_path))
        end
      end
    end

    before { target_and_login }

    context 'when uploading source package' do
      it 'Re-uploads all packages to replace old ones and eliminates broken compiled packages' do
        Dir.chdir(ClientSandbox.test_release_dir) do
          bosh_runner.run_in_current_dir('create-release')
          bosh_runner.run_in_current_dir('upload-release')
        end

        bosh_runner.run("upload-stemcell #{spec_asset('valid_stemcell.tgz')}")

        cloud_config_manifest = yaml_file('cloud_manifest', Bosh::Spec::Deployments.simple_cloud_config)
        bosh_runner.run("update-cloud-config #{cloud_config_manifest.path}")

        deployment_manifest = yaml_file('deployment_manifest', Bosh::Spec::Deployments.simple_manifest)

        bosh_runner.run("deploy #{deployment_manifest.path}", deployment_name: 'simple')

        inspect1 = bosh_runner.run('inspect-release bosh-release/0+dev.1')
        blob_files_1 = get_blob_ids(inspect1)

        # Delete all package and compiled package blob files
        search_and_delete_files(current_sandbox.blobstore_storage_dir, blob_files_1)

        Dir.chdir(ClientSandbox.test_release_dir) do
          bosh_runner.run_in_current_dir('upload-release --fix')
        end

        bosh_runner.run("deploy #{deployment_manifest.path}", deployment_name: 'simple')

        inspect2 = bosh_runner.run('inspect-release bosh-release/0+dev.1')
        blob_files_2 = get_blob_ids(inspect2)

        expect(blob_files_2 - blob_files_1).to eq blob_files_2
      end
    end

    context 'when uploading compiled package' do
      it 'Re-uploads all compiled packages to replace old ones' do
        bosh_runner.run("upload-stemcell #{spec_asset('valid_stemcell.tgz')}")
        bosh_runner.run("upload-release #{spec_asset('release-hello-go-50-on-toronto-os-stemcell-1.tgz')}")

        inspect1 = bosh_runner.run('inspect-release hello-go/50')
        blob_files_1 = get_blob_ids(inspect1.split(/\n\n/)[1])

        # Delete all package and compiled package blob files
        search_and_delete_files(current_sandbox.blobstore_storage_dir, blob_files_1)

        bosh_runner.run("upload-release #{spec_asset('release-hello-go-50-on-toronto-os-stemcell-1.tgz')} --fix")

        inspect2 = bosh_runner.run('inspect-release hello-go/50')
        blob_files_2 = get_blob_ids(inspect2.split(/\n\n/)[1])

        expect(blob_files_2 - blob_files_1).to eq blob_files_2
      end
    end
  end
end
