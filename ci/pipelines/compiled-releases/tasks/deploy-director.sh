#!/usr/bin/env bash

set -eu

BOSH_RELEASE=$PWD/bosh-release/*.tgz
BOSH_AWS_CPI_RELEASE=$PWD/bosh-aws-cpi-release/*.tgz
STEMCELL=$PWD/stemcell/*.tgz

cd bosh-src/ci/pipelines/compiled-releases

sed \
  -e "s%{{access_key_id}}%$BOSH_INIT_ACCESS_KEY%g" \
  -e "s%{{secret_key_id}}%$BOSH_INIT_SECRET_KEY%g" \
  -e "s%{{bosh_username}}%$BOSH_USERNAME%g" \
  -e "s%{{bosh_password}}%$BOSH_PASSWORD%g" \
  -e "s%{{bosh_target_ip}}%$BOSH_TARGET_IP%g" \
  -e "s%{{bosh_release}}%$BOSH_RELEASE%g" \
  -e "s%{{bosh_aws_cpi_release}}%$BOSH_AWS_CPI_RELEASE%g" \
  -e "s%{{stemcell}}%$STEMCELL%g" \
  tasks/bosh-init-template.yml \
  > bosh-init.yml

echo "$BOSH_SSH_TUNNEL_KEY" > ssh_tunnel_key
chmod 600 ssh_tunnel_key

bosh-init deploy bosh-init.yml

bosh -n target "https://$BOSH_TARGET_IP:25555"
bosh login "$BOSH_USERNAME" "$BOSH_PASSWORD"

#
# create/upload cloud config
#

cat > /tmp/cloud-config <<EOF
---
vm_types:
- name: default
  cloud_properties:
    instance_type: c4.large
    ephemeral_disk:
      size: 8192

networks:
- name: private
  subnets:
  - range: 10.0.2.0/24
    gateway: 10.0.2.1
    dns: [169.254.169.253]
    reserved: [10.0.2.0-10.0.2.10]
    cloud_properties:
        subnet: "subnet-20d8bf56"

compilation:
  workers: 8
  vm_type: default
  network: private
EOF

bosh update cloud-config /tmp/cloud-config
