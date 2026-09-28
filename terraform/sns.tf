resource "aws_sns_topic" "ga_sns_topic" {
  name = "GoAnywhere_${var.ENV}_Alarms_Topic"
  kms_master_key_id = data.aws_kms_alias.sns.target_key_id
  delivery_policy = <<EOF
{
  "http": {
    "defaultHealthyRetryPolicy": {
      "minDelayTarget": 20,
      "maxDelayTarget": 20,
      "numRetries": 3,
      "numMaxDelayRetries": 0,
      "numNoDelayRetries": 0,
      "numMinDelayRetries": 0,
      "backoffFunction": "linear"
    },
    "disableSubscriptionOverrides": false,
    "defaultRequestPolicy": {
      "headerContentType": "text/plain; charset=UTF-8"
    }
  }
}
EOF
}

resource "aws_sns_topic_subscription" "ga_sns_topic_subscription" {
  for_each  = toset(var.CLOUDWATCH_EMAIL)
  topic_arn = aws_sns_topic.ga_sns_topic.arn
  protocol  = "email"
  endpoint  = each.value
}

resource "aws_sns_topic_policy" "ga_sns_topic_policy" {
  arn = aws_sns_topic.ga_sns_topic.arn
  policy = data.aws_iam_policy_document.ga_sns_topic_access_policy.json
}
