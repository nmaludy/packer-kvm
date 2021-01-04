# Packer for KVM/libvirt

Builds KVM (qcow2) images

Concepts initially borrowed from:
https://github.com/stardata/packer-centos7-kvm-example
https://github.com/goffinet/packer-kvm


## Setup

Install packer https://learn.hashicorp.com/tutorials/packer/getting-started-install
```shell
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
sudo yum -y install packer
```

System-level packages for libvirt/kvm/quemu

```
sudo yum -y install epel-release
sudo yum -y install libvirt libguestfs-tools qemu-kvm qemu-system-x86  virt-install virt-manager virt-viewer 
```


## Build directory structure

Each build is contained in its own sub-directory. All files for the build live in 
that directory.

For CentOS/RHEL builds the directory structure looks like:

```shell
centos-X/http/centos-X-kickstart.cfg  # RHEL Kickstart file
centos-X/centos-X-template.json   # packer template file, describes how to build the VM template
```

## Building

Prior to building, you may want to edit the template file and adjust any `variables`
that are necessary to tweak.


This will download the ISO needed to build the template (packer caches these ISOs).
If you would like to use a local ISO, you can download the ISO yourself and tweak the 
`iso_urls` variable in the format: `file:///path/to/my.iso`, see the 
[QEMU builder docs](https://www.packer.io/docs/builders/qemu#iso-configuration)

```
packer build ./centos-8/centos-8-template.json
```

The output will be written to:
```
packer-centos-8-template/packer-centos-8-template.img
```

If you would like this image available to the system, simply copy it into the standard image path:

```
sudo cp packer-centos-8-template/packer-centos-8-template.img /var/lib/libvirt/images
```

The reason we don't default to putting images into `/var/lib/libvirt/images` is that Packer would
need to be run as root. This is possible and easy to configure using the `output_directory` 
option in the template file.
