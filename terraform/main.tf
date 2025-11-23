# DevSecOps Learning Project - Secure S3 Bucket
# Demonstrates security best practices with IaC

terraform {
  required_version = ">= 1.5.0"

  # Remote state backend configuration
  # IMPORTANT: Replace these values with your own S3 bucket and DynamoDB table
  # For first-time setup, comment out this backend block and use local state
  # After creating your state bucket, uncomment and run `terraform init -migrate-state`
  backend "s3" {
    bucket         = "YOUR-TERRAFORM-STATE-BUCKET"  # Replace with your bucket name
    key            = "devsecops-pipeline/terraform.tfstate"
    region         = "us-east-1"                    # Replace with your region
    dynamodb_table = "YOUR-TERRAFORM-LOCK-TABLE"    # Optional: for state locking
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "devsecops-pipeline"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Purpose     = "DevSecOps Learning"
    }
  }
}

# ============== DATA SOURCES ==============

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ============== S3 BUCKET (SECURE) ==============

# Main application bucket
resource "aws_s3_bucket" "app" {
  bucket = "${var.project_name}-${var.environment}-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name        = "DevSecOps Application Bucket"
    Description = "Demonstrates security best practices"
  }
}

# Block ALL public access (security best practice)
resource "aws_s3_bucket_public_access_block" "app" {
  bucket = aws_s3_bucket.app.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning (recover from accidents)
resource "aws_s3_bucket_versioning" "app" {
  bucket = aws_s3_bucket.app.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Server-side encryption with AES256 (free tier)
# Note: Using AES256 instead of KMS customer managed keys to stay in free tier
# KMS would cost ~$1/month per key + $0.03 per 10,000 requests
resource "aws_s3_bucket_server_side_encryption_configuration" "app" {
  bucket = aws_s3_bucket.app.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Lifecycle rule (cost optimization)
resource "aws_s3_bucket_lifecycle_configuration" "app" {
  bucket = aws_s3_bucket.app.id

  rule {
    id     = "delete-old-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    filter {}
  }

  rule {
    id     = "abort-incomplete-uploads"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    filter {}
  }
}

# Access logging bucket
resource "aws_s3_bucket" "logs" {
  bucket = "${var.project_name}-logs-${var.environment}-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name        = "DevSecOps Logs Bucket"
    Description = "Stores access logs"
  }
}

# Block public access on logs bucket
resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Encryption for logs bucket (AES256 = free tier)
resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Enable versioning on logs bucket
resource "aws_s3_bucket_versioning" "logs" {
  bucket = aws_s3_bucket.logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Configure bucket ownership for logging
resource "aws_s3_bucket_ownership_controls" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# ACL for log delivery
resource "aws_s3_bucket_acl" "logs" {
  bucket = aws_s3_bucket.logs.id
  acl    = "log-delivery-write"

  depends_on = [aws_s3_bucket_ownership_controls.logs]
}

# Enable logging on main bucket
resource "aws_s3_bucket_logging" "app" {
  bucket = aws_s3_bucket.app.id

  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "app-logs/"
}
