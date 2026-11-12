data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "../lambda/lambda_function.py"
  output_path = "../lambda/lambda_function.zip"
}

resource "aws_lambda_function" "eni_lambda" {
  function_name                   = "HandleENICreation-${var.ENV}"
  role                            = aws_iam_role.lambda_role.arn
  description                     = "Lambda function to handle ENI creation events and tag them with CBRID"
  handler                         = "lambda_function.lambda_handler"
  runtime                         = "python3.12"
  timeout                         = 30
  filename                        = data.archive_file.lambda_zip.output_path
  reserved_concurrent_executions  = 10
  source_code_hash                = data.archive_file.lambda_zip.output_base64sha256
  tracing_config {
    mode                          = "Active"
  }
}

resource "aws_cloudwatch_event_rule" "eni_create_rule" {
  name            = "ENICreateRule-${var.ENV}"
  description     = "Trigger Lambda on ENI creation"
  event_pattern   = jsonencode({
    source        = ["aws.ec2"]
    "detail-type" = ["AWS API Call via CloudTrail"]
    detail = {
      eventSource = ["ec2.amazonaws.com"]
      eventName   = ["CreateNetworkInterface"]
    }
  })
}

resource "aws_cloudwatch_event_target" "eni_lambda_target" {
  rule      = aws_cloudwatch_event_rule.eni_create_rule.name
  target_id = "ENILambdaTarget-${var.ENV}"
  arn       = aws_lambda_function.eni_lambda.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.eni_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.eni_create_rule.arn
}

data "archive_file" "lambda_db_zip" {
  type        = "zip"
  source_file = "../lambda/schedule_db_update.py"
  output_path = "../lambda/schedule_db_update.zip"
}

resource "aws_lambda_function" "rds_maintenance" {
  function_name                   = "rds-maintenance-${var.ENV}"
  description                     = "Lambda function to handle RDS maintenance tasks"
  filename                        = data.archive_file.lambda_db_zip.output_path
  source_code_hash                = data.archive_file.lambda_db_zip.output_base64sha256
  role                            = aws_iam_role.rds_maintenance_lambda.arn
  handler                         = "schedule_db_update.lambda_handler"
  runtime                         = "python3.12"
  timeout                         = 30
  reserved_concurrent_executions  = 10
  environment {
    variables = {
      DB_INSTANCE_ID  = aws_db_instance.ga_mysql.id
      SNS_TOPIC_ARN   = aws_sns_topic.rds_maintenance.arn
    }
  }
  tracing_config {
    mode            = "Active"
  }
}

resource "aws_cloudwatch_event_rule" "maintenance_rule" {
  name                = "rds-maintenance-check-${var.ENV}"
  schedule_expression = "${var.RDS_MAINTENANCE_SCHEDULE_EXPRESSION}"
}

resource "aws_cloudwatch_event_target" "lambda" {
  rule        = aws_cloudwatch_event_rule.maintenance_rule.name
  target_id   = "lambda"
  arn         = aws_lambda_function.rds_maintenance.arn
}

resource "aws_lambda_permission" "rds_maintenance_allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rds_maintenance.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.maintenance_rule.arn
}
