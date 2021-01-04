#!/bin/sh

# Get command line arguements
while [ "$1" != "" ]; do
  case $1 in
    -e | --satellite_enabled )
    SATELLITE_ENABLED=$2
    shift
    shift
    ;;
  esac
done

RHMAJVER=`cat /etc/redhat-release | sed 's/[^0-9.]*\([0-9.]\).*/\1/'`

# remove old kernels
echo 'Cleaning up old Kernals'
if [[ "$RHMAJVER" = '8' ]]; then
  # note: you MUST be on the latest active kernel, that is why the Packer provisioner
  #       has a reboot step in there, if you try to do this without being booted
  #       on the latest active kernel, it will throw an error
  dnf remove -y --oldinstallonly --setopt installonly_limit=1 kernel
elif [[ "$RHMAJVER" = '6' ||  "$RHMAJVER" = '7' ]]; then
  yum -y install yum-utils
  package-cleanup -y --oldkernels --count=1
fi

# cleanup yum cache
yum clean all

# unregister from satellite
echo "Satellite enabled = ${SATELLITE_ENABLED}"
if [[ "$SATELLITE_ENABLED" = 'True' ]]; then
  echo 'Cleaning yum repos and unregistering from satellite'
  subscription-manager unregister
  subscription-manager clean
  yum -y erase katello-ca-consumer*
fi

rm -rf /var/cache/yum/*

# cleanup SSH keys for host and root user
echo 'Cleaning ssh keys'
rm -rf /etc/ssh/ssh_host_*
rm -rf /root/.ssh/

# cleanup network configs
echo 'Cleaning network configs'
if [[ "$RHMAJVER" = '6' ]]; then
  hostname "localhost.localdomain"
  sed -i 's/HOSTNAME=.*/HOSTNAME=localhost.localdomain/g' /etc/sysconfig/network
else
  hostnamectl set-hostname "localhost.localdomain"
  echo "localhost.localdomain" > /etc/hostname
fi

find /etc/sysconfig/network-scripts -name "ifcfg-e*" | xargs sed -E -i '/^(HWADDR|UUID)=.*/d'
echo "" > /etc/resolv.conf
rm -rf /etc/udev/rules.d/70-*

# clean logs
echo 'Cleaning history data'
rm -rf /root/.bash_history
unset HISTFILE
history -c
