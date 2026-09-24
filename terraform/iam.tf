data "aws_iam_policy_document" "ga_rds_monitoring_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "ga_rds_monitoring_role" {
  name                = "ga_rds_monitoring_role-${var.ENV}"
  description         = "Provides access to Cloudwatch for RDS Enhanced Monitoring"
  assume_role_policy  = data.aws_iam_policy_document.ga_rds_monitoring_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ga_rds_monitoring_role_pa" {
  role        = aws_iam_role.ga_rds_monitoring_role.name
  policy_arn  = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

data "aws_iam_policy_document" "ga_ecs_role_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "ga_ecs_role_inline_policy" {
  statement {
    effect    = "Allow"
    actions   = ["logs:CreateLogGroup"]
    resources = ["arn:aws:logs:ca-central-1:${var.ACCOUNT}:log-group:*:*"]
  }
}

data "aws_iam_policy_document" "ga_ecs_task_role_inline_policy" {
  statement {
    effect    = "Allow"
    actions   = ["ecs:ExecuteCommand","ecs:DescribeTasks","ssmmessages:CreateDataChannel","ssmmessages:OpenDataChannel","ssmmessages:OpenControlChannel","ssmmessages:CreateControlChannel","logs:CreateLogGroup","logs:CreateLogStream","logs:PutLogEvents","logs:DescribeLogGroups"]
    resources = ["arn:aws:ecs:ca-central-1:${var.ACCOUNT}:cluster/*","arn:aws:ecs:ca-central-1:${var.ACCOUNT}:task/${aws_ecs_cluster.ga_cluster.name}/*","arn:aws:ssmmessages:ca-central-1:${var.ACCOUNT}:*","arn:aws:logs:ca-central-1:${var.ACCOUNT}:log-group:*:*"]
  }
  statement {
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = ["${var.PROFILE_CCTM_ROLE_ARN}"]
  }
}

resource "aws_iam_role" "ga_ecs_role" {
  name                = "ga_ecs_role-${var.ENV}"
  description         = "Provides access to other AWS service resources that are required to run Amazon ECS tasks"
  assume_role_policy  = data.aws_iam_policy_document.ga_ecs_role_assume_role.json
}

resource "aws_iam_role_policy" "ga_ecs_role_inline_policy" {
  name    = "ga_ecs_role_inline_policy"
  role    = aws_iam_role.ga_ecs_role.id
  policy  = data.aws_iam_policy_document.ga_ecs_role_inline_policy.json
}

resource "aws_iam_role_policy_attachment" "ga_ecs_role_pa" {
  role        = aws_iam_role.ga_ecs_role.name
  policy_arn  = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ga_ecs_task_role" {
  name                = "ga_ecs_task_role-${var.ENV}"
  description         = "The task role is an IAM role that is used by containers in a task to make AWS API calls on your behalf."
  assume_role_policy  = data.aws_iam_policy_document.ga_ecs_role_assume_role.json
}

resource "aws_iam_role_policy" "ga_ecs_task_role_inline_policy" {
  name    = "ga_ecs_task_role_inline_policy"
  role    = aws_iam_role.ga_ecs_task_role.id
  policy  = data.aws_iam_policy_document.ga_ecs_task_role_inline_policy.json
}

data "aws_iam_policy_document" "ga_sns_topic_access_policy" {
  statement {
    actions = [
      "SNS:GetTopicAttributes",
      "SNS:SetTopicAttributes",
      "SNS:AddPermission",
      "SNS:RemovePermission",
      "SNS:DeleteTopic",
      "SNS:Subscribe",
      "SNS:ListSubscriptionsByTopic",
      "SNS:Publish"
    ]
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers  = ["*"]
    }
    resources = [
      aws_sns_topic.ga_sns_topic.arn
    ]
    condition {
      test = "StringEquals"
      variable = "AWS:SourceOwner"
      values = [
        "${var.ACCOUNT}"
      ]
    }
    sid = "default_policy"
  }
  statement {
    actions = ["SNS:Publish"]
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers  = ["cloudwatch.amazonaws.com"]
    }
    resources = [
      data.aws_kms_alias.sns.target_key_arn
    ]
    sid = "Allow_Publish_Alarms"
  }
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "lambda_execution_role-${var.ENV}"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

data "aws_iam_policy_document" "create_eni_policy" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:CreateTags"
    ]

    resources = [
      "arn:aws:ec2:*:${var.ACCOUNT}:network-interface/*"
    ]
  }
}

resource "aws_iam_role_policy" "create_eni_policy" {
  name   = "create_eni_policy"
  role   = aws_iam_role.lambda_role.id
  policy = data.aws_iam_policy_document.create_eni_policy.json
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}