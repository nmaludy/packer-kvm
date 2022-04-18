#!/bin/sh

# In netboot/diskless land, during boot up with FIPS enabled it looks for /boot/.vmlinuz-xxx.x86_64.hmac
# along with some other files. If it can't find these files, the boot fails.
# Unfortunately these files live in the /boot partition on normal hard drives.
# In a normal hard drive setup /boot would be on its own partition and would be mounted
# by the boot loader.
# During netboot the /boot information is hosted on a remote machine and parameters
# are passed in with kernel+dracut options and the only option we have for mounting
# partitions locally is to mount the root partition and the path to it.
# Therefore the root partition needs to contain the /boot files so that the kernel+dracut
# can find the appropriate files, specifically ones needed by FIPS, to boot up
# properly into the OS.
#
# This is unique to netboot/diskless setup, so should only be run for those images.

set -e # stop on error
set -x # print all of the commands below

# find /boot partition
BOOT_PARTITION=$(mount | grep ' /boot ' | awk '{print $1}')

# unmount it and mount in new location
umount $BOOT_PARTITION
# mount our original /boot partition in /mnt
mount $BOOT_PARTITION /mnt

# make /boot on / partition
mkdir -p /boot

# copy /boot partition contents to / partition /boot directory
cp -rp /mnt/* /boot/
