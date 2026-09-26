# Terraform Backend Infrastructure

This repository manages the Terraform backend infrastructure used by different environments.

The repository uses a **common Terraform configuration** at the root level and maintains environment-specific values in separate `dev` and `test` directories.

## Repository Structure

```text
terraform-backend/
│
├── .gitignore
├── README.md
├── main.tf
├── providers.tf
├── variables.tf
├── locals.tf
├── outputs.tf
│
├── dev/
│   └── terraform.tfvars
│
└── test/
    └── terraform.tfvars
```

## Design

The Terraform configuration is common for all environments.

Only the environment-specific values are maintained separately.

```text
                         terraform-backend
                                │
                   Common Terraform Configuration
                                │
          ┌─────────────────────┴─────────────────────┐
          │                                           │
         DEV                                         TEST
          │                                           │
 dev/terraform.tfvars                        test/terraform.tfvars
          │                                           │
          ▼                                           ▼
      Dev S3 Bucket                              Test S3 Bucket
      Dev DynamoDB                                Test DynamoDB
```

## Common Terraform Files

The following files are maintained at the root level:

```text
main.tf
providers.tf
variables.tf
locals.tf
outputs.tf
```

These files contain the reusable Terraform configuration.

### main.tf

The `main.tf` file calls the reusable S3 module and creates the DynamoDB state-locking table.

Example:

```hcl
module "s3module" {
  source = "git::https://github.com/vamsidharterraform/terraform-s3.git?ref=v1.0.0"

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
```

### providers.tf

The AWS provider is configured at the root level.

```hcl
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}
```

### variables.tf

The variables required by the common Terraform configuration are defined here.

```hcl
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
```

### locals.tf

Common tags used by resources created directly in the backend project are defined here.

```hcl
locals {
  common_tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
```

The reusable S3 module has its own `locals.tf` because the module also adds the bucket name as the `Name` tag.

### outputs.tf

Example:

```hcl
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
  value       = aws_dynamodb_table.terraform_locks.name
}
```

---

# Environment-Specific Variables

Environment-specific values are stored separately.

## Dev

```text
dev/
└── terraform.tfvars
```

Example:

```hcl
aws_region          = "us-west-2"
environment         = "dev"
bucket_name         = "vamsi-terraform-state-dev-usw2"
dynamodb_table_name = "terraform-state-locks-dev"
```

## Test

```text
test/
└── terraform.tfvars
```

Example:

```hcl
aws_region          = "us-west-2"
environment         = "test"
bucket_name         = "vamsi-terraform-state-test-usw2"
dynamodb_table_name = "terraform-state-locks-test"
```

---

# Terraform Initialization

Terraform initialization is performed from the repository root.

```bash
cd terraform-backend
```

Run:

```bash
terraform init
```

`terraform init` downloads the required providers and reusable modules.

The environment-specific `.tfvars` file does not normally need to be supplied during `terraform init`.

---

# Dev Deployment

## 1. Initialize Terraform

```bash
terraform init
```

## 2. Validate

```bash
terraform validate
```

## 3. Format

```bash
terraform fmt -recursive
```

## 4. Create Dev Plan

```bash
terraform plan -var-file="dev/terraform.tfvars"
```

This loads the values from:

```text
dev/terraform.tfvars
```

Terraform then uses the common configuration from:

```text
main.tf
providers.tf
variables.tf
locals.tf
outputs.tf
```

## 5. Apply Dev

```bash
terraform apply -var-file="dev/terraform.tfvars"
```

Terraform will create the Dev backend resources.

Example:

```text
S3
└── vamsi-terraform-state-dev-usw2

DynamoDB
└── terraform-state-locks-dev
```

---

# Test Deployment

## 1. Create Test Plan

```bash
terraform plan -var-file="test/terraform.tfvars"
```

## 2. Apply Test

```bash
terraform apply -var-file="test/terraform.tfvars"
```

Terraform uses the same root-level Terraform configuration but loads the values from:

```text
test/terraform.tfvars
```

Example:

```text
S3
└── vamsi-terraform-state-test-usw2

DynamoDB
└── terraform-state-locks-test
```

---

# Complete Command Flow

## Dev

