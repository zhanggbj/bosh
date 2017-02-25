#!/bin/bash

set -e -x

source /etc/profile.d/chruby.sh
chruby 2.1

export BUNDLE_GEMFILE="${PWD}/bosh-src/src/Gemfile"

bundle install --local

DIRECTOR=`cat ${PWD}/director-state/director-info`

bosh() {
  bundle exec bosh -n -t "${DIRECTOR}" "$@"
}

# login
bosh login "${BOSH_DIRECTOR_USERNAME}" "${BOSH_DIRECTOR_PASSWORD}"

cleanup() {
  bosh cleanup --all
}
trap cleanup EXIT

# bosh upload stemcell
pushd stemcell
  bosh upload stemcell ./*.tgz
popd

# bosh upload release (syslog)
pushd syslog-release
  bosh upload release ./*.tgz
popd

env_attr() {
  local json=$1
  echo $json | jq --raw-output --arg attribute $2 '.[$attribute]'
}

#Build Cloud config
cat > "./cloud-config.yml" <<EOF
azs:
- name: z1
  cloud_properties:
    Datacenter: { Name: $SL_DATACENTER }

vm_types:
- name: compilation
  cloud_properties:
    Bosh_ip: $DIRECTOR
    StartCpus:  4
    MaxMemory:  8192
    EphemeralDiskSize: 100
    HourlyBillingFlag: true
    LocalDiskFlag: false
    VmNamePrefix: cc-compilation-worker-
    Domain: $SL_VM_DOMAIN
    PrimaryNetworkComponent:
       NetworkVlan:
          Id: $SL_VLAN_PUBLIC
    PrimaryBackendNetworkComponent:
       NetworkVlan:
          Id: $SL_VLAN_PRIVATE
- name: default
  cloud_properties:
    Bosh_ip: $DIRECTOR
    StartCpus:  4
    MaxMemory:  8192
    EphemeralDiskSize: 100
    HourlyBillingFlag: true
    LocalDiskFlag: false
    VmNamePrefix: $SL_VM_NAME_PREFIX
    Domain: $SL_VM_DOMAIN
    PrimaryNetworkComponent:
       NetworkVlan:
          Id: $SL_VLAN_PUBLIC
    PrimaryBackendNetworkComponent:
       NetworkVlan:
          Id: $SL_VLAN_PRIVATE

networks:
- name: default
  type: dynamic
  subnets:
  - {az: az1, dns: [ $DIRECTOR, 8.8.8.8, 10.0.80.11, 10.0.80.12 ]}

compilation:
  workers: 5
  reuse_compilation_vms: true
  az: z1
  vm_type: compilation
  network: default
EOF

bosh update cloud-config ./cloud-config.yml

# build manifest
cat > "./deployment.yml" <<EOF
---
name: bosh-stemcell-smoke-tests
director_uuid: $(bosh status --uuid)

releases:
- name: syslog
  version: "$(cat syslog-release/version)"

stemcells:
- alias: default
  os: ubuntu-trusty
  version: "$(cat stemcell/version)"

update:
  canaries: 1
  max_in_flight: 10
  canary_watch_time: 1000-30000
  update_watch_time: 1000-30000

instance_groups:
- name: syslog_storer
  stemcell: default
  vm_type: default
  instances: 1
  networks:
  - {name: default}
  azs: [z1]
  jobs:
  - name: syslog_storer
    release: syslog
    properties:
      syslog:
        transport: tcp
        port: 514
- name: syslog_forwarder
  stemcell: default
  vm_type: default
  azs: [z1]
  instances: 1
  networks:
  - {name: default}
  jobs:
  - name: syslog_forwarder
    release: syslog
    properties:
      syslog:
        forward_files: true
    consumes:
      syslog_storer: { from: syslog_storer }
EOF

cleanup() {
  bosh delete deployment bosh-stemcell-smoke-tests
  bosh cleanup --all
}

bosh -d ./deployment.yml deploy

# trigger auditd event
bosh -d ./deployment.yml ssh syslog_forwarder 0 'sudo modprobe -r floppy'
bosh -d ./deployment.yml ssh syslog_forwarder 0 'logger -t vcap some vcap message'

# check that syslog drain gets event
download_destination=$(mktemp -d -t)
bosh -d ./deployment.yml scp --download syslog_storer 0 /var/vcap/store/syslog_storer/syslog.log $download_destination

grep 'COMMAND=/sbin/modprobe -r floppy' $download_destination/syslog.log.syslog_storer.0 || ( echo "Syslog did not contain 'audit'!" ; exit 1 )
grep 'some vcap message' $download_destination/syslog.log.syslog_storer.0 || ( echo "Syslog did not contain 'vcap'!" ; exit 1 )


#fill the syslog so it will need rotating and set cron to run logrotate every min
bosh -d ./deployment.yml ssh syslog_forwarder 0 'logger "old syslog content" \
	&& sudo bash -c "dd if=/dev/urandom count=10000 bs=1024 >> /var/log/syslog" \
	&& sudo sed -i "s/0,15,30,45/\*/" /etc/cron.d/logrotate'
