# Outputs for DevSecOps Pipeline Project

output "app_bucket_name" {
  description = "Name of the application S3 bucket"
  value       = aws_s3_bucket.app.id
}

output "app_bucket_arn" {
  description = "ARN of the application S3 bucket"
  value       = aws_s3_bucket.app.arn
}

output "logs_bucket_name" {
  description = "Name of the logs S3 bucket"
  value       = aws_s3_bucket.logs.id
}

output "region" {
  description = "AWS region where resources are deployed"
  value       = data.aws_region.current.name
}

output "account_id" {
  description = "AWS account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "security_features" {
  description = "Security features enabled on the bucket"
  value = {
    public_access_blocked = "All public access blocked"
    versioning            = "Enabled"
    encryption            = "AES256 (Server-side)"
    logging               = "Enabled (to logs bucket)"
    lifecycle_rules       = "Old versions deleted after 30 days"
  }
}
