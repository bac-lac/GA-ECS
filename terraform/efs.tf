resource "aws_efs_file_system" "ga_efs" {
  creation_token  = "ga-efs-${var.ENV}"
  encrypted       = true
  kms_key_id      = data.aws_kms_alias.efs.target_key_arn
  throughput_mode = "elastic"
  tags = {
    Name = "ga-efs-${var.ENV}"
  }
}

resource "aws_efs_mount_target" "ga_efs_mount_target" {
  for_each = toset(data.aws_subnets.app.ids)
  file_system_id  = aws_efs_file_system.ga_efs.id
  security_groups = [data.aws_security_group.app.id]
  subnet_id       = each.key
}

locals {
  cluster_nodes = upper(var.MFT_CLUSTER) == "TRUE" ? 2 : 1
}

resource "aws_efs_access_point" "ga_ap" {
  for_each = toset(
    concat(
      ["userdata"],
      flatten([
        for i in range(1, local.cluster_nodes + 1) : [
          "upgrader${i}",
          "config${i}",
          "tomcatserver${i}",
          "tomcatlog${i}",
          "ghttpsroot${i}"
        ]
      ])
    )
  )
  file_system_id  = aws_efs_file_system.ga_efs.id
  posix_user {
    gid = 888
    uid = 888
  }
  root_directory {
    creation_info {
      owner_gid   = 888
      owner_uid   = 888
      permissions = 777
    }
    path = "/${each.key}"
  }
  tags = {
    Name = "${each.key}-${var.ENV}"
  }
}