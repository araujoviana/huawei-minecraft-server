variable "region" {
  description = "Huawei Cloud region."
  type        = string
  default     = "la-south-2"
}

variable "name_prefix" {
  description = "Prefix applied to all resource names."
  type        = string
  default     = "mc"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "192.168.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for the subnet."
  type        = string
  default     = "192.168.1.0/24"
}

variable "minecraft_port" {
  description = "TCP port the Minecraft Java server listens on."
  type        = number
  default     = 25565
}

variable "admin_cidr" {
  description = "CIDR allowed to reach the server over SSH (port 22). Required — no default, since opening SSH to 0.0.0.0/0 is not acceptable."
  type        = string
}

variable "ssh_public_key_path" {
  description = "Path to a local SSH public key. Terraform imports it into Huawei Cloud KPS as the instance's keypair — no pre-existing console keypair required."
  type        = string
  default     = "~/.ssh/mc-minecraft.pub"
}

variable "flavor_cpu" {
  description = "vCPU count to look up for the ECS flavor."
  type        = number
  default     = 4
}

variable "flavor_memory" {
  description = "Memory (GB) to look up for the ECS flavor."
  type        = number
  default     = 16
}

variable "sfs_turbo_size_gb" {
  description = "Capacity, in GB, of the SFS Turbo file system holding world data. 500 is the minimum for the STANDARD share type."
  type        = number
  default     = 500
}

variable "cbr_daily_retention" {
  description = "Number of daily CBR backups to retain."
  type        = number
  default     = 7
}

variable "cbr_weekly_retention" {
  description = "Number of weekly CBR backups to retain."
  type        = number
  default     = 4
}

variable "alarm_email" {
  description = "Email address subscribed to SMN for Cloud Eye alarm notifications. Required — no default."
  type        = string
}
