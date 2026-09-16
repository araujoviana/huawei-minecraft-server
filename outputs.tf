output "ssh_command" {
  description = "SSH command to reach the instance, using the auto-imported keypair."
  value       = "ssh -i ${trimsuffix(var.ssh_public_key_path, ".pub")} ubuntu@${module.compute.eip_address}"
}

output "minecraft_server_address" {
  description = "Public IP players connect to."
  value       = module.compute.eip_address
}

output "minecraft_server_port" {
  description = "TCP port players connect to."
  value       = var.minecraft_port
}

output "sfs_export_location" {
  description = "NFS export path backing the Minecraft world data."
  value       = module.storage.export_location
}

output "cbr_vault_id" {
  description = "CBR vault ID holding scheduled world-data backups."
  value       = module.backup.vault_id
}

output "alarm_topic_urn" {
  description = "SMN topic URN alarms notify."
  value       = module.monitoring.topic_urn
}
