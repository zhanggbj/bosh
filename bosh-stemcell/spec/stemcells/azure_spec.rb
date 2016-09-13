require 'spec_helper'

describe 'Azure Stemcell', stemcell_image: true do
  context 'installed by system_parameters' do
    describe file('/var/vcap/bosh/etc/infrastructure') do
      it { should contain('azure') }
    end
  end

  context 'installed by bosh_disable_password_authentication' do
    describe 'disallows password authentication' do
      subject { file('/etc/ssh/sshd_config') }
      it { should contain /^PasswordAuthentication no$/ }
    end
  end

  context 'udf module should be enabled' do
    describe file('/etc/modprobe.d/blacklist.conf') do
      it { should_not contain 'install udf /bin/true' }
    end
  end
end
