# auto_create_security_group_rules defaults to "true": Huawei Cloud manages
# the NFS ingress rules on security_group_id automatically, so the network
# module does not need hand-written NFS port rules.
resource "huaweicloud_sfs_turbo" "this" {
  name              = "${var.name_prefix}-world-data"
  size              = var.size_gb
  share_proto       = "NFS"
  vpc_id            = var.vpc_id
  subnet_id         = var.subnet_id
  security_group_id = var.security_group_id
  availability_zone = var.availability_zone
}
