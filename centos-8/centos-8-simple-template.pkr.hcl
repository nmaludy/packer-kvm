
variable "cpu" {
  type    = string
  default = "1"
}

variable "disk_size" {
  type    = string
  default = "4096"
}

variable "headless" {
  type    = string
  default = "true"
}

variable "iso_checksum" {
  type    = string
  default = "aaf9d4b3071c16dbbda01dfe06085e5d0fdac76df323e3bbe87cce4318052247"
}

variable "iso_checksum_type" {
  type    = string
  default = "sha256"
}

variable "iso_urls" {
  type    = string
  default = "http://mirrors.rit.edu/centos/8/isos/x86_64/CentOS-8.3.2011-x86_64-dvd1.iso"
}

variable "kickstart_file" {
  type    = string
  default = "centos-8-simple-kickstart.cfg"
}

variable "ram" {
  type    = string
  default = "1024"
}

variable "ssh_password" {
  type    = string
  default = "Packer"
}

variable "ssh_username" {
  type    = string
  default = "root"
}

variable "vm_os_name" {
  type    = string
  default = "centos"
}

variable "vm_os_version" {
  type    = string
  default = "8"
}

# could not parse template for following block: "template: hcl2_upgrade:2: bad character U+0060 '`'"

source "qemu" "{{user_`vm_os_name`}}-{{user_`vm_os_version`}}-simple-template" {
  accelerator      = "kvm"
  boot_command     = ["<up><wait><tab><wait> net.ifnames=0 biosdevname=0 text ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/{{user `kickstart_file`}}<enter><wait>"]
  boot_wait        = "40s"
  disk_cache       = "none"
  disk_compression = true
  disk_discard     = "unmap"
  disk_interface   = "virtio"
  disk_size        = "{{user `disk_size`}}"
  format           = "qcow2"
  headless         = "{{user `headless`}}"
  http_directory   = "centos-8/http"
  iso_checksum     = "{{user `iso_checksum_type`}}:{{user `iso_checksum`}}"
  iso_urls         = "{{user `iso_urls`}}"
  net_device       = "virtio-net"
  output_directory = "packer-{{ build_name }}"
  qemu_binary      = "/usr/libexec/qemu-kvm"
  qemuargs         = [["-m", "{{user `ram`}}M"], ["-smp", "{{user `cpu`}}"]]
  shutdown_command = "sudo /usr/sbin/shutdown -h now"
  ssh_password     = "{{user `ssh_password`}}"
  ssh_timeout      = "30m"
  ssh_username     = "{{user `ssh_username`}}"
  vm_name          = "packer-{{ build_name }}.qcow2"
}

build {
  sources = ["source.qemu.{{user_`vm_os_name`}}-{{user_`vm_os_version`}}-simple-template"]

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
    execute_command = "\"{{ .Path }}\""
    remote_folder   = "/opt/tmp"
    script          = "${path.root}/../scripts/rhel_cleanup.sh"
  }

}
