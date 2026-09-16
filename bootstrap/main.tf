resource "huaweicloud_obs_bucket" "state" {
  bucket     = var.bucket_name
  acl        = "private"
  versioning = true
}
