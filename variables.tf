variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "bucket_name" {
  description = "Terraform state S3 bucket name"
  type        = string
}

variable "dynamodb_table_name" {
  description = "DynamoDB state locking table name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}