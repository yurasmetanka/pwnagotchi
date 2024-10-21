packer {
  required_plugins {
    ansible = {
      source  = "github.com/hashicorp/ansible"
      version = ">= 1.1.1"
    }
  }
}

variable "pwn_hostname" {
  type = string
}

variable "pwn_version" {
  type = string
}

variable "images_root" {
  type = string
  description = "Path to disk image directory"
  default = "../../../images"
}

source "arm-image" "bpim4-pwnagotchi" {
  image_type      = "armbian"
  image_arch      = "arm64"
  // iso_url         = "https://mirrors.dotsrc.org/armbian-dl/bananapim4zero/archive/Armbian_24.8.1_Bananapim4zero_bookworm_current_6.6.44.img.xz"
  // iso_url         = "https://dl.armbian.com/nightly/bananapim4zero/Bookworm_current_gnome-backported-mesa"
  iso_url         = "file:${abspath(var.images_root)}/Armbian-unofficial_24.11.0-trunk.303_Bananapim4zero_bookworm_current_6.6.54.img.xz"
  iso_checksum    = "none"
  output_filename = "../../../pwnagotchi-bpim4.img"
  // qemu_binary     = "qemu-aarch64-static"
  qemu_args       = ["-r", "6.6.54"]
  target_image_size = 19969908736
  resolv-conf     = "delete"
}

build {
  name = "Banana Pi M4 Zero Pwnagotchi"
  sources = ["source.arm-image.bpim4-pwnagotchi"]

  provisioner "shell" {
    inline = [
      "echo 'nameserver 8.8.8.8' | sudo tee -a /etc/resolv.conf > /dev/null",
      "echo 'nameserver 8.8.4.4' | sudo tee -a /etc/resolv.conf > /dev/null",
    ]
  }

  provisioner "file" {
    destination = "/usr/bin/"
    sources     = [
      "data/64bit/usr/bin/bettercap-launcher",
      // "data/64bit/usr/bin/decryption-webserver",
      "data/64bit/usr/bin/fix_pwny_ethernet.sh",
      "data/64bit/usr/bin/hdmioff",
      "data/64bit/usr/bin/hdmion",
      "data/64bit/usr/bin/monstart",
      "data/64bit/usr/bin/monstop",
      "data/64bit/usr/bin/pwnagotchi-launcher",
      "data/64bit/usr/bin/pwnlib",
    ]
  }
  provisioner "shell" {
    inline = ["chmod +x /usr/bin/*"]
  }
  provisioner "shell" {
    inline = ["mkdir -p /usr/local/src/pwnagotchi"]
  }
  provisioner "file" {
    destination = "/usr/local/src/pwnagotchi/"
    source = "../"
  }
  provisioner "file" {
    destination = "/etc/"
    sources     = [
      "data/64bit/etc/rc.local",
      // "data/64bit/etc/dphys-swapfile",
      // "data/64bit/etc/bash_completion.d/",
      "data/64bit/etc/network/",
    ]
  }
  provisioner "file" {
    destination = "/etc/systemd/system/"
    sources     = [
      "data/64bit/etc/systemd/system/bettercap.service",
      "data/64bit/etc/systemd/system/pwnagotchi.service",
      "data/64bit/etc/systemd/system/pwngrid-peer.service",
    ]
  }
  provisioner "file" {
    destination = "/etc/update-motd.d/01-motd"
    source      = "data/64bit/etc/update-motd.d/01-motd"
  }
  provisioner "shell" {
    inline = ["chmod +x /etc/update-motd.d/*"]
  }
  provisioner "shell" {
    inline = ["apt-get -y --allow-releaseinfo-change update", "apt-get -y dist-upgrade", "apt-get install -y --no-install-recommends ansible"]
  }
  provisioner "ansible-local" {
    command         = "ANSIBLE_FORCE_COLOR=1 PYTHONUNBUFFERED=1 PWN_VERSION=${var.pwn_version} PWN_HOSTNAME=${var.pwn_hostname} ansible-playbook"
    extra_arguments = ["--extra-vars \"ansible_python_interpreter=/usr/bin/python3\""]
    playbook_file   = "bpim4.yml"
  }
}
