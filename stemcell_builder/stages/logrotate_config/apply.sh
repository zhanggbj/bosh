#!/usr/bin/env bash

set -e

base_dir=$(readlink -nf $(dirname $0)/../..)
source $base_dir/lib/prelude_apply.bash

# Make logrotate run hourly, not daily
mv $chroot/etc/cron.daily/logrotate $chroot/etc/cron.hourly/logrotate

# Disable dateext config property
sed -i 's/dateext/# dateext (this was commented by bosh)/g' $chroot/etc/logrotate.conf
