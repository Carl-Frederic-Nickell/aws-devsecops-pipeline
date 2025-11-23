# AWS Security Monitoring - FREE Tier

Complete security monitoring stack for AWS using only FREE tier services.

**Cost**: $0.00/month (permanent)

---

## What's Included

This security monitoring solution provides:

**Real-time Alerts** (< 5 minutes):
- Unauthorized API calls detection
- Root account usage monitoring
- IAM policy change tracking
- Security group modifications
- S3 bucket policy changes

**Daily Security Scans** (automated):
- IAM Access Analyzer findings
- S3 public access detection
- Security group 0.0.0.0/0 rules
- IAM MFA compliance checks

---

## Architecture

```
CloudTrail → Metric Filters → CloudWatch Alarms → SNS → Email

EventBridge → Lambda (daily) → Security Checks → SNS → Email
```

**Components**:
- **1** IAM Access Analyzer (always FREE)
- **5** CloudWatch Metric Filters (FREE)
- **5** CloudWatch Alarms (first 10 FREE)
- **1** Lambda Function (1M requests/month FREE)
- **1** EventBridge Schedule (FREE)
- **1** SNS Topic (1,000 emails/month FREE)

**Total**: 19 AWS resources, $0.00/month

---

## Quick Start

### 1. Lambda Function

Deploy the security monitoring Lambda:

```bash
# Package the function
./package_lambda.sh

# Deploy via Terraform or AWS Console
# See DEPLOYMENT-GUIDE.md for detailed instructions
```

### 2. CloudWatch Alarms

The CloudWatch alarms monitor CloudTrail for suspicious activity:

- `UnauthorizedAPICalls` - AccessDenied errors
- `RootAccountUsage` - Root account activity
- `IAMPolicyChanges` - IAM policy modifications
- `SecurityGroupChanges` - Firewall changes
- `S3BucketPolicyChanges` - S3 policy updates

### 3. Daily Checks

Lambda runs at 8 AM UTC and checks:

1. IAM Access Analyzer active findings
2. S3 buckets without public access blocks
3. Security groups with 0.0.0.0/0 ingress
4. IAM users without MFA enabled

---

## Documentation

- **[DEPLOYMENT-GUIDE.md](./DEPLOYMENT-GUIDE.md)** - Complete deployment instructions
- **[HOW-IT-WORKS.md](./HOW-IT-WORKS.md)** - Architecture deep dive and data flows
- **[security_monitor.py](./security_monitor.py)** - Lambda function source code
- **[package_lambda.sh](./package_lambda.sh)** - Packaging script

---

## Features

✅ **100% FREE Tier** - No ongoing costs
✅ **Real-time Alerts** - Email notifications within 5 minutes
✅ **Daily Reports** - Automated security scans
✅ **Easy Deployment** - Terraform or manual via AWS Console
✅ **Comprehensive Coverage** - IAM, S3, network, accounts
✅ **No Maintenance** - Fully automated
✅ **Production Ready** - Battle-tested architecture

---

## Requirements

- AWS Account (FREE tier eligible)
- Email address for notifications
- Basic AWS knowledge (IAM, Lambda, CloudWatch)
- Optional: Terraform for Infrastructure as Code

---

## Security Checks

### Real-time (CloudWatch Alarms)

| Check | Detection Time | Severity |
|-------|---------------|----------|
| Unauthorized API calls | < 5 min | HIGH |
| Root account usage | < 5 min | HIGH |
| IAM policy changes | < 5 min | MEDIUM |
| Security group changes | < 5 min | MEDIUM |
| S3 policy changes | < 5 min | MEDIUM |

### Daily (Lambda Function)

| Check | Frequency | Severity |
|-------|-----------|----------|
| IAM Analyzer findings | Daily 8 AM UTC | HIGH/MEDIUM |
| S3 public exposure | Daily 8 AM UTC | HIGH |
| Open security groups | Daily 8 AM UTC | MEDIUM |
| IAM MFA compliance | Daily 8 AM UTC | MEDIUM |

---

## Cost Breakdown

**All FREE tier services**:

- IAM Access Analyzer: Always FREE
- CloudWatch Metric Filters: No charge
- CloudWatch Alarms: First 10 FREE (we use 5)
- Lambda: 1M requests/month FREE (we use 30/month)
- CloudWatch Logs: 5GB/month FREE (we use <100MB)
- SNS: 1,000 emails/month FREE (we send ~60)
- EventBridge: Service events always FREE

**Total**: $0.00/month indefinitely

---

## Example Alerts

### Real-time Alert (Root Login)
```
Subject: ALARM: "my-project-root-usage" in EU (Frankfurt)

Alarm: my-project-root-usage
State: ALARM
Reason: Threshold Crossed: 1 datapoint > 0.0

Time: 2025-11-23 18:30:00 UTC
```

### Daily Report (Clean)
```
Subject: Daily Security Report - No Issues

AWS SECURITY MONITOR REPORT
============================
Total Findings: 0
Critical Findings: 0
============================
✅ No security issues detected!

Timestamp: 2025-11-23 08:00:15 UTC
```

### Daily Report (Findings)
```
Subject: Daily Security Report - 2 Findings

AWS SECURITY MONITOR REPORT
============================
Total Findings: 2
Critical Findings: 1
============================

🔴 HIGH SEVERITY (1 finding):
  - [S3_PUBLIC_ACCESS] Bucket 'data-bucket' missing public access blocks

🟡 MEDIUM SEVERITY (1 finding):
  - [IAM_NO_MFA] User 'deploy-bot' does not have MFA enabled
```

---

## Portfolio Value

This implementation demonstrates:

**Technical Skills**:
- AWS security service configuration
- CloudWatch log metric filters (JSON pattern matching)
- Lambda serverless automation (Python + boto3)
- Event-driven architecture
- Infrastructure as Code (Terraform)
- Cost optimization strategies

**Security Principles**:
- Defense in depth
- Continuous monitoring
- Automated alerting
- Least privilege IAM
- Audit trail maintenance

---

## Next Steps

1. Read [DEPLOYMENT-GUIDE.md](./DEPLOYMENT-GUIDE.md) for setup instructions
2. Review [HOW-IT-WORKS.md](./HOW-IT-WORKS.md) to understand the architecture
3. Deploy to your AWS account
4. Configure email notifications
5. Wait for first daily report (next day 8 AM UTC)

---

## Support

For questions or issues:
- Check [DEPLOYMENT-GUIDE.md](./DEPLOYMENT-GUIDE.md) troubleshooting section
- Review [HOW-IT-WORKS.md](./HOW-IT-WORKS.md) for technical details
- Open an issue on GitHub

---

**Status**: Production Ready
**Maintenance**: Zero (fully automated)
**Cost**: FREE Forever

*Last Updated: November 2025*
