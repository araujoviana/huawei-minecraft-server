# Remote state in an OBS bucket via Terraform's S3-compatible backend.
# OBS's S3-compatible API has no native state locking. Acceptable for a
# single-operator project; a team setting would need an external locking
# mechanism (e.g. Terraform Cloud) on top of this.
#
# Backend blocks cannot reference variables, so fill these in by hand
# after running the bootstrap config in ../bootstrap:
#   1. cd bootstrap && terraform apply -var="bucket_name=<your-unique-name>"
#   2. Copy the "state_bucket_name" output into `bucket` below.
#   3. Run `terraform init` here.
terraform {
  backend "s3" {
    bucket = "mc-minecraft-tfstate-dfe901"
    key    = "minecraft-server/terraform.tfstate"
    region = "la-south-2"

    endpoints = {
      s3 = "https://obs.la-south-2.myhuaweicloud.com"
    }

    skip_region_validation      = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
  }
}
