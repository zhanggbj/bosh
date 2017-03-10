#!/usr/bin/env bash
set -e

source bosh-src/ci/pipelines/compiled-release/tasks/utils.sh
#source /etc/profile.d/chruby.sh
#chruby 2.2.4

check_param SL_VM_PREFIX
check_param SL_USERNAME
check_param SL_API_KEY
check_param SL_DATACENTER
check_param SL_VLAN_PUBLIC
check_param SL_VLAN_PRIVATE

#apt-get update > /dev/null 2>&1
#apt-get install -y python-pip python-dev> /dev/null 2>&1

#echo "Downloading SoftLayer CLI..."
#
#pip install SoftLayer  >/dev/null 2>&1
#
#echo "Using $(slcli --version)"

#cat > ~/.softlayer <<EOF
#[softlayer]
#username = $SL_USERNAME
#api_key = $SL_API_KEY
#endpoint_url = https://api.softlayer.com/xmlrpc/v3.1/
#timeout = 0
#EOF

deployment_dir="${PWD}/deployment"
mkdir -p $deployment_dir

SL_VM_DOMAIN=${SL_VM_PREFIX}.softlayer.com

BOSH_RELEASE_URI="file://$(echo bosh-release/*.tgz)"
CPI_RELEASE_URI="file://$(echo cpi-release/*.tgz)"
STEMCELL_URI="file://$(echo stemcell/*.tgz)"

ORG_BOSH_RELEASE_URI="file://bosh-release/bosh-261.tgz"
ORG_CPI_RELEASE_URI="file://bosh-softlayer-cpi-release/bosh-softlayer-cpi-release-4.tgz"
ORG_STEMCELL_URI="file://stemcell/light-bosh-stemcell-3312.9-softlayer-xen-ubuntu-trusty-go_agent.tgz"

sed -i 's/'"$ORG_BOSH_RELEASE_URI"'/'"$BOSH_RELEASE_URI"'/g;s/'"$ORG_CPI_RELEASE_URI"'/'"$ORG_BOSH_RELEASE_URI"'/g; s/'"$ORG_STEMCELL_URI"'/'"$ORG_BOSH_RELEASE_URI"'/g' \
bosh-src/ci/pipelines/compiled-release/templates/bosh-template.yml > bosh-template.yml

BOSH_CLI="$(pwd)/$(echo bosh-cli/bosh-cli-*)"
chmod +x ${BOSH_CLI}

  function finish {
    echo "Final state of director deployment:"
    echo "====================================================================="
    cat ${deployment_dir}/director-deploy-state.json
    echo "====================================================================="
    echo "Director:"
    echo "====================================================================="
    cat /etc/hosts | grep "$SL_VM_DOMAIN" | tee ${deployment_dir}/director-hosts
    echo "====================================================================="
    echo "Saving config..."
#    DIRECTOR_VM_ID=$(grep -Po '(?<=current_vm_cid": ")[^"]*' ${deployment_dir}/director-deploy-state.json)
#    slcli vs detail ${DIRECTOR_VM_ID} --passwords > ${deployment_dir}/director-detail
    cp $BOSH_CLI ${deployment_dir}/
    pushd ${deployment_dir}
      tar -zcvf  /tmp/director_artifacts.tgz ./ >/dev/null 2>&1
    popd
    mv /tmp/director_artifacts.tgz deploy-artifacts/
  }

trap finish ERR

echo "Using bosh-cli $(bosh-cli-v2/bosh-cli* -v)"
echo "Deploying director..."

$BOSH_CLI create-env bosh-template.yml \
                      --state=${deployment_dir}/director-deploy-state.json \
                      --vars-store ${deployment_dir}/credentials.yml \
                      -v SL_VM_PREFIX=${SL_VM_PREFIX} \
                      -v SL_VM_DOMAIN=${SL_VM_DOMAIN} \
                      -v SL_USERNAME=${SL_USERNAME} \
                      -v SL_API_KEY=${SL_API_KEY} \
                      -v SL_DATACENTER=${SL_DATACENTER} \
                      -v SL_VLAN_PUBLIC=${SL_VLAN_PUBLIC} \
                      -v SL_VLAN_PRIVATE=${SL_VLAN_PRIVATE}

echo "Trying to set target to director..."

$BOSH_CLI  -e ${SL_VM_DOMAIN} --ca-cert <($BOSH_CLI int ${deployment_dir}/credentials.yml --path /DIRECTOR_SSL/ca) alias-env bosh-env

echo "Trying to login to director..."

export BOSH_CLIENT=admin
export BOSH_CLIENT_SECRET=$(bosh-cli-v2/bosh-cli* int ${deployment_dir}/credentials.yml --path /DI_ADMIN_PASSWORD)

$BOSH_CLI -e bosh-env login

trap - ERR

finish

