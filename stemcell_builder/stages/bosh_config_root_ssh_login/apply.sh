#!/usr/bin/env bash
#
# Copyright (c) 2009-2012 VMware, Inc.

set -e

base_dir=$(readlink -nf $(dirname $0)/../..)
source $base_dir/lib/prelude_apply.bash

sed "/^ *PermitRootLogin/d" -i $chroot/etc/ssh/sshd_config
echo 'PermitRootLogin yes' >> $chroot/etc/ssh/sshd_config

echo '    UserKnownHostsFile /dev/null' >>  $chroot/etc/ssh/ssh_config
echo '    StrictHostKeyChecking no' >>  $chroot/etc/ssh/ssh_config
