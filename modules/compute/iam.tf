# Cloud-service agency: delegated_domain_name = "op_svc_ecs" is Huawei Cloud's
# reserved pseudo-account for "let ECS instances assume this agency", not a
# real customer domain. The instance calls the metadata securitykey endpoint
# at boot to get temporary AK/SK/security-token credentials scoped to this
# agency (see scripts/user_data.sh.tftpl in Task 6).
#
# Scoped to "VPC Administrator" because Huawei Cloud has no narrower,
# EIP-only system role — EIP permissions live inside the VPC permission set.
resource "huaweicloud_identity_agency" "this" {
  name                  = "${var.name_prefix}-ecs-eip-agency"
  description           = "Lets the Minecraft ECS instance re-associate its static EIP after Auto Scaling replaces it."
  delegated_domain_name = "op_svc_ecs"

  project_role {
    project = var.region
    roles   = ["VPC Administrator"]
  }
}
