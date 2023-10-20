resource "aws_iam_role" "lambda_role" {
  name = "lambda-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "iam_full_access" {
  name        = "iam_full_access_policy"
  description = "Amazon IAM Full Access Policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "iam:*", 
        Effect = "Allow",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_policy" "secrets_manager_full_access" {
  name        = "secrets_manager_full_access_policy"
  description = "Amazon Secrets Manager Full Access Policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "secretsmanager:*", 
        Effect = "Allow",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "lambda_iam_full_access" {
  name        = "IAM full access role attachment to the lambda"
  policy_arn = aws_iam_policy.iam_full_access.arn
  roles      = [aws_iam_role.lambda_role.name]
}

resource "aws_iam_policy_attachment" "lambda_secrets_manager_full_access" {
  name        = "Secrets Manager full access role attachment to the lambda"
  policy_arn = aws_iam_policy.secrets_manager_full_access.arn
  roles      = [aws_iam_role.lambda_role.name]
}

resource "aws_lambda_function" "my_lambda_function" {
  function_name = var.function_name
  handler = var.handler # Specify your Python handler function
  runtime = var.runtime # Specify the Python runtime version
  role = aws_iam_role.lambda_role.arn
  # The deployment package (ZIP file) containing your Python code and dependencies.
  filename = "lambda_function.zip"
}

resource "aws_cloudwatch_event_rule" "event_rule" {
  name = "my-event-rule"
  description = "My EventBridge Rule"
  event_pattern = <<EOF
{
  "source": ["aws.iam"],
  "detail": {
    "eventName": ["IAM Key Rotate"]
  }
}
EOF

  # Schedule the rule to trigger daily at 8 PM UTC
  schedule_expression = "cron(25 15 * * ? *)"

}

resource "aws_lambda_permission" "event_rule_lambda_permission" {
  statement_id  = "AllowExecutionFromEventRule"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.my_lambda_function.arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.event_rule.arn
}

resource "aws_cloudwatch_event_target" "event_target" {
  rule = aws_cloudwatch_event_rule.event_rule.name
  target_id = "my-target"
  arn = aws_lambda_function.my_lambda_function.arn
}