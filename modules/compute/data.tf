data "huaweicloud_images_image" "ubuntu" {
  name_regex   = "^Ubuntu 22.04 server 64bit"
  visibility   = "public"
  architecture = "x86"
  most_recent  = true
}

data "huaweicloud_compute_flavors" "this" {
  availability_zone = var.availability_zone
  performance_type  = "normal"
  cpu_core_count    = var.flavor_cpu
  memory_size       = var.flavor_memory
}
