terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-southeast-1" # Singapore, Free Tier OK
}


resource "aws_s3_bucket" "images" {
  bucket = "my-upload-image-bucket-sun-devops-demo"

  tags = {
    Name = "image-upload-bucket"
  }
}


resource "aws_dynamodb_table" "images" {
  name         = "Images"
  billing_mode = "PAY_PER_REQUEST" # On-demand => free tier
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Name = "images-table"
  }
}

resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"
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


resource "aws_iam_role_policy" "lambda_policy" {
  name = "lambda_policy"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect   = "Allow",
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ],
        Effect   = "Allow",
        Resource = "${aws_s3_bucket.images.arn}/*"
      },
      {
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem"
        ],
        Effect   = "Allow",
        Resource = aws_dynamodb_table.images.arn
      }
    ]
  })
}

#resource "aws_lambda_layer_version" "pillow" {
#  filename            = "pillow-layer.zip"
#  layer_name          = "pillow-layer"
#  compatible_runtimes = ["python3.12"]
#}

resource "aws_lambda_function" "resize" {
  function_name = "resizeImage"
  handler       = "index.lambda_handler"
  runtime       = "python3.10"
  role          = aws_iam_role.lambda_exec.arn
  filename      = "lambda.zip"
  layers = ["arn:aws:lambda:ap-southeast-1:770693421928:layer:Klayers-p310-Pillow:10"]

  depends_on = [aws_iam_role_policy.lambda_policy]
  source_code_hash = filebase64sha256("lambda.zip")
}


resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.resize.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.images.arn
}


resource "aws_s3_bucket_notification" "images_notification" {
  bucket = aws_s3_bucket.images.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.resize.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_s3]
}


