# AWS DevSecOps Pipeline - Secure S3 Infrastructure

> **Automated Infrastructure Deployment with Security Scanning and CI/CD**

A production-ready DevSecOps implementation demonstrating Infrastructure as Code (IaC) best practices, automated security scanning, and CI/CD deployment to AWS. This project showcases secure S3 bucket deployment with comprehensive security controls, automated testing, and continuous integration.

[![AWS](https://img.shields.io/badge/AWS-S3%20%7C%20IAM-orange)](https://aws.amazon.com/)
[![Terraform](https://img.shields.io/badge/Terraform-1.5%2B-blue)](https://www.terraform.io/)
[![Security](https://img.shields.io/badge/Security-tfsec%20%7C%20Checkov%20%7C%20Trufflehog-green)](https://github.com/aquasecurity/tfsec)
[![License](https://img.shields.io/badge/License-MIT-yellow)](LICENSE)

---

## 📋 Table of Contents

- [Overview](#overview)
- [Key Features](#key-features)
- [Architecture](#architecture)
- [Multi-Environment Setup](#multi-environment-setup)
- [Security Highlights](#security-highlights)
- [Pipeline Stages](#pipeline-stages)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Deployment Guide](#deployment-guide)
- [Cleanup & Destruction](#cleanup--destruction)
- [Implementation Challenges](#implementation-challenges)
- [Cost Analysis](#cost-analysis)
- [Lessons Learned](#lessons-learned)
- [Contributing](#contributing)

---

## 🎯 Overview

This project demonstrates a complete DevSecOps workflow for deploying secure cloud infrastructure to AWS. It was built to showcase:

- **Infrastructure as Code**: Terraform configuration following AWS Well-Architected Framework
- **Security Automation**: Integrated scanning with tfsec, Checkov, and Trufflehog
- **CI/CD Best Practices**: GitLab-based automation with manual approval gates
- **Production-Ready**: All resources configured with encryption, versioning, and access controls
- **Cost-Optimized**: 100% AWS Free Tier compatible

### Project Goals

1. ✅ Implement secure S3 storage following industry best practices
2. ✅ Automate infrastructure deployment with CI/CD pipeline
3. ✅ Integrate security scanning into development workflow
4. ✅ Demonstrate practical DevSecOps skills for portfolio/hiring
5. ✅ Maintain zero-cost operation within AWS Free Tier

---

## 🔑 Key Features

### Infrastructure Security
- **Server-side encryption** (AES-256) on all buckets
- **Versioning enabled** for data recovery and audit trails
- **Public access completely blocked** (4-level AWS protection)
- **Access logging** to dedicated logging bucket
- **Lifecycle policies** for cost optimization

### DevSecOps Pipeline
- **Automated validation** of Terraform syntax and formatting
- **Security scanning** with 3 industry-standard tools
- **Manual approval gates** preventing accidental deployments
- **Artifact management** for plan → apply workflow
- **Verification stage** confirming successful deployment

### Developer Experience
- **Clear documentation** with examples and troubleshooting
- **Reproducible deployments** via GitLab CI/CD or local execution
- **Modular design** allowing easy customization
- **Free Tier compatible** for learning and experimentation

---

## 🏗️ Architecture

### Infrastructure Diagram

```
┌──────────────────────────────────────────────────────────────┐
│                GitLab CI/CD Pipeline (Build-Time)            │
│  ┌──────────┐  ┌──────────┐  ┌──────┐  ┌───────┐  ┌──────┐   │
│  │ Validate │→ │  Security│→ │ Plan │→ │ Apply │→ │Verify│   │
│  │          │  │   Scan   │  │      │  │ Manual│  │      │   │
│  └──────────┘  └──────────┘  └──────┘  └───────┘  └──────┘   │
└──────────────────────────────────────────────────────────────┘
                             ↓ deploys
┌─────────────────────────────────────────────────────────────┐
│                         AWS Account                         │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  Application Infrastructure                           │  │
│  │  ┌──────────────────┐  ┌──────────────────┐           │  │
│  │  │ Application S3   │  │ Logs S3 Bucket   │           │  │
│  │  │ • AES-256        │→ │ • AES-256        │           │  │
│  │  │ • Versioned      │  │ • Versioned      │           │  │
│  │  │ • Public Blocked │  │ • Public Blocked │           │  │
│  │  └──────────────────┘  └──────────────────┘           │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  Security Monitoring Stack (Runtime - FREE)           │  │
│  │                                                       │  │
│  │  ┌─────────────┐    ┌──────────────────┐              │  │
│  │  │ CloudTrail  │───→│ CloudWatch Logs  │              │  │
│  │  │ (All APIs)  │    │ + Metric Filters │              │  │
│  │  └─────────────┘    └──────────────────┘              │  │
│  │                              ↓                        │  │
│  │  ┌─────────────────────────────────────────────────┐  │  │
│  │  │ Real-Time Alarms (< 5 min)                      │  │  │
│  │  │ • Unauthorized API calls                        │  │  │
│  │  │ • Root account usage                            │  │  │
│  │  │ • IAM/SG/S3 policy changes                      │  │  │
│  │  └─────────────────────────────────────────────────┘  │  │
│  │                              ↓                        │  │
│  │  ┌──────────────┐    ┌────────────────────────────┐   │  │
│  │  │ EventBridge  │───→│ Lambda Security Monitor    │   │  │
│  │  │ (Daily 8 AM) │    │ • IAM Access Analyzer      │   │  │
│  │  └──────────────┘    │ • S3 public buckets        │   │  │
│  │                      │ • Security groups 0.0.0.0  │   │  │
│  │  ┌──────────────┐    │ • IAM MFA compliance       │   │  │
│  │  │ IAM Access   │──→ │                            │   │  │
│  │  │ Analyzer     │    └────────────────────────────┘   │  │
│  │  └──────────────┘                ↓                    │  │
│  │                      ┌────────────────────────────┐   │  │
│  │                      │ SNS Topic                  │   │  │
│  │                      │ Email: security@example... │   │  │
│  │                      └────────────────────────────┘   │  │
│  │                                                       │  │
│  │  Cost: $0.00/month (19 resources, all FREE tier)      │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### Technology Stack

- **Infrastructure as Code**: Terraform 1.5+
- **Version Control**: Git / GitLab
- **CI/CD**: GitLab Runner with Docker executor
- **Security Scanning**: tfsec, Checkov, Trufflehog
- **Cloud Provider**: AWS
- **State Management**: S3 backend with DynamoDB locking

---

## 🌍 Multi-Environment Setup

This project demonstrates real-world multi-environment deployment using **Terraform Workspaces** with branch-based workflows.

### Environment Strategy

Three isolated environments with progressive deployment:

```
dev branch      → Dev Environment      (Auto-deploy, fast iteration)
                     ↓
staging branch  → Staging Environment  (Manual approval, full security scans)
                     ↓
main branch     → Production           (Strict approval, full security scans)
```

### Branch → Environment Mapping

| Branch | Workspace | Environment | Deployment | Security Scans |
|--------|-----------|-------------|------------|----------------|
| `dev` | `dev` | Development | Auto (on success) | ❌ Skipped (fast iteration) |
| `staging` | `staging` | Staging | Manual approval | ✅ Full scans (tfsec, checkov, trufflehog) |
| `main` | `prod` | Production | Strict manual approval | ✅ Full scans + warnings |

### Infrastructure Isolation

Each environment gets isolated infrastructure:

```
Workspace: dev
├── S3 Bucket: devsecops-dev-{ACCOUNT_ID}
└── S3 Logs: devsecops-logs-dev-{ACCOUNT_ID}

Workspace: staging
├── S3 Bucket: devsecops-staging-{ACCOUNT_ID}
└── S3 Logs: devsecops-logs-staging-{ACCOUNT_ID}

Workspace: prod
├── S3 Bucket: devsecops-prod-{ACCOUNT_ID}
└── S3 Logs: devsecops-logs-prod-{ACCOUNT_ID}
```

### State Management

Terraform automatically manages separate state files per workspace:
- **Dev**: `s3://YOUR-BUCKET/env:/dev/devsecops-pipeline/terraform.tfstate`
- **Staging**: `s3://YOUR-BUCKET/env:/staging/devsecops-pipeline/terraform.tfstate`
- **Prod**: `s3://YOUR-BUCKET/env:/prod/devsecops-pipeline/terraform.tfstate`

### Trade-off: Developer Velocity vs. Security

**Design Decision**: Skip security scans on dev branch

**Rationale**:
- Dev iteration: ~1 minute (validation only)
- Full security scan: ~4 minutes (validation + 3 scanners)
- Same code is scanned when promoted to staging/prod
- Real-world companies prioritize dev velocity with security gates at promotion points

**Security stance**: Not compromised—all production-bound code undergoes full scanning before reaching staging/prod.

---

## 🔒 Security Highlights

### Two-Layer Security Approach

#### Build-Time Security (CI/CD Pipeline)
- **tfsec, Checkov, Trufflehog**: Automated scanning before deployment
- **Manual approval gates**: Human review for production changes
- **Secret detection**: Prevents credential leaks

#### Runtime Security Monitoring (AWS)
**Complete FREE tier security stack deployed in base infrastructure:**

- ✅ **Real-time detection** (<5 min): CloudWatch alarms for unauthorized API calls, root usage, policy changes
- ✅ **Daily security scans**: Lambda function checking IAM policies, S3 public access, security groups, MFA compliance
- ✅ **IAM Access Analyzer**: Continuous policy scanning for external access
- ✅ **Email alerts**: SNS notifications for all security findings
- ✅ **Cost**: $0.00/month (19 resources, all FREE tier)

📚 **[Full Runtime Security Documentation →](docs/security-monitoring/README.md)**

### Implemented Controls

#### 1. S3 Bucket Security
- ✅ **Encryption at rest**: AES-256 server-side encryption
- ✅ **Versioning**: Enabled for both application and logs buckets
- ✅ **Public access blocking**: All 4 AWS public access settings enabled
- ✅ **Access logging**: Centralized logging to dedicated bucket
- ✅ **Lifecycle management**: Automatic cleanup of old versions (30 days)
- ✅ **Abort incomplete uploads**: Multipart uploads cleaned after 7 days

#### 2. Infrastructure Security
- ✅ **Remote state encryption**: Terraform state stored in encrypted S3 bucket
- ✅ **State locking**: DynamoDB table prevents concurrent modifications
- ✅ **No hardcoded credentials**: Uses environment variables and CI/CD secrets
- ✅ **Least privilege IAM**: Dedicated CI/CD user with minimal permissions
- ✅ **Resource tagging**: Compliance and cost tracking via tags

#### 3. Pipeline Security
- ✅ **Automated security scanning**: 3 tools validate every commit
- ✅ **Manual approval gates**: Production changes require human review
- ✅ **Secret detection**: Trufflehog scans for accidentally committed secrets
- ✅ **Policy compliance**: Checkov validates against security best practices

### Security Scan Results

| Scanner | Purpose | Result |
|---------|---------|--------|
| **tfsec** | Terraform-specific security checks | 18/19 passed* |
| **Checkov** | Policy compliance validation | Warnings accepted** |
| **Trufflehog** | Secret detection in repository | 0 secrets found ✅ |

*Intentionally using AWS-managed encryption (AES-256) instead of KMS to maintain Free Tier compliance.
**Policy warnings reviewed and documented; acceptable for learning/demo environment.

---

## 🔄 Pipeline Stages

### Stage 1: Validation
**Duration**: ~15 seconds
**Jobs**: `terraform:format`, `terraform:validate`

Validates Terraform syntax, formatting, and configuration structure. Provides fast feedback on code quality.

### Stage 2: Security Scan
**Duration**: ~30 seconds
**Jobs**: `tfsec:scan`, `checkov:scan`, `secrets:scan`

Runs three security scanners in parallel:
- **tfsec**: Terraform-specific security checks
- **Checkov**: Policy-as-code compliance validation
- **Trufflehog**: Secret detection across entire repository

### Stage 3: Plan
**Duration**: ~20 seconds
**Job**: `terraform:plan`

Generates infrastructure change plan, connects to AWS, and outputs detailed resource modifications. Creates plan artifact for apply stage.

### Stage 4: Apply (Manual)
**Duration**: ~40 seconds
**Job**: `terraform:apply`

**Requires manual approval** via GitLab UI. Applies infrastructure changes using pre-generated plan from previous stage.

### Stage 5: Verify
**Duration**: ~15 seconds
**Job**: `verify:deployment`

Confirms resources created successfully by checking:
- Bucket existence
- Encryption configuration
- Versioning status
- Public access blocks

### Stage 6: Destroy (Manual)
**Duration**: ~30 seconds
**Job**: `terraform:destroy`

**Manual trigger only**. Safely removes all infrastructure from AWS. Used for cost control and cleanup.

---

## ✅ Prerequisites

### Required Software
- **Terraform**: 1.5.0 or higher ([Download](https://www.terraform.io/downloads))
- **AWS CLI**: v2 ([Installation Guide](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html))
- **Git**: For version control
- **tfsec** (optional): For local security scanning

### AWS Account Requirements
- Personal AWS account (Free Tier eligible)
- IAM user with permissions for:
  - S3 (CreateBucket, PutObject, etc.)
  - IAM (for CI/CD user creation)
- AWS credentials configured locally:
  ```bash
  aws configure
  # Enter: Access Key ID, Secret Access Key, Region (e.g., us-east-1)
  ```

### For GitLab CI/CD (Optional)
- GitLab account with CI/CD access
- GitLab Runner configured (or use GitLab.com shared runners)
- CI/CD variables configured:
  - `AWS_ACCESS_KEY_ID` (masked, protected)
  - `AWS_SECRET_ACCESS_KEY` (masked, protected)
  - `AWS_DEFAULT_REGION` (e.g., `us-east-1`)

---

## 🚀 Quick Start

### 1. Clone Repository

```bash
git clone https://github.com/YOUR_USERNAME/aws-devsecops-pipeline.git
cd aws-devsecops-pipeline
```

### 2. Configure Backend

Update `terraform/main.tf` backend configuration with your S3 bucket:

```hcl
terraform {
  backend "s3" {
    bucket         = "YOUR-TERRAFORM-STATE-BUCKET"  # Replace this
    key            = "devsecops-pipeline/terraform.tfstate"
    region         = "us-east-1"                    # Your region
    dynamodb_table = "YOUR-TERRAFORM-LOCK-TABLE"   # Optional
    encrypt        = true
  }
}
```

**First-time setup?** Use local backend initially:
```hcl
# Comment out the backend "s3" block for first run
# After deploying state bucket, migrate to remote backend
```

### 3. Customize Variables (Optional)

Edit `terraform/terraform.tfvars` or use command-line variables:

```hcl
aws_region   = "us-east-1"       # Your preferred region
environment  = "dev"             # dev, staging, or prod
project_name = "devsecops"       # Your project identifier
```

### 4. Deploy Locally

```bash
cd terraform

# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Review planned changes
terraform plan

# Apply infrastructure
terraform apply
# Type 'yes' to confirm
```

### 5. Verify Deployment

```bash
# Check bucket creation
aws s3 ls | grep devsecops

# Verify encryption
aws s3api get-bucket-encryption --bucket devsecops-dev-YOUR-ACCOUNT-ID

# Verify versioning
aws s3api get-bucket-versioning --bucket devsecops-dev-YOUR-ACCOUNT-ID
```

---

## 📚 Deployment Guide

### Option A: Local Deployment (Recommended for Learning)

**Advantages**:
- Full control over each step
- Easier troubleshooting
- No CI/CD setup required

**Steps**: See [Quick Start](#quick-start) above

### Option B: GitLab CI/CD Deployment

**Advantages**:
- Automated security scanning
- Consistent deployments
- Manual approval gates
- Artifact management

**Setup**:

1. **Fork this repository** to your GitLab account

2. **Configure CI/CD variables** (Settings → CI/CD → Variables):
   - `AWS_ACCESS_KEY_ID`: Your AWS access key
   - `AWS_SECRET_ACCESS_KEY`: Your AWS secret key
   - `AWS_DEFAULT_REGION`: Your AWS region (e.g., `us-east-1`)

   ⚠️ **Important**: Enable "Masked" and "Protected" for credentials!

3. **Update backend configuration** in `terraform/main.tf`:
   ```hcl
   backend "s3" {
     bucket = "YOUR-STATE-BUCKET"
     key    = "devsecops-pipeline/terraform.tfstate"
     region = "us-east-1"
   }
   ```

4. **Push to trigger pipeline**:
   ```bash
   git add .
   git commit -m "feat: initial infrastructure deployment"
   git push origin main
   ```

5. **Monitor pipeline** in GitLab UI:
   - Validation and security scans run automatically
   - Review `terraform:plan` output
   - Click "Play" on `terraform:apply` to deploy
   - Verify stage confirms deployment

6. **Destroy when done**:
   - Navigate to pipeline in GitLab
   - Click "Play" on `terraform:destroy` job

### Troubleshooting

<details>
<summary><strong>Error: "Error loading state: AccessDenied"</strong></summary>

**Cause**: IAM user lacks S3 permissions for state bucket

**Solution**:
```bash
# Verify your AWS credentials
aws sts get-caller-identity

# Check state bucket exists and you have access
aws s3 ls s3://YOUR-STATE-BUCKET/
```
</details>

<details>
<summary><strong>Pipeline fails with "Terraform has no command named 'sh'"</strong></summary>

**Cause**: Docker entrypoint issue in GitLab CI

**Solution**: Ensure `.gitlab-ci.yml` has `entrypoint: [""]` for Terraform image:
```yaml
image:
  name: hashicorp/terraform:1.5.7
  entrypoint: [""]  # This is required!
```
</details>

<details>
<summary><strong>tfsec reports encryption warning</strong></summary>

**Explanation**: tfsec recommends KMS customer-managed keys over AWS-managed encryption

**Decision**: This project uses AES-256 (AWS-managed) to remain Free Tier compliant. For production, consider KMS.
</details>

---

## 🗑️ Cleanup & Destruction

### Infrastructure Lifecycle Management

This project demonstrates infrastructure lifecycle management with easy cleanup capabilities.

#### Destroy Environments

**Option 1: Via GitLab Pipeline (Recommended)**

Navigate to **GitLab → Pipelines → Select completed pipeline → Manual Actions**:

```bash
# Available destroy buttons per environment:
terraform:destroy:dev      # Destroys dev environment
terraform:destroy:staging  # Destroys staging environment
terraform:destroy:prod     # Destroys production environment
```

**Option 2: Via Terraform CLI (Local)**

```bash
cd terraform

# Select the workspace you want to destroy
terraform workspace select dev    # or staging, or prod

# Generate destroy plan and apply
terraform plan -destroy -out=destroy.tfplan
terraform show destroy.tfplan     # Review what will be destroyed
terraform apply destroy.tfplan    # Execute destruction

# Alternative: Direct destroy command
terraform destroy -auto-approve   # ⚠️ Use with caution!
```

#### What Gets Destroyed

When you destroy an environment workspace, the following resources are removed:

✅ Application S3 bucket (`devsecops-{env}-{account-id}`)
✅ Logs S3 bucket (`devsecops-logs-{env}-{account-id}`)
✅ All bucket configurations (encryption, versioning, logging)
✅ All objects in buckets (due to `force_destroy = true`)

#### What Remains

The following are NOT destroyed and remain shared across all projects:

🔒 Terraform state bucket (in S3)
🔒 DynamoDB state locking table
🔒 Your AWS account and IAM users/roles

### Cost Control Strategy

**Learning Project Pattern:**
- Deploy to dev/staging for learning and testing
- Destroy environments when not actively using
- Re-deploy anytime with `git push` to respective branch
- **Monthly cost when destroyed: $0.00**

---

## 🐛 Implementation Challenges & Solutions

### Real-World Issues Encountered

This section documents actual challenges faced during implementation and their solutions—valuable learning for anyone building similar infrastructure.

#### 1. Terraform Workspace Initialization Issue

**Problem**: `terraform init` prompted interactively for workspace selection in CI/CD pipelines, causing "EOF" errors.

**Solution**: Added `-input=false` flag and proper workspace selection sequencing:
```yaml
script:
  - WORKSPACE_NAME=${TF_WORKSPACE}
  - unset TF_WORKSPACE                    # Clear env var before init
  - terraform init -input=false           # Non-interactive init
  - terraform workspace select ${WORKSPACE_NAME} 2>/dev/null || terraform workspace new ${WORKSPACE_NAME}
  - export TF_WORKSPACE=${WORKSPACE_NAME} # Re-export after selection
```

**Learning**: CI/CD pipelines require non-interactive Terraform execution. Always use `-input=false`.

#### 2. Environment Variable Collision

**Problem**: All workspaces created buckets with "dev" naming because `var.environment` defaulted to "dev" for all workspaces, causing bucket name conflicts.

**Solution**: Implemented `local.environment` that maps directly to workspace name:
```hcl
locals {
  environment = terraform.workspace == "default" ? var.environment : terraform.workspace
}

# Use local.environment instead of var.environment
bucket = "${var.project_name}-${local.environment}-${data.aws_caller_identity.current.account_id}"
```

**Learning**: Workspace-specific logic requires locals, not just input variables.

#### 3. S3 Bucket Destruction Blocked by Versioning

**Problem**: Buckets with versioning couldn't be destroyed—`BucketNotEmpty` error even after deleting all visible objects.

**Solution**: Added `force_destroy = true` to bucket resources:
```hcl
resource "aws_s3_bucket" "app" {
  bucket        = "${var.project_name}-${local.environment}-${data.aws_caller_identity.current.account_id}"
  force_destroy = true  # Allows deletion with versioned objects
}
```

**Learning**: Versioned S3 buckets require `force_destroy` for easy cleanup in dev/learning environments. For production, remove this flag to prevent accidental data loss.

#### 4. CI/CD Variable Protection Issues

**Problem**: AWS credentials marked as "Protected" were only accessible to protected branches (main), blocking dev and staging pipelines.

**Solution**: Unprotected credentials while keeping them masked:
```bash
# In GitLab: Settings → CI/CD → Variables
AWS_ACCESS_KEY_ID: Masked=true, Protected=false
AWS_SECRET_ACCESS_KEY: Masked=true, Protected=false
```

**Learning**: CI/CD variable protection restricts branch access. For multi-environment workflows, use masked (hides value) rather than protected (restricts branches).

#### 5. Artifact Path Resolution in Multi-Stage Pipeline

**Problem**: Apply stage couldn't find plan artifacts (`tfplan-${TF_WORKSPACE}`) because `TF_WORKSPACE` was unset during init.

**Solution**: Re-export workspace variable after workspace selection:
```yaml
script:
  - WORKSPACE_NAME=${TF_WORKSPACE}
  - unset TF_WORKSPACE
  - terraform init -input=false
  - terraform workspace select ${WORKSPACE_NAME}
  - export TF_WORKSPACE=${WORKSPACE_NAME}  # Critical: Re-export
  - terraform apply -auto-approve tfplan-${TF_WORKSPACE}
```

**Learning**: Environment variable management across multi-step scripts requires explicit sequencing.

### Key Takeaways

1. **CI/CD is different from local development**: Non-interactive flags, explicit variable management
2. **Multi-environment adds complexity**: State isolation, variable scoping, naming conflicts
3. **Security vs. Usability**: Protected variables vs. branch accessibility
4. **Always plan for cleanup**: `force_destroy` for dev/learning, remove for production
5. **Document your journey**: Real-world challenges are valuable learning material

---

## 💰 Cost Analysis

### Monthly Cost Breakdown

| Resource | Usage | Monthly Cost |
|----------|-------|--------------|
| S3 Storage (both buckets) | < 1 GB | **$0.00** (Free Tier: 5 GB) |
| S3 PUT Requests | < 2,000 | **$0.00** (Free Tier: 2,000) |
| S3 GET Requests | < 20,000 | **$0.00** (Free Tier: 20,000) |
| Data Transfer Out | Minimal | **$0.00** (Free Tier: 100 GB) |
| **Total** | | **$0.00 per month** |

### Free Tier Limits (First 12 Months)

- **S3 Storage**: 5 GB (you'll use < 1%)
- **S3 Requests**: 20,000 GET, 2,000 PUT (you'll use < 5%)
- **Data Transfer**: 100 GB out per month (you'll use < 0.1%)

### Cost Optimization Features

✅ Lifecycle policy deletes old versions after 30 days
✅ Abort incomplete multipart uploads after 7 days
✅ No expensive services enabled (KMS, GuardDuty, etc.)
✅ Single-region deployment

⚠️ **Note**: Always enable **AWS Budget Alerts** to monitor costs!

```bash
# Set up a $1 budget alert (recommended)
aws budgets create-budget \
  --account-id YOUR-ACCOUNT-ID \
  --budget file://budget.json
```

---

## 🎓 Lessons Learned

### Technical Insights

#### 1. Docker Entrypoints in GitLab CI
Many Docker images have custom entrypoints that interfere with shell commands in CI/CD.

**Problem**: `Terraform has no command named "sh"`
**Solution**: Override entrypoint in `.gitlab-ci.yml`:
```yaml
image:
  name: hashicorp/terraform:1.5.7
  entrypoint: [""]  # Allows shell commands
```

#### 2. Terraform State Management
Remote state is crucial for team collaboration and prevents state corruption.

**Key learnings**:
- S3 + DynamoDB locking prevents concurrent modifications
- Always encrypt state files (contains sensitive data)
- Enable versioning on state bucket for recovery
- Use workspaces for multi-environment deployments

#### 3. Security Scanning Trade-offs
Perfect security scores aren't always practical or cost-effective.

**Example**:
- **tfsec** recommends KMS customer-managed keys
- **Trade-off**: KMS costs ~$1/month, AES-256 is free
- **Decision**: Document intentional exception for learning projects

#### 4. Manual Approval Gates
Prevent accidental infrastructure changes in production.

**Implementation**:
```yaml
terraform:apply:
  when: manual  # Requires clicking "Play" in GitLab UI
  needs:
    - terraform:plan  # Must complete successfully first
```

### DevSecOps Principles Applied

- **Shift Left Security**: Scan during development, not after deployment
- **Automation**: Everything reproducible via code and pipeline
- **Observability**: Comprehensive logging and verification stages
- **Fail Fast**: Early validation catches issues in seconds
- **Defense in Depth**: Multiple security layers (encryption, access control, logging, versioning)

### What I'd Do Differently

1. ~~**Start with workspaces** for multi-environment support~~ ✅ **Implemented!**
2. **Add Terraform modules** for better code reuse
3. **Implement policy-as-code** earlier (OPA/Sentinel)
4. **Use Terraform Cloud** for enhanced collaboration
5. **Add automated testing** (Terratest or kitchen-terraform)
6. **Implement GitOps** with ArgoCD or Flux for automated deployments

---

## 📸 Screenshots

### CI/CD Pipeline

#### Pipeline Overview
![Pipeline Success](screenshots/01-pipeline-success.png)
*Complete CI/CD pipeline with all stages passing (Validate → Security Scan → Plan → Apply → Verify)*

#### Pipeline Jobs Detail
![Pipeline Jobs](screenshots/02-pipeline-jobs-detail.png)
*Detailed view of all pipeline jobs and their execution status*

### Security Scanning

#### tfsec Scanner
![tfsec Results](screenshots/03-security-scan-tfsec.png)
*tfsec security scanner results - Terraform-specific security checks*

#### Checkov Scanner
![Checkov Results](screenshots/04-security-scan-checkov.png)
*Checkov policy compliance validation results*

### Terraform Execution

#### Terraform Plan
![Terraform Plan](screenshots/05-terraform-plan.png)
*Terraform plan output showing infrastructure changes before deployment*

#### Terraform Apply
![Terraform Apply](screenshots/06-terraform-apply.png)
*Terraform apply execution creating AWS resources*

#### Deployment Verification
![Verify Deployment](screenshots/07-verify-deployment.png)
*Automated verification stage confirming successful resource creation*

### AWS Console

#### S3 Buckets Overview
![S3 Buckets](screenshots/08-aws-s3-buckets.png)
*Deployed S3 buckets in AWS Console with security configurations*

#### Bucket Security Settings
![Bucket Security](screenshots/09-aws-bucket-security.png)
*Detailed security settings: encryption, versioning, public access blocking*

#### Logs Bucket
![Logs Bucket](screenshots/10-aws-logs-bucket.png)
*Dedicated logging bucket for access logs*

### GitLab Configuration

#### Project Structure
![GitLab Structure](screenshots/11-gitlab-project-structure.png)
*GitLab repository structure and organization*

#### CI/CD Variables
![CI/CD Variables](screenshots/12-gitlab-cicd-variables.png)
*GitLab CI/CD variables configuration (AWS credentials masked)*

#### Terraform Code
![Terraform Code](screenshots/13-terraform-code.png)
*Terraform infrastructure code with security best practices*

---

## 🤝 Contributing

Contributions are welcome! This project is designed for learning and experimentation.

### Ways to Contribute

- 🐛 **Report bugs** or security issues
- 💡 **Suggest improvements** to security configurations
- 📝 **Improve documentation** with clearer examples
- ✨ **Add features** like additional security tools or AWS services
- 🌍 **Translate** documentation to other languages

### Contribution Process

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/your-feature`)
3. Make your changes
4. Run security scans locally (`tfsec terraform/`)
5. Commit with clear messages (`git commit -m "feat: add X"`)
6. Push to your fork (`git push origin feature/your-feature`)
7. Open a Pull Request

---

## 📊 Project Statistics

- **Lines of Terraform**: ~250
- **Environments**: 3 (dev, staging, prod)
- **CI/CD Pipeline Jobs**: 27 (9 jobs × 3 environments)
- **Security Scanners**: 3 (tfsec, Checkov, Trufflehog)
- **AWS Resources Per Environment**: 12
- **Pipeline Execution Time**:
  - Dev: ~1 minute (fast path)
  - Staging/Prod: ~4 minutes (full security scans)
- **Cost Per Environment**: $0.00/month (Free Tier)

---

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👤 Author

**Carl-Frederic Nickell**
Security & DevOps Engineer | Ex-Bundeswehr | Production SIEM & CI/CD

- 🌐 Website: [carl-cyber.tech](https://carl-cyber.tech)
- 💼 LinkedIn: [Carl-Frederic Nickell](https://linkedin.com/in/carl-frederic-nickell)
- 🐙 GitHub: [@Carl-Frederic-Nickell](https://github.com/Carl-Frederic-Nickell)
- ✉️ Email: mail@carl-cyber.tech

---

## 🙏 Acknowledgments

- **HashiCorp** for Terraform and excellent documentation
- **Aqua Security** for tfsec scanner
- **Bridgecrew** for Checkov policy validation
- **Trufflehog** for secret detection
- **AWS** for Free Tier program enabling learning

---

## 🔗 Related Resources

### Official Documentation
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS S3 Security Best Practices](https://docs.aws.amazon.com/AmazonS3/latest/userguide/security-best-practices.html)
- [GitLab CI/CD](https://docs.gitlab.com/ee/ci/)

### Security Tools
- [tfsec](https://github.com/aquasecurity/tfsec)
- [Checkov](https://www.checkov.io/)
- [Trufflehog](https://github.com/trufflesecurity/trufflehog)

### Learning Resources
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [DevSecOps Manifesto](https://www.devsecops.org/)

---

**Project Status**: ✅ Complete & Production-Ready (Multi-Environment)
**Last Updated**: December 2025
**Environments**: Dev, Staging, Production
**AWS Region**: Configurable (default: us-east-1)

⭐ If this project helped you learn DevSecOps and multi-environment deployments, please consider starring the repository!

