data "huaweicloud_availability_zones" "this" {
  region = var.region
}

resource "huaweicloud_vpc" "this" {
  name = "${var.name_prefix}-vpc"
  cidr = var.vpc_cidr
}

resource "huaweicloud_vpc_subnet" "this" {
  name              = "${var.name_prefix}-subnet"
  cidr              = var.subnet_cidr
  gateway_ip        = cidrhost(var.subnet_cidr, 1)
  vpc_id            = huaweicloud_vpc.this.id
  availability_zone = data.huaweicloud_availability_zones.this.names[0]
}

resource "huaweicloud_networking_secgroup" "this" {
  name        = "${var.name_prefix}-secgroup"
  description = "Minecraft server: game port open to the internet, SSH restricted to admin_cidr."
}

resource "huaweicloud_networking_secgroup_rule" "minecraft" {
  security_group_id = huaweicloud_networking_secgroup.this.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = var.minecraft_port
  port_range_max    = var.minecraft_port
  remote_ip_prefix  = "0.0.0.0/0"
  description       = "Minecraft Java game port"
}

resource "huaweicloud_networking_secgroup_rule" "ssh" {
  security_group_id = huaweicloud_networking_secgroup.this.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = var.admin_cidr
  description       = "SSH, restricted to admin_cidr"
}
