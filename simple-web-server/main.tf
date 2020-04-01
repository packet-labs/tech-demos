variable "auth_token" {}
variable "project_id" {}
variable "hostname" {default = "web-0"}
variable "size" {default = "t1.small.x86"}
variable "facility" {default = "ewr1"}
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
    name = "web_ssh_key"
    public_key = chomp(tls_private_key.ssh_key_pair.public_key_openssh)
}

resource "packet_device" "server" {
    depends_on = [ packet_ssh_key.ssh_pub_key ]
    hostname         = var.hostname
    plan             = var.size
    facilities       = [var.facility]
    operating_system = var.os
    billing_cycle    = var.billing_cycle
    project_id       = var.project_id
}

data "template_file" "post_install" {
    template = file("templates/post_install.sh")
}

resource "null_resource" "pos_install" {
    connection {
        type = "ssh"
        user = "root"
        private_key = chomp(tls_private_key.ssh_key_pair.private_key_pem)
        host = packet_device.server.access_public_ipv4
    }

    provisioner "file" {
        content = data.template_file.post_install.rendered
        destination = "/root/post_install.sh"
    }

    provisioner "remote-exec" {
        inline = [
            "chmod +x /root/post_install.sh",
            "/root/post_install.sh"
        ]
    }
}

output "IP_Address" {
  value = packet_device.server.access_public_ipv4
}
