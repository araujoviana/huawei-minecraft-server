resource "huaweicloud_as_configuration" "this" {
  scaling_configuration_name = "${var.name_prefix}-config"

  instance_config {
    flavor             = data.huaweicloud_compute_flavors.this.ids[0]
    image              = data.huaweicloud_images_image.ubuntu.id
    key_name           = var.ssh_key_name
    security_group_ids = [var.security_group_id]

    disk {
      size        = 40
      volume_type = "SSD"
      disk_type   = "SYS"
    }

    user_data = base64encode(templatefile("${path.module}/templates/user_data.sh.tftpl", {
      minecraft_port      = var.minecraft_port
      sfs_export_location = var.sfs_export_location
      eip_id              = huaweicloud_vpc_eip.this.id
      region              = var.region
    }))
  }
}

# min=max=desired=1: this is a "self-healing single instance", not a scaling
# group. health_periodic_audit_method=NOVA_AUDIT means AS checks raw ECS
# status (no load balancer needed) and replaces the instance if it stops or
# is deleted outside Terraform.
resource "huaweicloud_as_group" "this" {
  scaling_group_name       = "${var.name_prefix}-group"
  scaling_configuration_id = huaweicloud_as_configuration.this.id
  vpc_id                   = var.vpc_id

  networks {
    id = var.subnet_id
  }

  security_groups {
    id = var.security_group_id
  }

  availability_zones = [var.availability_zone]

  min_instance_number    = 1
  max_instance_number    = 1
  desire_instance_number = 1

  health_periodic_audit_method       = "NOVA_AUDIT"
  health_periodic_audit_time         = 5
  health_periodic_audit_grace_period = 600

  agency_name     = huaweicloud_identity_agency.this.name
  delete_publicip = false
  delete_volume   = false
}
