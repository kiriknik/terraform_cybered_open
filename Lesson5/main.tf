terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  zone = "ru-central1-a"
}

resource "yandex_compute_disk" "boot-disk-1" {
  name     = "boot-disk-1"
  type     = "network-hdd"
  zone     = "ru-central1-a"
  size     = "20"
  image_id = "fd83j4siasgfq4pi1qif"
}
resource "yandex_compute_disk" "boot-disk-2" {
  name     = "boot-disk-2"
  type     = "network-hdd"
  zone     = "ru-central1-a"
  size     = "20"
  image_id = "fd83j4siasgfq4pi1qif"
}

resource "yandex_compute_instance" "vm-1" {
  name = "hacker"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    disk_id = yandex_compute_disk.boot-disk-1.id
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat       = true
  }

  scheduling_policy {
    preemptible = true
  }

  metadata = {
    user-data = "${file("meta.txt")}"
  }
}
resource "yandex_compute_instance" "vm-2" {
  name = "victim"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    disk_id = yandex_compute_disk.boot-disk-2.id
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat       = true
  }

  scheduling_policy {
    preemptible = true
  }

  metadata = {
    user-data = "${file("meta.txt")}"
  }
}

resource "yandex_vpc_network" "network-1" {
  name = "network1"
}

resource "yandex_vpc_subnet" "subnet-1" {
  name           = "subnet1"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}





output "internal_ip_address_vm_1" {
  value = yandex_compute_instance.vm-1.network_interface.0.ip_address
}

output "internal_ip_address_vm_2" {
  value = yandex_compute_instance.vm-2.network_interface.0.ip_address
}


output "external_ip_address_vm_1" {
  value = yandex_compute_instance.vm-1.network_interface.0.nat_ip_address
}

output "external_ip_address_vm_2" {
  value = yandex_compute_instance.vm-2.network_interface.0.nat_ip_address
}


resource "local_file" "hosts" {
  content  = "[all]\nhacker ansible_host=${yandex_compute_instance.vm-1.network_interface.0.nat_ip_address} ansible_user=debian\nvictim ansible_host=${yandex_compute_instance.vm-2.network_interface.0.nat_ip_address} ansible_user=debian"
  filename = "ansible/hosts"
}


resource "null_resource" "hacker" {
  connection {
    type = "ssh"
    user = "debian"
    #password = var.root_password
    host = yandex_compute_instance.vm-2.network_interface.0.nat_ip_address
    private_key = "${file("/home/kirill/project/2024/terraform_cybered/terraform/terraform_yc_key")}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo apt -y install nmap curl build-essential linux-headers-amd64 linux-image-amd64 git",
      "echo 127.0.0.1 hacker | sudo tee -a /etc/cloud/templates/hosts.debian.tmpl",
      "echo 127.0.0.1 hacker | sudo tee -a /etc/hosts",
      "sudo hostname hacker",
      "sudo hostnamectl set-hostname hacker",
      "rm -rf secinfo-docker",
      "git clone https://github.com/bykvaadm/secinfo-docker"
    ]
  }
}

resource "null_resource" "victim" {
  connection {
    type = "ssh"
    user = "debian"
    #password = var.root_password
    host = yandex_compute_instance.vm-2.network_interface.0.nat_ip_address
    private_key = "${file("/home/kirill/project/2024/terraform_cybered/terraform/terraform_yc_key")}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo apt -y install ca-certificates curl git linux-headers-amd64 linux-image-amd64",
      "sudo install -m 0755 -d /etc/apt/keyrings",
      "sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc",
      "sudo chmod a+r /etc/apt/keyrings/docker.asc",
      "echo deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian   bookworm stable | sudo tee /etc/apt/sources.list.d/docker.list",
      "sudo apt update",
      "sudo apt -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin",
      "echo 127.0.0.1 victim | sudo tee -a /etc/cloud/templates/hosts.debian.tmpl",
      "echo 127.0.0.1 victim | sudo tee -a /etc/hosts",
      "sudo hostname victim",
      "sudo hostnamectl set-hostname victim",
      "rm -rf secinfo-docker",
      "git clone https://github.com/bykvaadm/secinfo-docker"
    ]
  }
}