variable "env" {
  description = "Deployment environment (e.g., dev, staging, prod)"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "bucket_name" {
  description = "S3 bucket name"
  type        = string
}

variable "dynamodb_table_name" {
  description = "DynamoDB table name"
  type        = string
}

variable "lambda_name" {
  description = "Lambda function name"
  type        = string
}

variable "lambda_role_name" {
  description = "IAM role name for Lambda"
  type        = string
}

variable "lambda_layer_arn" {
  description = "Lambda layer ARN"
  type        = string
}

variable "lambda_runtime" {
  description = "Lambda runtime (e.g. python3.10)"
  type        = string
}

variable "lambda_filename" {
  description = "Lambda deployment package filename"
  type        = string
}

variable "lambda_handler" {
  description = "Lambda handler"
  type        = string
}