module "s3module" {
  source = "git::https://github.com/vamsidharterraform/s3module.git//s3?ref=main"

  bucket_name = var.bucket_name
  environment = var.environment
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = local.common_tags
}