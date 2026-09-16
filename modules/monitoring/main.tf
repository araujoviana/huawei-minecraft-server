resource "huaweicloud_smn_topic" "alerts" {
  name         = "${var.name_prefix}-alerts"
  display_name = "Minecraft server alerts"
}

resource "huaweicloud_smn_subscription" "email" {
  topic_urn = huaweicloud_smn_topic.alerts.id
  endpoint  = var.alarm_email
  protocol  = "email"
  remark    = "Minecraft server operational alerts"
}

# SYS.AS namespace metrics are AS-group aggregates. Quirk in Huawei's own
# API: the dimension key is literally "instance_id" but its value is the AS
# GROUP id, not an ECS instance id (confirmed against the AS monitoring
# metrics doc) — this is what makes the alarm resolvable at plan time even
# though the ASG's actual ECS instance ID is only known at runtime.
resource "huaweicloud_ces_alarmrule" "cpu_high" {
  alarm_name        = "${var.name_prefix}-as-cpu-high"
  alarm_description = "AS group average CPU exceeded 80% for 5 minutes."

  metric {
    namespace = "SYS.AS"
  }

  resources {
    dimensions {
      name  = "instance_id"
      value = var.as_group_id
    }
  }

  condition {
    period              = 300
    filter              = "average"
    comparison_operator = ">"
    value               = 80
    unit                = "%"
    count               = 1
    metric_name         = "cpu_util"
    alarm_level         = 2
  }

  alarm_actions {
    type              = "notification"
    notification_list = [huaweicloud_smn_topic.alerts.id]
  }
}

resource "huaweicloud_ces_alarmrule" "instance_down" {
  alarm_name        = "${var.name_prefix}-as-instance-down"
  alarm_description = "AS group has fewer than 1 running instance (server down or being replaced)."

  metric {
    namespace = "SYS.AS"
  }

  resources {
    dimensions {
      name  = "instance_id"
      value = var.as_group_id
    }
  }

  condition {
    period              = 300
    filter              = "average"
    comparison_operator = "<"
    value               = 1
    count               = 1
    metric_name         = "instance_num"
    alarm_level         = 1
  }

  alarm_actions {
    type              = "notification"
    notification_list = [huaweicloud_smn_topic.alerts.id]
  }
}
