# Pre-allocated once, outside the AS group's own lifecycle, so it survives
# instance replacement. The instance re-associates this EIP with itself at
# boot rather than the AS configuration creating a fresh EIP per instance.
resource "huaweicloud_vpc_eip" "this" {
  name = "${var.name_prefix}-eip"

  publicip {
    type = "5_bgp"
  }

  bandwidth {
    share_type  = "PER"
    name        = "${var.name_prefix}-bandwidth"
    size        = 10
    charge_mode = "traffic"
  }
}
