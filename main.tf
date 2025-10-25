terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket        = ""
    key           = ""
    region        = ""
    use_lockfile  = true
  }
}

# --- Provider ---
provider "aws" {
  region = var.region
}

# --- S3 bucket ---
resource "aws_s3_bucket" "images" {
  bucket = var.bucket_name

  tags = {
    Name = "${var.env}-image-upload-bucket"
  }
}

# --- DynamoDB table ---
resource "aws_dynamodb_table" "images" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Name = "${var.env}-images-table"
  }
}

# --- IAM Role for Lambda ---
resource "aws_iam_role" "lambda_exec" {
  name = var.lambda_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# --- IAM Policy for Lambda ---
resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.env}-lambda-policy"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect   = "Allow",
        Action   = [
          "s3:GetObject",
          "s3:PutObject"
        ],
        Resource = "${aws_s3_bucket.images.arn}/*"
      },
      {
        Effect   = "Allow",
        Action   = [
          "dynamodb:PutItem",
          "dynamodb:GetItem"
        ],
        Resource = aws_dynamodb_table.images.arn
      }
    ]
  })
}

# --- Lambda Function ---
resource "aws_lambda_function" "resize" {
  function_name = var.lambda_name
  handler       = var.lambda_handler
  runtime       = var.lambda_runtime
  role          = aws_iam_role.lambda_exec.arn
  filename      = var.lambda_filename
  layers        = [var.lambda_layer_arn]

  source_code_hash = filebase64sha256(var.lambda_filename)
  depends_on       = [aws_iam_role_policy.lambda_policy]
}

# --- Allow S3 to trigger Lambda ---
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.resize.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.images.arn
}

# --- S3 -> Lambda event notification ---
resource "aws_s3_bucket_notification" "images_notification" {
  bucket = aws_s3_bucket.images.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.resize.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_s3]
}