```bash
cd terraform-backend

terraform init

terraform fmt -recursive

terraform validate

terraform plan -var-file="dev/terraform.tfvars"

terraform apply -var-file="dev/terraform.tfvars"
```

## Test

```bash
cd terraform-backend

terraform init

terraform fmt -recursive

terraform validate

terraform plan -var-file="test/terraform.tfvars"

terraform apply -var-file="test/terraform.tfvars"
```

---

# Why `-var-file` Is Required

Terraform automatically loads variable files only when they follow the automatic naming convention and are located in the current Terraform working directory.

In this repository:

```text
terraform-backend/
│
├── main.tf
├── variables.tf
│
├── dev/
│   └── terraform.tfvars
│
└── test/
    └── terraform.tfvars
```

Terraform does not automatically load:

```text
dev/terraform.tfvars
```

or:

```text
test/terraform.tfvars
```

when running Terraform from the root directory.

Therefore, the appropriate file must be explicitly provided:

```bash
terraform plan -var-file="dev/terraform.tfvars"
```

or:

```bash
terraform plan -var-file="test/terraform.tfvars"
```

This ensures that the correct environment-specific values are used.

---

# Environment Isolation

Although the Terraform code is common, the environment-specific values are different.

```text
                    Common Terraform Code
                           │
             ┌─────────────┴─────────────┐
             │                           │
            DEV                         TEST
             │                           │
   dev/terraform.tfvars         test/terraform.tfvars
             │                           │
             ▼                           ▼
       environment=dev             environment=test
             │                           │
             ▼                           ▼
        Dev resources              Test resources
```

This allows the same Terraform implementation to be reused without duplicating infrastructure code.

---

# Important: Terraform State

The backend infrastructure itself creates the resources that will later be used for Terraform state management.

The S3 module creates the S3 bucket:

```text
S3
└── Terraform State Storage
```

The backend project creates the DynamoDB table:

```text
DynamoDB
└── Terraform State Locking
```

These resources are created before the other Terraform infrastructure uses them as its backend.

For example, your future environment backend can use:

```hcl
terraform {
  backend "s3" {
    bucket         = "vamsi-terraform-state-dev-usw2"
    key            = "dev/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-state-locks-dev"
    encrypt        = true
  }
}
```

The Test environment can use a different state key/table:

```hcl
terraform {
  backend "s3" {
    bucket         = "vamsi-terraform-state-test-usw2"
    key            = "test/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-state-locks-test"
    encrypt        = true
  }
}
```

> The backend resources must exist before another Terraform configuration can initialize against them.

---

# Resource Separation

The backend project creates two types of resources.

```text
terraform-backend
│
├── Reusable S3 Module
│   └── Terraform State S3 Bucket
│
└── Direct Terraform Resource
    └── DynamoDB State Locking Table
```

The reusable S3 module is maintained in a separate repository:

```text
terraform-s3
```

and consumed using:

```hcl
module "s3module" {
  source = "git::https://github.com/vamsidharterraform/terraform-s3.git?ref=v1.0.0"
}
```

This allows the S3 module to be independently versioned and reused.

---

# Best Practices

- Keep reusable infrastructure in separate Terraform modules.
- Keep environment-specific values in separate `.tfvars` files.
- Use Git tags to version Terraform modules.
- Do not hard-code environment-specific values in reusable modules.
- Do not store AWS credentials in Terraform files.
- Do not store secrets in committed `.tfvars` files.
- Commit `.terraform.lock.hcl` to Git.
- Review `terraform plan` before every `terraform apply`.
- Use separate state for different environments.
- Keep Terraform backend infrastructure separate from application infrastructure.

---

# Summary

The repository follows this model:

```text
terraform-backend
│
├── Common Terraform Code
│   ├── main.tf
│   ├── providers.tf
│   ├── variables.tf
│   ├── locals.tf
│   └── outputs.tf
│
├── dev
│   └── terraform.tfvars
│
└── test
    └── terraform.tfvars
```

The same Terraform code is used for both environments.

Only the variable file changes:

```bash
# Dev
terraform plan -var-file="dev/terraform.tfvars"

# Test
terraform plan -var-file="test/terraform.tfvars"
```

This provides a simple and reusable environment-management pattern while avoiding duplication of the Terraform implementation.