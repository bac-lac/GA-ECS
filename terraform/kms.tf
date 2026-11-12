data "aws_kms_alias" "sns" {
  name = "alias/aws/sns"
}

data "aws_kms_alias" "efs" {
  name = "alias/aws/elasticfilesystem"
}

data "aws_kms_alias" "lambda" {
  name = "alias/aws/lambda"
}