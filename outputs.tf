output "s3_bucket_name" {
  description = "Terraform state S3 bucket name"
  value       = module.s3module.s3_bucket_name
}

output "s3_bucket_arn" {
  description = "Terraform state S3 bucket ARN"
  value       = module.s3module.s3_bucket_arn
}

output "dynamodb_table_name" {
  description = "Terraform state locking DynamoDB table"
  value       = aws_dynamodb_table.terraform_locks.id
}