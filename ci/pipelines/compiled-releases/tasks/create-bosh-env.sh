#!/usr/bin/env bash
set -ex


source bosh-src/ci/pipelines/compiled-releases/tasks/utils.sh
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

STEMCELL_NAME="$(ls stemcell|grep tgz)"
ORG_STEMCELL_NAME="light-bosh-stemcell-3312.9-softlayer-xen-ubuntu-trusty-go_agent.tgz"
cp bosh-src/ci/pipelines/compiled-releases/templates/bosh-template.yml bosh-template.yml
sed -i 's/'"$ORG_STEMCELL_NAME"'/'"$STEMCELL_NAME"'/g' bosh-template.yml

echo "here"
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
      tar -zcvf  /tmp/director_state.tgz ./ >/dev/null 2>&1
    popd
    mv /tmp/director_state.tgz director_state/
  }

trap finish ERR

echo "Using bosh-cli $($BOSH_CLI -v)"
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
export BOSH_CLIENT_SECRET=$(${BOSH_CLI} int ${deployment_dir}/credentials.yml --path /DI_ADMIN_PASSWORD)

$BOSH_CLI -e bosh-env login

trap - ERR

finish