#!/usr/bin/env bash

set -e

base_dir=$(readlink -nf $(dirname $0)/../..)
source $base_dir/lib/prelude_apply.bash
source $base_dir/lib/prelude_bosh.bash
source $base_dir/etc/settings.bash

# Set up users/groups
vcap_user_groups='admin,adm,audio,cdrom,dialout,floppy,video,dip'

if [ -f $chroot/etc/debian_version ] # Ubuntu
then
  vcap_user_groups+=",plugdev"
fi

run_in_chroot $chroot "
useradd -m --comment 'Doctor Sytem User' doctor --uid 1001
useradd -m --comment 'Monitor System User' monitor --uid 1002
chmod 755 ~monitor
chmod 755 ~doctor
echo \"monitor:${bosh_users_password}\" | chpasswd
echo \"doctor:${bosh_users_password}\" | chpasswd
usermod -G ${vcap_user_groups} monitor
usermod -G ${vcap_user_groups} doctor
usermod -s /bin/bash monitor
usermod -s /bin/bash doctor
chage -E -1 -M -1 root
chage -E -1 -M -1 vcap
chage -E -1 -M -1 doctor
chage -E -1 -M -1 monitor
"

# Add pub key to monitor and doctor
mkdir -p $chroot/home/monitor/.ssh
mkdir -p $chroot/home/doctor/.ssh
cp -a $assets_dir/authorized_keys_monitor $chroot/home/monitor/.ssh/authorized_keys
cp -a $assets_dir/authorized_keys_doctor $chroot/home/doctor/.ssh/authorized_keys
run_in_chroot $chroot "
chown -R monitor:monitor /home/monitor/.ssh
chown -R doctor:doctor /home/doctor/.ssh
chmod 0755 /home/monitor/.ssh
chmod 0755 /home/doctor/.ssh
chmod 0600 /home/monitor/.ssh/authorized_keys
chmod 0600 /home/doctor/.ssh/authorized_keys
"

# Add $bosh_dir/bin to $PATH
echo "export PATH=$bosh_dir/bin:\$PATH" >> $chroot/home/monitor/.bashrc
echo "export PATH=$bosh_dir/bin:\$PATH" >> $chroot/home/doctor/.bashrc
