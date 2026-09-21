resource "aws_cloudwatch_metric_alarm" "ga_cw_db_cpu_alarm" {
  alarm_name                = "${var.ENV} - MySQL CPU reaching 90%"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  alarm_actions             = [aws_sns_topic.ga_sns_topic.arn]
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/RDS"
  statistic                 = "Maximum"
  dimensions = {
    DBInstanceIdentifier    = aws_db_instance.ga_mysql.identifier
  }
  period                    = 60
  evaluation_periods        = 5
  datapoints_to_alarm       = 5
  threshold                 = 90
  treat_missing_data        = "missing"
  alarm_description         = "This metric monitors RDS ${var.ENV} cpu utilization"
}

resource "aws_cloudwatch_metric_alarm" "ga_cw_db_memory_alarm" {
  alarm_name                = "${var.ENV} - MySQL Memory reaching 90%"
  comparison_operator       = "LessThanOrEqualToThreshold"
  alarm_actions             = [aws_sns_topic.ga_sns_topic.arn]
  metric_name               = "FreeableMemory"
  namespace                 = "AWS/RDS"
  statistic                 = "Minimum"
  dimensions = {
    DBInstanceIdentifier    = aws_db_instance.ga_mysql.identifier
  }
  period                    = 60
  evaluation_periods        = 5
  datapoints_to_alarm       = 5
  threshold                 = floor(var.DB_INSTANCE_CLASS_MEMORY * 1024 * 1024 * 1024 * 0.10)
  treat_missing_data        = "missing"
  alarm_description         = "This metric monitors RDS ${var.ENV} memory utilization"
}

resource "aws_cloudwatch_metric_alarm" "ga_cw_db_storage_alarm" {
  alarm_name                = "${var.ENV} - MySQL Storage reaching 90%"
  comparison_operator       = "LessThanOrEqualToThreshold"
  alarm_actions             = [aws_sns_topic.ga_sns_topic.arn]
  metric_name               = "FreeStorageSpace"
  namespace                 = "AWS/RDS"
  statistic                 = "Minimum"
  dimensions = {
    DBInstanceIdentifier    = aws_db_instance.ga_mysql.identifier
  }
  period                    = 60
  evaluation_periods        = 5
  datapoints_to_alarm       = 5
  threshold                 = floor(aws_db_instance.ga_mysql.allocated_storage * 1024 * 1024 * 1024 * 0.10)
  treat_missing_data        = "missing"
  alarm_description         = "This metric monitors RDS ${var.ENV} storage utilization"
}

resource "aws_cloudwatch_metric_alarm" "ga_cw_ecs_cpu_alarm" {
  for_each                  = upper(var.MFT_CLUSTER) == "TRUE" ? toset(["1", "2"]) : toset(["1"])
  alarm_name                = "${var.ENV} - MFT-${each.key} CPU reaching 90%"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  alarm_actions             = [aws_sns_topic.ga_sns_topic.arn]
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/ECS"
  statistic                 = "Maximum"
  dimensions                = zipmap(["ServiceName", "ClusterName"], ["ga-service-mft${each.key}-${var.ENV}", aws_ecs_cluster.ga_cluster.name])
  period                    = 60
  evaluation_periods        = 5
  datapoints_to_alarm       = 5
  threshold                 = 90
  treat_missing_data        = "missing"
  alarm_description         = "This metric monitors MFT-${each.key} ${var.ENV} cpu utilization"
}

resource "aws_cloudwatch_metric_alarm" "ga_cw_ecs_memory_alarm" {
  for_each                  = upper(var.MFT_CLUSTER) == "TRUE" ? toset(["1", "2"]) : toset(["1"])
  alarm_name                = "${var.ENV} - MFT-${each.key} Memory reaching 90%"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  alarm_actions             = [aws_sns_topic.ga_sns_topic.arn]
  insufficient_data_actions = []
  metric_name               = "MemoryUtilization"
  namespace                 = "AWS/ECS"
  statistic                 = "Maximum"
  dimensions                = zipmap(["ServiceName", "ClusterName"], ["ga-service-mft${each.key}-${var.ENV}", aws_ecs_cluster.ga_cluster.name])
  period                    = 60
  evaluation_periods        = 5
  datapoints_to_alarm       = 5
  threshold                 = 90
  treat_missing_data        = "missing"
  alarm_description         = "This metric monitors MFT-${each.key} ${var.ENV} memory utilization"
}

