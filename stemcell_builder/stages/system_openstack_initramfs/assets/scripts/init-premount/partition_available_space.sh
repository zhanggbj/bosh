#!/bin/sh

# FIXME: repartition with sfdisk, use blkid to apply ephemeral-disk label,
# have agent format and mount it if no ephemeral disk is already present

# FIXME: every utility used here must be in initramfs

# FIXME: uuid can be found in image_install_grub stage, how do I get it here?
# then I can follow it to the root device
device_name=/dev/vda1 # $(df | grep /\$ | awk '{print $1}')
# FIXME: assumes root is on the first partition
drive_name=${device_name%1}

root_partition=$(sfdisk -l -uS $drive_name 2>/dev/null | grep $device_name)
root_partition_start=$(echo $root_partition | awk '{print $2}')
sector_size=$(echo $root_partition | awk '{print $4}')
new_partition_start=$(($sector_size + $root_partition_start))

sfdisk -uS $drive_name <<EOS
$root_partition_start,$sector_size,L
$new_partition_start,,L
EOS
