#!/usr/bin/env bash

set -e

base_dir=$(readlink -nf $(dirname $0)/../..)
source $base_dir/lib/prelude_apply.bash

# FIXME: how should this work on CentOS?
# * sfdisk
# * initramfs

cp $assets_dir/hooks/* $chroot/etc/initramfs-tools/hooks/
cp -R $assets_dir/scripts/* $chroot/etc/initramfs-tools/scripts/

chmod +x $chroot/etc/initramfs-tools/hooks/*
chmod +x $chroot/etc/initramfs-tools/scripts/*/*

run_in_chroot "update-initramfs -u -v"
