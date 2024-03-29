
variable "cpu" {
  type    = string
  default = "2"
}

variable "disk_size" {
  type    = string
  default = "32768"
}

variable "disk_format" {
  # either "qcow2" or "raw"
  type    = string
  default = "qcow2"
}

variable "headless" {
  type    = bool
  default = true
}

variable "iso_checksum" {
  type    = string
  default = "0394ecfa994db75efc1413207d2e5ac67af4f6685b3b896e2837c682221fd6b2"
}

variable "iso_checksum_type" {
  type    = string
  default = "sha256"
}

variable "iso_urls" {
  type    = list(string)
  default = ["http://mirrors.rit.edu/centos/8/isos/x86_64/CentOS-8.4.2105-x86_64-dvd1.iso"]
}

variable "kickstart_file" {
  type    = string
  default = "centos-8-kickstart.cfg"
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

source "qemu" "centos-8-template" {
  accelerator      = "kvm"
  boot_command     = ["<up><wait><tab><wait> net.ifnames=0 biosdevname=0 text ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/${var.kickstart_file}<enter><wait>"]
  boot_wait        = "40s"
  disk_cache       = "none"
  disk_compression = true
  disk_discard     = "unmap"
  disk_interface   = "virtio"
  disk_size        = var.disk_size
  format           = "${var.disk_format}"
  headless         = var.headless
  http_directory   = "centos-8/http"
  iso_checksum     = "${var.iso_checksum_type}:${var.iso_checksum}"
  iso_urls         = var.iso_urls
  net_device       = "virtio-net"
  output_directory = "packer-{{build_name}}"
  qemu_binary      = "/usr/libexec/qemu-kvm"
  qemuargs         = [["-m", "${var.ram}M"], ["-smp", "${var.cpu}"]]
  shutdown_command = "sudo /usr/sbin/shutdown -h now"
  ssh_password     = var.ssh_password
  ssh_timeout      = "30m"
  ssh_username     = var.ssh_username
  vm_name          = "packer-{{build_name}}.${var.disk_format}"
}

build {
  sources = ["source.qemu.centos-8-template"]

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
    inline            = ["mkdir /opt/tmp && chmod 1777 /opt/tmp"]
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
    # don't delete the qcow2/img image
    keep_input_artifact = true
  }
}
