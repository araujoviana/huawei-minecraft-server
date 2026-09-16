resource "huaweicloud_kps_keypair" "this" {
  name       = "${var.name_prefix}-key"
  public_key = file(pathexpand(var.ssh_public_key_path))
}

module "network" {
  source = "./modules/network"

  region         = var.region
  name_prefix    = var.name_prefix
  vpc_cidr       = var.vpc_cidr
  subnet_cidr    = var.subnet_cidr
  minecraft_port = var.minecraft_port
  admin_cidr     = var.admin_cidr
}

module "storage" {
  source = "./modules/storage"

  region            = var.region
  name_prefix       = var.name_prefix
  vpc_id            = module.network.vpc_id
  subnet_id         = module.network.subnet_id
  security_group_id = module.network.security_group_id
  availability_zone = module.network.availability_zone
  size_gb           = var.sfs_turbo_size_gb
}

module "compute" {
  source = "./modules/compute"

  region              = var.region
  name_prefix         = var.name_prefix
  vpc_id              = module.network.vpc_id
  subnet_id           = module.network.subnet_id
  security_group_id   = module.network.security_group_id
  availability_zone   = module.network.availability_zone
  minecraft_port      = var.minecraft_port
  sfs_export_location = module.storage.export_location
  ssh_key_name        = huaweicloud_kps_keypair.this.name
  flavor_cpu          = var.flavor_cpu
  flavor_memory       = var.flavor_memory
}

module "backup" {
  source = "./modules/backup"

  name_prefix      = var.name_prefix
  sfs_turbo_id     = module.storage.id
  vault_size_gb    = var.sfs_turbo_size_gb
  daily_retention  = var.cbr_daily_retention
  weekly_retention = var.cbr_weekly_retention
}

module "monitoring" {
  source = "./modules/monitoring"

  name_prefix = var.name_prefix
  alarm_email = var.alarm_email
  as_group_id = module.compute.as_group_id
}

