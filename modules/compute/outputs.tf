output "agency_name" {
  value = huaweicloud_identity_agency.this.name
}

output "eip_id" {
  value = huaweicloud_vpc_eip.this.id
}

output "eip_address" {
  value = huaweicloud_vpc_eip.this.address
}

output "as_group_id" {
  value = huaweicloud_as_group.this.id
}
