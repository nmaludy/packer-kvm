#!/bin/sh
#
# Setup box to be used with Vagrant
# https://www.vagrantup.com/docs/boxes/base
#
# - Adds a user 'vagrant'
# - Sets up the 'vagrant' user with passwordless sudo
# - Sets up the "insecure vagrant SSH key", so vagrant tool can ssh in and replace it

if [[ "${VAGRANT_SETUP}" != "true" ]]; then
  echo "VAGRANT_SETUP is not true '${VAGRANT_SETUP}', skipping"
  exit 0
fi

# add vagrant user
useradd vagrant

# setup passwordless sudo
echo 'vagrant ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/vagrant

# install rsync for vagrant-rsync-auto
yum -y install rsync

# setup insecure vagrant key
mkdir -p /home/vagrant/.ssh
chmod 0700 /home/vagrant/.ssh
curl https://raw.githubusercontent.com/hashicorp/vagrant/main/keys/vagrant.pub -o /home/vagrant/.ssh/authorized_keys
chmod 0600 /home/vagrant/.ssh/authorized_keys
chown -R vagrant: /home/vagrant/.ssh
