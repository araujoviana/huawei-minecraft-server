variable "region" {
  type = string
}

variable "name_prefix" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "security_group_id" {
  type = string
}

variable "availability_zone" {
  type = string
}

variable "minecraft_port" {
  type = number
}

variable "sfs_export_location" {
  description = "NFS export path of the SFS Turbo file system holding world data."
  type        = string
}

variable "ssh_key_name" {
  type = string
}

variable "flavor_cpu" {
  type = number
}

variable "flavor_memory" {
  type = number
}
