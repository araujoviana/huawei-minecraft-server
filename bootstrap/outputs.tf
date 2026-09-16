output "state_bucket_name" {
  description = "OBS bucket name to reference in the root module's backend.tf."
  value       = huaweicloud_obs_bucket.state.bucket
}
