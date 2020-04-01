variable "auth_token" {}
variable "project_id" {}
variable "hostname" {default = "os-controller-verizon"}
variable "size" {default = "m2.xlarge.x86"}
variable "facility" {default = "sjc1"}
variable "os" {default = "centos_7"}
variable "billing_cycle" {default = "hourly"}

provider "packet" {
    auth_token = var.auth_token
}

resource "tls_private_key" "ssh_key_pair" {
    algorithm = "RSA"
    rsa_bits = 4096
}

resource "packet_ssh_key" "ssh_pub_key" {
    name = "openstack_ssh_key"
    public_key = chomp(tls_private_key.ssh_key_pair.public_key_openssh)
}

resource "packet_reserved_ip_block" "os_ip_blocks" {
    project_id = var.project_id
    facility = var.facility
    quantity = 16
}

resource "packet_device" "os_controller" {
    depends_on = [ packet_ssh_key.ssh_pub_key ]
    hostname         = var.hostname
    plan             = var.size
    facilities       = [var.facility]
    operating_system = var.os
    billing_cycle    = var.billing_cycle
    project_id       = var.project_id
}

resource "packet_ip_attachment" "block_assignment" {
    device_id = packet_device.os_controller.id
    cidr_notation = packet_reserved_ip_block.os_ip_blocks.cidr_notation
}


data "template_file" "install_packstack" {
    template = file("templates/install_packstack.sh")
    vars = {
        public_cidr = packet_reserved_ip_block.os_ip_blocks.cidr_notation
        first_ip = cidrhost(packet_reserved_ip_block.os_ip_blocks.cidr_notation, 1)
        prefix_length = packet_reserved_ip_block.os_ip_blocks.cidr
    }
}

resource "null_resource" "install_packstack" {
    connection {
        type = "ssh"
        user = "root"
        private_key = chomp(tls_private_key.ssh_key_pair.private_key_pem)
        host = packet_device.os_controller.access_public_ipv4
    }

    provisioner "file" {
        content = data.template_file.install_packstack.rendered
        destination = "/root/install_packstack.sh"
    }

    provisioner "remote-exec" {
        inline = [
            "chmod +x /root/install_packstack.sh",
            "/root/install_packstack.sh"
        ]
    }
}
