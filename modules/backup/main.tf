resource "huaweicloud_cbr_policy" "this" {
  name            = "${var.name_prefix}-backup-policy"
  type            = "backup"
  time_zone       = "UTC+00:00"
  backup_quantity = var.daily_retention + var.weekly_retention

  backup_cycle {
    interval        = 1
    execution_times = ["02:00"]
  }

  long_term_retention {
    daily                = var.daily_retention
    weekly               = var.weekly_retention
    monthly              = 0
    yearly               = 0
    full_backup_interval = -1
  }
}

resource "huaweicloud_cbr_vault" "this" {
  name            = "${var.name_prefix}-backup-vault"
  type            = "turbo"
  protection_type = "backup"
  size            = var.vault_size_gb

  resources {
    includes = [var.sfs_turbo_id]
  }

  policy {
    id = huaweicloud_cbr_policy.this.id
  }
}