resource "aws_cloudwatch_metric_alarm" "ga_cw_ecs_storage_alarm" {
  for_each                  = upper(var.MFT_CLUSTER) == "TRUE" ? toset(["1", "2"]) : toset(["1"])
  alarm_name                = "${var.ENV} - MFT-${each.key} Storage reaching 90%"
  comparison_operator       = "GreaterThanThreshold"
  alarm_actions             = [aws_sns_topic.ga_sns_topic.arn]
  evaluation_periods        = 5
  datapoints_to_alarm       = 5
  threshold                 = 90
  treat_missing_data        = "missing"
  alarm_description         = "This metric monitors MFT-${each.key} ${var.ENV} storage utilization"

  metric_query {
    id          = "e1"
    expression  = "m1*100/m2"
    label       = "Storage used in %"
    return_data = "true"
  }

  metric_query {
    id = "m1"
    return_data = "false"

    metric {
      metric_name = "EphemeralStorageUtilized"
      namespace   = "ECS/ContainerInsights"
      period      = 60
      stat        = "Maximum"
      dimensions  = zipmap(["ServiceName", "ClusterName"], ["ga-service-mft${each.key}-${var.ENV}", aws_ecs_cluster.ga_cluster.name])
    }
  }

  metric_query {
    id = "m2"
    return_data = "false"

    metric {
      metric_name = "EphemeralStorageReserved"
      namespace   = "ECS/ContainerInsights"
      period      = 60
      stat        = "Maximum"
      dimensions  = zipmap(["ServiceName", "ClusterName"], ["ga-service-mft${each.key}-${var.ENV}", aws_ecs_cluster.ga_cluster.name])
    }
  }

}

resource "aws_cloudwatch_metric_alarm" "ga_cw_nlb_8022_alarm" {
  alarm_name                = "${var.ENV} - NLB port 8022 (SFTP) unhealthy host"
  comparison_operator       = "LessThanThreshold"
  alarm_actions             = [aws_sns_topic.ga_sns_topic.arn]
  metric_name               = "HealthyHostCount"
  namespace                 = "AWS/NetworkELB"
  statistic                 = "Minimum"
  dimensions                = zipmap(["TargetGroup", "LoadBalancer"], [aws_lb_target_group.ga_tg_8022.arn_suffix, data.aws_lb.ga_nlb.arn_suffix])
  period                    = 60
  evaluation_periods        = 5
  datapoints_to_alarm       = 5
  threshold                 = 1
  treat_missing_data        = "missing"
  alarm_description         = "This metric monitors NLB port 8022 (SFTP) ${var.ENV} health"
}

resource "aws_cloudwatch_metric_alarm" "ga_cw_alb_8001_alarm" {
  alarm_name                = "${var.ENV} - ALB port 8001 (admin portal) unhealthy host"
  comparison_operator       = "LessThanThreshold"
  alarm_actions             = [aws_sns_topic.ga_sns_topic.arn]
  metric_name               = "HealthyHostCount"
  namespace                 = "AWS/ApplicationELB"
  statistic                 = "Minimum"
  dimensions                = zipmap(["TargetGroup", "LoadBalancer"], [aws_lb_target_group.ga_tg_8001.arn_suffix, data.aws_lb.ga_alb.arn_suffix])
  period                    = 60
  evaluation_periods        = 5
  datapoints_to_alarm       = 5
  threshold                 = 1
  treat_missing_data        = "missing"
  alarm_description         = "This metric monitors ALB port 8001 (admin portal) ${var.ENV} health"
}

resource "aws_cloudwatch_metric_alarm" "ga_cw_alb_8443_alarm" {
  alarm_name                = "${var.ENV} - ALB port 8443 (web client) unhealthy host"
  comparison_operator       = "LessThanThreshold"
  alarm_actions             = [aws_sns_topic.ga_sns_topic.arn]
  metric_name               = "HealthyHostCount"
  namespace                 = "AWS/ApplicationELB"
  statistic                 = "Minimum"
  dimensions                = zipmap(["TargetGroup", "LoadBalancer"], [aws_lb_target_group.ga_tg_8443.arn_suffix, data.aws_lb.ga_alb.arn_suffix])
  period                    = 60
  evaluation_periods        = 5
  datapoints_to_alarm       = 5
  threshold                 = 1
  treat_missing_data        = "missing"
  alarm_description         = "This metric monitors ALB port 8443 (web client) ${var.ENV} health"
}

resource "aws_cloudwatch_metric_alarm" "ga_cw_nlb_8009_alarm" {
  alarm_name                = "${var.ENV} - NLB port 8009 (Agent) unhealthy host"
  comparison_operator       = "LessThanThreshold"
  alarm_actions             = [aws_sns_topic.ga_sns_topic.arn]
  metric_name               = "HealthyHostCount"
  namespace                 = "AWS/NetworkELB"
  statistic                 = "Minimum"
  dimensions                = zipmap(["TargetGroup", "LoadBalancer"], [aws_lb_target_group.ga_tg_8009.arn_suffix, data.aws_lb.ga_nlb.arn_suffix])
  period                    = 60
  evaluation_periods        = 5
  datapoints_to_alarm       = 5
  threshold                 = upper(var.MFT_CLUSTER) == "TRUE" ? 2 : 1
  treat_missing_data        = "missing"
  alarm_description         = "This metric monitors NLB port 8009 (Agent) ${var.ENV} health"
}