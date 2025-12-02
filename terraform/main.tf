# DevSecOps Learning Project - Secure S3 Bucket
# Demonstrates security best practices with IaC

terraform {
  required_version = ">= 1.5.0"

  # Remote state backend (uses base-infrastructure S3 bucket)
  # Terraform automatically manages separate state files per workspace:
  # - Workspace "dev": env:/dev/devsecops-pipeline/terraform.tfstate
  # - Workspace "staging": env:/staging/devsecops-pipeline/terraform.tfstate
  # - Workspace "prod": env:/prod/devsecops-pipeline/terraform.tfstate
  # - Default workspace: devsecops-pipeline/terraform.tfstate
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

  # Comprehensive tagging strategy (auto-applied to all resources)
  # Aligned with organization-wide tagging standards
  default_tags {
    tags = {
      # Core Tags (Required)
      Owner       = "YourName"  # Replace with your name
      OwnerEmail  = "your.email@example.com"  # Replace with your email
      Environment = local.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"

      # Organization Tags
      Category    = "DevSecOps"
      Domain      = "Infrastructure"
      ProjectType = "CI/CD Pipeline"

      # Workspace Tracking
      Workspace = terraform.workspace

      # Cost Tags
      MonthlyBudget = "0"
      FreeTierOnly  = "true"
      CostOptimized = "true"

      # Operational Tags
      DeployedBy      = "GitLab-CI"
      Repository      = "github.com/your-username/aws-devsecops-pipeline"  # Replace
      MonitoringLevel = "basic"
      AlertsEnabled   = "false"
    }
  }
}

# ============== DATA SOURCES ==============

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ============== LOCALS ==============

locals {
  # Use workspace name as environment (dev, staging, prod)
  # Falls back to var.environment for default workspace
  environment = terraform.workspace == "default" ? var.environment : terraform.workspace
}

# ============== S3 BUCKET (SECURE) ==============

# Main application bucket
resource "aws_s3_bucket" "app" {
  bucket        = "${var.project_name}-${local.environment}-${data.aws_caller_identity.current.account_id}"
  force_destroy = true # Allow destroy even with objects (for learning project)

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
  bucket        = "${var.project_name}-logs-${local.environment}-${data.aws_caller_identity.current.account_id}"
  force_destroy = true # Allow destroy even with objects (for learning project)

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
