# Quick Start Guide

Get your DevSecOps pipeline running in 15 minutes!

## Prerequisites Checklist

Before you begin, ensure you have:

- [ ] AWS Account (Free Tier eligible)
- [ ] AWS CLI v2 installed and configured
- [ ] Terraform 1.5+ installed
- [ ] Git installed
- [ ] (Optional) GitLab account for CI/CD

## Option 1: Local Deployment (Fastest)

### Step 1: Clone and Configure

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/aws-devsecops-pipeline.git
cd aws-devsecops-pipeline/terraform

# Copy example variables
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your preferences
nano terraform.tfvars
```

### Step 2: Configure Backend (First-Time Only)

For your first deployment, comment out the S3 backend in `main.tf`:

```hcl
terraform {
  required_version = ">= 1.5.0"

  # Comment out for first run - use local backend
  # backend "s3" {
  #   bucket = "YOUR-TERRAFORM-STATE-BUCKET"
  #   ...
  # }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

### Step 3: Deploy!

```bash
# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Deploy infrastructure
terraform apply
# Type 'yes' when prompted
```

### Step 4: Verify

```bash
# List your buckets
aws s3 ls | grep devsecops

# Check encryption
aws s3api get-bucket-encryption --bucket devsecops-dev-YOUR-ACCOUNT-ID
```

**Success!** You now have:
- ✅ Encrypted S3 application bucket
- ✅ Encrypted S3 logs bucket
- ✅ Versioning enabled
- ✅ Public access blocked
- ✅ Access logging configured

### Step 5: Cleanup (When Done)

```bash
# Destroy all resources
terraform destroy
# Type 'yes' to confirm
```

---

## Option 2: GitLab CI/CD Deployment

### Step 1: Fork to GitLab

1. Create account on [GitLab.com](https://gitlab.com)
2. Create new project → Import from GitHub
3. Or manually push to GitLab:

```bash
git clone https://github.com/YOUR_USERNAME/aws-devsecops-pipeline.git
cd aws-devsecops-pipeline
git remote add gitlab https://gitlab.com/YOUR_USERNAME/aws-devsecops-pipeline.git
git push gitlab main
```

### Step 2: Create AWS IAM User for CI/CD

```bash
# Create IAM user
aws iam create-user --user-name gitlab-ci-devsecops

# Create access key
aws iam create-access-key --user-name gitlab-ci-devsecops

# Save the Access Key ID and Secret Access Key!
```

### Step 3: Attach Policy to User

Create `gitlab-ci-policy.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:*"
      ],
      "Resource": "*"
    }
  ]
}
```

Apply policy:

```bash
aws iam put-user-policy \
  --user-name gitlab-ci-devsecops \
  --policy-name S3FullAccess \
  --policy-document file://gitlab-ci-policy.json
```

### Step 4: Configure GitLab CI/CD Variables

In GitLab: **Settings → CI/CD → Variables**

Add these variables:

| Key | Value | Masked | Protected |
|-----|-------|--------|-----------|
| `AWS_ACCESS_KEY_ID` | `AKIA...` | ✅ | ✅ |
| `AWS_SECRET_ACCESS_KEY` | `secret...` | ✅ | ✅ |
| `AWS_DEFAULT_REGION` | `us-east-1` | ❌ | ❌ |

### Step 5: Update Backend Configuration

Edit `terraform/main.tf`:

```hcl
backend "s3" {
  bucket         = "YOUR-TERRAFORM-STATE-BUCKET"  # Create this first!
  key            = "devsecops-pipeline/terraform.tfstate"
  region         = "us-east-1"
  encrypt        = true
}
```

### Step 6: Trigger Pipeline

```bash
git add .
git commit -m "feat: configure for GitLab CI/CD"
git push gitlab main
```

### Step 7: Monitor Pipeline

1. Go to **CI/CD → Pipelines** in GitLab
2. Watch stages execute:
   - ✅ Validate (terraform format, validate)
   - ✅ Security Scan (tfsec, checkov, secrets)
   - ✅ Plan (shows what will be created)
   - ⏸️ Apply (click "Play" to deploy)
   - ✅ Verify (confirms deployment)

### Step 8: Destroy (When Done)

1. Go to latest pipeline
2. Click "Play" on `terraform:destroy` job
3. Confirm in job output

---

## Troubleshooting

### Error: "Backend initialization required"

```bash
cd terraform
terraform init -migrate-state
```

### Error: "AccessDenied: User is not authorized"

Check IAM user has correct permissions:

```bash
aws iam get-user-policy --user-name gitlab-ci-devsecops --policy-name S3FullAccess
```

### Error: "BucketAlreadyExists"

S3 bucket names must be globally unique. Change `project_name` in `terraform.tfvars`:

```hcl
project_name = "devsecops-yourname"  # Make it unique!
```

### Pipeline Fails: "Terraform has no command named 'sh'"

Ensure `.gitlab-ci.yml` has `entrypoint: [""]` in all Terraform image blocks.

---

## Next Steps

### Security Scanning (Local)

```bash
# Install tfsec
brew install tfsec  # macOS
# or download from https://github.com/aquasecurity/tfsec

# Run security scan
cd terraform
tfsec .
```

### Cost Monitoring

```bash
# Set up AWS Budget (recommended!)
aws budgets create-budget \
  --account-id $(aws sts get-caller-identity --query Account --output text) \
  --budget '{
    "BudgetName": "DevSecOps-Monthly",
    "BudgetLimit": {
      "Amount": "1",
      "Unit": "USD"
    },
    "TimeUnit": "MONTHLY",
    "BudgetType": "COST"
  }'
```

### Remote State Migration

After deploying your first state bucket, migrate from local to remote:

```bash
# 1. Uncomment backend "s3" block in main.tf
# 2. Run init with migration
terraform init -migrate-state

# 3. Confirm migration
# 4. Delete local terraform.tfstate files
```

---

## Learning Resources

- 📚 [Terraform AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- 🔒 [AWS S3 Security Best Practices](https://docs.aws.amazon.com/AmazonS3/latest/userguide/security-best-practices.html)
- 🚀 [GitLab CI/CD Tutorial](https://docs.gitlab.com/ee/ci/quick_start/)
- 🛡️ [tfsec Documentation](https://aquasecurity.github.io/tfsec/)

---

## Questions or Issues?

- 💬 [Open an Issue](https://github.com/YOUR_USERNAME/aws-devsecops-pipeline/issues)
- 📧 Email: mail@carl-cyber.tech
- 🌐 Website: [carl-cyber.tech](https://carl-cyber.tech)

Happy deploying! 🚀
