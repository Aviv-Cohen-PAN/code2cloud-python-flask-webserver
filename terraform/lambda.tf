# lambda.tf

# Defines a map of common settings to be reused by all Lambda functions in this file.
locals {
  common_lambda_settings = {
    handler       = "index.handler"
    runtime       = "python3.12"
    memory_size   = 128
    architectures = ["x86_64"]
  }
}

# Defines the first Cortex custom Lambda function.
resource "aws_lambda_function" "cortex_custom_lambda" {
  filename         = "source_code/cortex_custom_lambda.zip"
  source_code_hash = filebase64sha256("source_code/cortex_custom_lambda.zip")

  function_name = var.cortex_custom_lambda_name_1
  role          = aws_iam_role.cortex_custom_lambda.arn

  handler       = local.common_lambda_settings.handler
  runtime       = local.common_lambda_settings.runtime
  memory_size   = local.common_lambda_settings.memory_size
  architectures = local.common_lambda_settings.architectures
  timeout       = 75
  tags = {
    yor_trace = "63347fb9-22ac-4586-b456-9015c4fbed0b"
  }
}

# Defines the Lambda function responsible for emptying S3 buckets.
resource "aws_lambda_function" "empty_bucket_lambda" {
  filename         = "source_code/empty_bucket_lambda.zip"
  source_code_hash = filebase64sha256("source_code/empty_bucket_lambda.zip")

  function_name = var.empty_bucket_lambda_name
  role          = aws_iam_role.empty_bucket_lambda.arn

  handler       = local.common_lambda_settings.handler
  runtime       = local.common_lambda_settings.runtime
  memory_size   = local.common_lambda_settings.memory_size
  architectures = local.common_lambda_settings.architectures
  timeout       = 600
  tags = {
    yor_trace = "5c574dc2-e7aa-4e9e-a130-8c4f62de7318"
  }
}

# Defines the second Cortex custom Lambda function.
resource "aws_lambda_function" "cortex_custom_lambda_2" {
  filename         = "source_code/cortex_custom_lambda_2.zip"
  source_code_hash = filebase64sha256("source_code/cortex_custom_lambda_2.zip")

  function_name = var.cortex_custom_lambda_name_2
  role          = aws_iam_role.cortex_custom_lambda_2.arn

  handler       = local.common_lambda_settings.handler
  runtime       = local.common_lambda_settings.runtime
  memory_size   = local.common_lambda_settings.memory_size
  architectures = local.common_lambda_settings.architectures
  timeout       = 75
  tags = {
    yor_trace = "3ba3373c-9853-4742-9ae9-99e23cf201b0"
  }
}