# Terraform Backend Module

This Terraform module creates the AWS resources required for storing and locking Terraform remote state.

## Architecture

```text
Terraform
    |
    v
terraform-backend module
    |
    +-------------------+
    |                   |
    v                   v
   S3               DynamoDB
    |                   |
    |                   |
Terraform State      State Lock
```

## Resources Created

| Resource | Purpose |
|---|---|
| S3 Bucket | Stores the Terraform remote state file |
| S3 Versioning | Maintains previous versions of the state file |
| S3 Server-Side Encryption | Encrypts Terraform state using AES256 |
| DynamoDB Table | Provides Terraform state locking |
| S3 Bucket Tags | Identifies environment and ownership |
| DynamoDB Tags | Identifies environment and ownership |

## Module Structure

```text
terraform-backend/
├── main.tf
├── variables.tf
├── outputs.tf
└── README.md
```

## Usage

Call the module from the root Terraform configuration:

```hcl
module "terraform_backend" {
  source = "./modules/terraform-backend"

  bucket_name         = "vamsi-eks-terraform-state-usw2"
  dynamodb_table_name = "terraform-eks-state-locks"
  environment         = "dev"
}
```

## Variables

| Variable | Description | Type | Default |
|---|---|---|---|
| `bucket_name` | S3 bucket used to store Terraform state | `string` | Required |
| `dynamodb_table_name` | DynamoDB table used for state locking | `string` | Required |
| `environment` | Environment name | `string` | `dev` |

## Outputs

| Output | Description |
|---|---|
| `s3_bucket_name` | Name of the Terraform state S3 bucket |
| `s3_bucket_arn` | ARN of the Terraform state S3 bucket |
| `dynamodb_table_name` | Name of the state-locking DynamoDB table |

## S3 Configuration

The S3 bucket has:

- Versioning enabled
- AES256 server-side encryption
- Terraform state storage
- Environment and management tags

Example:

```text
S3 Bucket
   |
   +-- terraform.tfstate
   +-- Previous state versions
   +-- Server-side encryption
```

## DynamoDB Configuration

The DynamoDB table is configured for Terraform state locking.

```text
Table: terraform-eks-state-locks

Partition Key:
LockID (String)
```

Terraform uses the lock to prevent multiple users or CI/CD pipelines from modifying the same state simultaneously.

## Important Note

The backend configuration itself cannot use Terraform module outputs.

For example, this is not valid:

```hcl
backend "s3" {
  bucket = module.terraform_backend.s3_bucket_name
}
```

The backend bucket must be specified directly during Terraform initialization.

## Example Backend Configuration

```hcl
terraform {
  backend "s3" {
    bucket         = "vamsi-eks-terraform-state-usw2"
    key            = "eks/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-eks-state-locks"
    encrypt        = true
  }
}
```

## Deployment

Initialize Terraform:

```bash
terraform init
```

Review the resources:

```bash
terraform plan
```

Create the backend resources:

```bash
terraform apply
```

## Destroy

The current module has:

```hcl
prevent_destroy = false
```

Therefore, Terraform can destroy the S3 bucket if it is removed from the configuration.

For a production Terraform state bucket, consider enabling deletion protection and following your organization's backup and recovery policy.

## Interview Explanation

> "I created a reusable Terraform backend module that provisions an S3 bucket for remote Terraform state and a DynamoDB table for state locking. The S3 bucket has versioning and server-side encryption enabled. This allows multiple engineers or CI/CD pipelines to work with a centralized Terraform state while preventing concurrent state modifications."