variable "region" {
  description = "Huawei Cloud region for the Terraform state bucket."
  type        = string
  default     = "la-south-2"
}

variable "bucket_name" {
  description = "Globally-unique OBS bucket name to hold Terraform state. OBS bucket names must be lowercase, 3-63 characters, and unique within the region."
  type        = string
}
