resource "aws_ecs_cluster" "ga_cluster" {
  name = "ga-cluster-${var.ENV}"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_cluster_capacity_providers" "ga_cluster_capacity_providers" {
  cluster_name = aws_ecs_cluster.ga_cluster.name

  capacity_providers = ["FARGATE"]
}

resource "aws_ecs_task_definition" "ga_task_definition_mft" {
  count                     = upper(var.MFT_CLUSTER) == "TRUE" ? 2 : 1
  family                    = "ga-task-definition-mft${count.index + 1}-${var.ENV}"
  requires_compatibilities  = ["FARGATE"]
  network_mode              = "awsvpc"
  cpu                       = var.TASK_DEFINITION_CPU
  memory                    = var.TASK_DEFINITION_MEMORY
  execution_role_arn        = aws_iam_role.ga_ecs_role.arn
  task_role_arn             = aws_iam_role.ga_ecs_task_role.arn
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
  dynamic "volume" {
    for_each = tomap({
      ga_ap_userdata      = aws_efs_access_point.ga_ap["userdata"].id
      ga_ap_upgrader      = aws_efs_access_point.ga_ap["upgrader${count.index + 1}"].id
      ga_ap_config        = aws_efs_access_point.ga_ap["config${count.index + 1}"].id
      ga_ap_tomcatserver  = aws_efs_access_point.ga_ap["tomcatserver${count.index + 1}"].id
      ga_ap_tomcatlog     = aws_efs_access_point.ga_ap["tomcatlog${count.index + 1}"].id
      ga_ap_ghttpsroot    = aws_efs_access_point.ga_ap["ghttpsroot${count.index + 1}"].id
    })
    content {
      name = volume.key

      efs_volume_configuration {
        file_system_id        = aws_efs_file_system.ga_efs.id
        transit_encryption    = "ENABLED"
        authorization_config {
          access_point_id = volume.value
        }
      }
    }
  }
  container_definitions = templatefile("task-definitions/mft.tftpl", {
                                        ECR_IMAGE         = var.ECR_IMAGE,
                                        ADMIN_DB_USERNAME = var.ADMIN_DB_USERNAME,
                                        ADMIN_DB_PASSWORD = var.ADMIN_DB_PASSWORD,
                                        FORCE_REFRESH     = var.FORCE_REFRESH,
                                        FRESH_INSTALL     = var.FRESH_INSTALL,
                                        MFT_NUMBER        = count.index + 1,
                                        MFT_CLUSTER       = var.MFT_CLUSTER
                                      })
}

resource "aws_ecs_service" "ga_service_mft" {
  count                 = upper(var.MFT_CLUSTER) == "TRUE" ? 2 : 1
  name                  = "ga-service-mft${count.index + 1}-${var.ENV}"
  cluster               = aws_ecs_cluster.ga_cluster.id
  task_definition       = aws_ecs_task_definition.ga_task_definition_mft[count.index].arn
  launch_type           = "FARGATE"
  platform_version      = "LATEST"
  force_new_deployment  = true
  scheduling_strategy   = "REPLICA"
  desired_count         = 1
  network_configuration {
    subnets             = data.aws_subnets.app.ids
    security_groups     = [data.aws_security_group.app.id]
    assign_public_ip    = false
  }
  load_balancer {
    target_group_arn    = aws_lb_target_group.ga_tg_8001.arn
    container_name      = "MFT-${count.index + 1}"
    container_port      = 8001
  }
  load_balancer {
    target_group_arn    = aws_lb_target_group.ga_tg_8009.arn
    container_name      = "MFT-${count.index + 1}"
    container_port      = 8009
  }
  load_balancer {
    target_group_arn    = aws_lb_target_group.ga_tg_8443.arn
    container_name      = "MFT-${count.index + 1}"
    container_port      = 8443
  }
  load_balancer {
    target_group_arn    = aws_lb_target_group.ga_tg_8022.arn
    container_name      = "MFT-${count.index + 1}"
    container_port      = 8022
  }
  enable_execute_command = true
}