# wait for cron to run logrotate
sleep 62
bosh -d ./deployment.yml ssh syslog_forwarder 0 'logger "new syslog content"'
bosh -d ./deployment.yml ssh syslog_forwarder 0 'sudo cp /var/vcap/data/root_log/syslog /tmp/ && sudo chmod 777 /tmp/syslog'

download_destination=$(mktemp -d -t)
#/var/log should be bind mounted to /var/vcap/data/root_log
# download from there to show rsyslogd is running and logging to the bind mounted directory.
bosh -d ./deployment.yml scp --download syslog_forwarder 0 /tmp/syslog $download_destination
grep 'new syslog content' $download_destination/syslog.* || ( echo "logrotate did not rotate syslog and restart rsyslogd successfully" ; exit 1 )
grep -vl 'old syslog content' $download_destination/syslog.* || ( echo "syslog contains content that should have been rotated" ; exit 1 )

# test #134136191 - pam_cracklib.so is missing from the stemcell even though pam is configured
download_destination=$(mktemp -d -t)
bosh -d ./deployment.yml ssh syslog_forwarder 0 'sudo cp /var/log/auth.log /tmp/ && sudo chmod 777 /tmp/auth.log'
bosh -d ./deployment.yml scp --download syslog_forwarder 0 /tmp/auth.log $download_destination
[[ "0" == "$( grep -c "No such file or directory" $download_destination/auth.log.* )" ]] \
  || ( echo 'Expected to not find "No such file or directory" in /var/log/auth.log' ; exit 1 )

# testing log forwarding #133776519
DOWNLOAD_DESTINATION=$(mktemp -d -t)

bosh -d ./deployment.yml ssh syslog_forwarder 0 "logger syslog-forwarder-test-msg"
bosh -d ./deployment.yml scp --download syslog_storer 0 /var/vcap/store/syslog_storer/syslog.log ${DOWNLOAD_DESTINATION}

grep 'syslog-forwarder-test-msg' ${DOWNLOAD_DESTINATION}/syslog.* || ( echo "was not able to get logs from syslog" ; exit 1 )

# testing deep log forwarding #133776519
DOWNLOAD_DESTINATION=$(mktemp -d -t)
LOGPATH=/var/vcap/sys/log/deep/path
LOGFILE=${LOGPATH}/deepfile.log
EXPECTED_VALUE="test-blackbox-message"

cat > "./script.sh" <<EOF
#!/bin/bash
mkdir -p /var/vcap/sys/log/deep/path
touch ${LOGFILE}
sleep 35
echo "${EXPECTED_VALUE}" >> ${LOGFILE}
EOF

bosh -d ./deployment.yml scp --upload syslog_forwarder 0 ./script.sh /tmp/script.sh
bosh -d ./deployment.yml ssh syslog_forwarder 0 "echo c1oudc0w | sudo -S bash /tmp/script.sh"
bosh -d ./deployment.yml scp --download syslog_storer 0 "/var/vcap/store/syslog_storer/syslog.log" $DOWNLOAD_DESTINATION

grep ${EXPECTED_VALUE} ${DOWNLOAD_DESTINATION}/syslog.* || ( echo "was not able to get message forwarded from BlackBox" ; exit 1 )

# testing CEF logs #135979501
DOWNLOAD_DESTINATION=$(mktemp -d -t)
EXPECTED_VALUE="CEF:0|CloudFoundry|BOSH|1|agent_api|get_task"

bosh -d ./deployment.yml vms
bosh -d ./deployment.yml scp --download syslog_storer 0 "/var/vcap/store/syslog_storer/syslog.log" $DOWNLOAD_DESTINATION
grep ${EXPECTED_VALUE} ${DOWNLOAD_DESTINATION}/syslog.* || ( echo "was not able to get CEF logs from syslog" ; exit 1 )

# testing audit logs for use of binaries #137987887
DOWNLOAD_DESTINATION=$(mktemp -d -t)
EXPECTED_VALUE="exe=\"/usr/bin/chage\""

bosh -d ./deployment.yml ssh syslog_forwarder 0 "chage -h"
bosh -d ./deployment.yml scp --download syslog_storer 0 "/var/vcap/store/syslog_storer/syslog.log" $DOWNLOAD_DESTINATION
grep ${EXPECTED_VALUE} ${DOWNLOAD_DESTINATION}/syslog.* || ( echo "was not able to get audit logs for chage usage" ; exit 1 )
