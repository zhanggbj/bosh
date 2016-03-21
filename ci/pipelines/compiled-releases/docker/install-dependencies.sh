#!/usr/bin/env bash

set -e

apt-get update
apt-get -y install wget make

#Install bosh-init
wget https://s3.amazonaws.com/bosh-init-artifacts/bosh-init-0.0.81-linux-amd64 -O /bin/bosh-init
chmod +x /bin/bosh-init

#apt-get install installs ruby-1.9 maximum. We need to use ruby-install to install ruby 2.+
RUBY_INSTALL_VER="0.5.0"
RUBY_INSTALL_SHA1=d8061e46fe2ea40f867e219cdd7d28fea24f47ca
RUBY_INSTALL_URL=https://github.com/postmodern/ruby-install/archive/v${RUBY_INSTALL_VER}.tar.gz
RUBY_VER="2.1.3"
RUBY_VER_SHA256=36ce72f84ae4129f6cc66e33077a79d87b018ea7bf1dbc3d353604bf006f76d6

echo "Installing ruby-install v${RUBY_INSTALL_VER}..."
wget -O ruby-install-${RUBY_INSTALL_VER}.tar.gz $RUBY_INSTALL_URL
echo "${RUBY_INSTALL_SHA1} ruby-install-${RUBY_INSTALL_VER}.tar.gz" | sha1sum -c -
tar -xzvf ruby-install-${RUBY_INSTALL_VER}.tar.gz
cd ruby-install-${RUBY_INSTALL_VER}/
make install
cd ..
rm -rf ruby-install-${RUBY_INSTALL_VER}/
rm ruby-install-${RUBY_INSTALL_VER}.tar.gz

ruby-install --sha256 ${RUBY_VER_SHA256} --system ruby ${RUBY_VER}

gem install bundler

gem install bosh_cli --no-ri --no-rdoc
