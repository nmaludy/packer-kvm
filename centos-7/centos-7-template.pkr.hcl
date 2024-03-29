
variable "cpu" {
  type    = string
  default = "2"
}

variable "disk_format" {
  type    = string
  default = "qcow2"
}

variable "disk_size" {
  type    = string
  default = "32768"
}

variable "headless" {
  type    = bool
  default = true
}

variable "iso_checksum" {
  type    = string
  default = "e33d7b1ea7a9e2f38c8f693215dd85254c3a4fe446f93f563279715b68d07987"
}

variable "iso_checksum_type" {
  type    = string
  default = "sha256"
}

variable "iso_urls" {
  type    = list(string)
  default = ["http://mirrors.rit.edu/centos/7/isos/x86_64/CentOS-7-x86_64-DVD-2009.iso"]
}

variable "http_directory" {
  type    = string
  default = "centos-7/http"
}

variable "kickstart_file" {
  type    = string
  default = "centos-7-kickstart.cfg"
}

variable "output_directory" {
  type    = string
  default = "packer-{{build_name}}"
}

variable "ram" {
  type    = string
  default = "2048"
}

variable "ssh_password" {
  type    = string
  default = "Packer"
}

variable "ssh_username" {
  type    = string
  default = "root"
}

variable "vagrant_setup" {
  type    = bool
  default = true
}

variable "vm_name" {
  type    = string
  default = "packer-{{build_name}}"
}

source "qemu" "centos-7-template" {
  accelerator      = "kvm"
  boot_command     = ["<up><wait><tab><wait> net.ifnames=0 biosdevname=0 text ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/${var.kickstart_file} inst.repo=cdrom<enter><wait>"]
  boot_wait        = "40s"
  disk_cache       = "none"
  disk_compression = true
  disk_discard     = "unmap"
  disk_interface   = "virtio"
  disk_size        = var.disk_size
  format           = var.disk_format
  headless         = var.headless
  http_directory   = var.http_directory
  iso_checksum     = "${var.iso_checksum_type}:${var.iso_checksum}"
  iso_urls         = var.iso_urls
  net_device       = "virtio-net"
  output_directory = var.output_directory
  qemu_binary      = "/usr/libexec/qemu-kvm"
  qemuargs         = [["-m", "${var.ram}M"], ["-smp", "${var.cpu}"]]
  shutdown_command = "sudo /usr/sbin/shutdown -h now"
  ssh_password     = var.ssh_password
  ssh_timeout      = "30m"
  ssh_username     = var.ssh_username
  vm_name          = "${var.vm_name}.${var.disk_format}"
}

build {
  name = "netboot"
  sources = ["source.qemu.centos-7-template"]

  # TODO add in /boot moving magic

  provisioner "shell" {
    script        = "${path.root}/../scripts/copy_boot_to_root.sh"
    remote_folder = "/root"
  }

  provisioner "shell" {
    inline        = ["mkdir -p /opt/tmp && chmod 1777 /opt/tmp"]
    remote_folder = "/root"
  }

  provisioner "shell" {
    script        = "${path.root}/../scripts/rhel_cleanup.sh"
    remote_folder = "/opt/tmp"
  }
}

build {
  name = "vagrant"
  sources = ["source.qemu.centos-7-template"]

  provisioner "shell" {
    inline        = ["yum -y upgrade"]
    remote_folder = "/root"
  }

  provisioner "shell" {
    expect_disconnect = true
    inline            = ["systemctl reboot"]
    remote_folder     = "/root"
  }

  provisioner "shell" {
    expect_disconnect = true
    inline            = ["mkdir -p /opt/tmp && chmod 1777 /opt/tmp"]
    remote_folder     = "/root"
  }

  provisioner "shell" {
    # execute_command = "\"{{ .Path }}\""
    remote_folder   = "/opt/tmp"
    script          = "${path.root}/../scripts/vagrant_setup.sh"
    environment_vars = [
      "VAGRANT_SETUP=${var.vagrant_setup}"
    ]
  }

  provisioner "shell" {
    # execute_command = "\"{{ .Path }}\""
    remote_folder   = "/opt/tmp"
    script          = "${path.root}/../scripts/rhel_cleanup.sh"
  }

  # build a Vagrant box too
  post-processor "vagrant" {
    # don't delete the image
    keep_input_artifact = true
  }
}
