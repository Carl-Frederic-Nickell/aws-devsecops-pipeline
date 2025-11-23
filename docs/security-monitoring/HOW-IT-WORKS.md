# AWS Security Monitoring - How It Works

Complete technical explanation of the security monitoring architecture.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                         AWS Account 123456789012                     │
│                         Region: eu-central-1                         │
└─────────────────────────────────────────────────────────────────────┘
                                    │
        ┌───────────────────────────┼───────────────────────────┐
        │                           │                           │
        ▼                           ▼                           ▼
┌───────────────┐          ┌────────────────┐         ┌─────────────────┐
│   CloudTrail  │          │  IAM Access    │         │   EventBridge   │
│               │          │    Analyzer    │         │                 │
│  All API Logs │          │                │         │  Daily Schedule │
│               │          │  Policy Scans  │         │  (8 AM UTC)     │
└───────┬───────┘          └────────────────┘         └────────┬────────┘
        │                                                        │
        │ Log Events                                            │ Trigger
        ▼                                                        ▼
┌────────────────────────────────────────────────────────────────────┐
│                   CloudWatch Logs                                   │
│             /aws/cloudtrail/my-project                               │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │            5 Metric Filters (Pattern Matching)                │ │
│  ├──────────────────────────────────────────────────────────────┤ │
│  │  1. UnauthorizedAPICalls - AccessDenied errors              │ │
│  │  2. RootAccountUsage - Root user activity                    │ │
│  │  3. IAMPolicyChanges - Policy CRUD operations               │ │
│  │  4. SecurityGroupChanges - Firewall modifications           │ │
│  │  5. S3BucketPolicyChanges - Bucket policy changes           │ │
│  └──────────────────────────────────────────────────────────────┘ │
└────────────────────────┬───────────────────────────────────────────┘
                         │ Metrics
                         ▼
┌────────────────────────────────────────────────────────────────────┐
│                  CloudWatch Alarms (5)                              │
│                                                                     │
│  Each alarm monitors its metric and triggers when threshold met:    │
│  - UnauthorizedAPICalls > 1                                        │
│  - RootAccountUsage > 0                                             │
│  - IAMPolicyChanges > 0                                             │
│  - SecurityGroupChanges > 0                                         │
│  - S3BucketPolicyChanges > 0                                        │
└────────────────────────┬───────────────────────────────────────────┘
                         │ Alert
                         ▼
┌────────────────────────────────────────────────────────────────────┐
│                   SNS Topic                                         │
│         my-project-security-alerts                                    │
│                                                                     │
│  Subscription: security@example.com                                │
│  Encryption: KMS (my-project-terraform key)                          │
└────────────────────────┬───────────────────────────────────────────┘
                         │ Email
                         ▼
                    security@example.com
                    (Real-time Alerts)


┌────────────────────────────────────────────────────────────────────┐
│              Lambda Security Monitor (Daily Checks)                 │
│            my-project-security-monitor                                │
│                                                                     │
│  Triggered by: EventBridge (daily at 8 AM UTC)                     │
│  Runtime: Python 3.11                                               │
│  Timeout: 60 seconds                                                │
│                                                                     │
│  Security Checks:                                                   │
│  1. IAM Access Analyzer findings (HIGH severity)                   │
│  2. S3 buckets without public access blocks (HIGH)                 │
│  3. Security groups with 0.0.0.0/0 ingress (MEDIUM)               │
│  4. IAM users without MFA (MEDIUM)                                 │
│                                                                     │
│  Output: Daily report + SNS alert if critical findings            │
└────────────────────────┬───────────────────────────────────────────┘
                         │ Daily Email
                         ▼
                    security@example.com
                    (Daily Summary)
```

---

## Component Deep Dive

### 1. CloudTrail Log Collection

**What it does**: Records all AWS API calls made in the account

**How it works**:
- Every API call (console, CLI, SDK) is logged
- Logs stored in S3 bucket `my-project-cloudtrail-123456789012`
- Also sent to CloudWatch Logs `/aws/cloudtrail/my-project`
- Encrypted with KMS key `my-project-cloudtrail`

**Example log entry**:
```json
{
  "eventTime": "2025-11-23T18:30:00Z",
  "eventName": "PutBucketPolicy",
  "userIdentity": {
    "type": "IAMUser",
    "userName": "carl-admin"
  },
  "requestParameters": {
    "bucketName": "my-bucket",
    "policy": "..."
  }
}
```

---

### 2. CloudWatch Log Metric Filters

**What they do**: Parse CloudTrail logs and create metrics when patterns match

**How they work**:
1. Each filter watches the CloudTrail log group
2. Uses JSON pattern matching to detect specific events
3. When pattern matches, increments a CloudWatch metric
4. Metrics are checked by alarms every 5 minutes

**Example: Unauthorized API Calls Filter**
```hcl
pattern = "{ ($.errorCode = \"*UnauthorizedOperation\") || ($.errorCode = \"AccessDenied*\") }"
```

This matches any log entry where:
- `errorCode` contains "UnauthorizedOperation", OR
- `errorCode` starts with "AccessDenied"

**When it triggers**:
```json
{
  "eventName": "DescribeInstances",
  "errorCode": "UnauthorizedOperation",
  "errorMessage": "You are not authorized to perform this operation"
}
```
↓
Creates metric data point: `UnauthorizedAPICalls = 1`

---

### 3. CloudWatch Alarms

**What they do**: Monitor metrics and send SNS notifications when thresholds are breached

**How they work**:
1. Alarm checks metric every 5 minutes (period = 300 seconds)
2. Compares metric value to threshold
3. If threshold exceeded, changes state from OK → ALARM
4. When state changes to ALARM, publishes to SNS topic

**Example: Root Account Usage Alarm**
```hcl
metric_name = "RootAccountUsage"
threshold   = 0          # Any value greater than 0
statistic   = "Sum"      # Total count in 5-minute window
```

**State Transitions**:
```
INSUFFICIENT_DATA → OK → ALARM → OK
        ↓            ↓      ↓
     No data    No events  Event!
                           Send SNS!
```

**Email format**:
```
Subject: ALARM: "my-project-root-usage" in EU (Frankfurt)

You are receiving this email because your Amazon CloudWatch Alarm
"my-project-root-usage" in the EU (Frankfurt) region has entered the
ALARM state.

Alarm Details:
- Alarm Name: my-project-root-usage
- Description: Detects root account usage
- State Change: OK -> ALARM
- Reason: Threshold Crossed: 1 datapoint (1.0) was greater than threshold (0.0)
```

---

### 4. IAM Access Analyzer

**What it does**: Continuously analyzes IAM policies to identify resources shared with external entities

**How it works**:
1. Scans all IAM policies, S3 bucket policies, KMS key policies, etc.
2. Identifies policies that grant access to principals outside the account
3. Creates findings when external access is detected
4. Continuously monitors for new or modified policies

**Finding Example**:
```json
{
  "id": "a1b2c3d4-5678-90ab-cdef-EXAMPLE",
  "status": "ACTIVE",
  "resourceType": "AWS::S3::Bucket",
  "resource": "arn:aws:s3:::my-bucket",
  "principal": {
    "AWS": "*"
  },
  "action": ["s3:GetObject"],
  "condition": {},
  "analyzedAt": "2025-11-23T18:00:00Z"
}
```

**Accessed by Lambda**: Daily scan checks for active findings and includes them in report

---

### 5. Lambda Security Monitor

**What it does**: Runs comprehensive security checks daily and sends summary report

**Runtime**: Python 3.11, 128MB memory, 60-second timeout

**Execution flow**:

```python
def lambda_handler(event, context):
    findings = []

    # Check 1: IAM Access Analyzer
    analyzer_findings = check_iam_analyzer()
    findings.extend(analyzer_findings)

    # Check 2: S3 Public Access
    s3_findings = check_s3_public_buckets()
    findings.extend(s3_findings)

    # Check 3: Security Groups
    sg_findings = check_security_groups()
    findings.extend(sg_findings)

    # Check 4: IAM MFA
    mfa_findings = check_iam_mfa()
    findings.extend(mfa_findings)

    # Generate report
    report = generate_report(findings)

    # Send SNS alert if critical
    if has_critical_findings(findings):
        send_sns_alert(report)

    return {
        'statusCode': 200,
        'body': {
            'findings_count': len(findings),
            'critical_findings': count_critical(findings)
        }
    }
```

**IAM Permissions Required**:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "access-analyzer:ListFindings",    // Read analyzer results
        "s3:ListAllMyBuckets",             // List S3 buckets
        "s3:GetBucketPublicAccessBlock",   // Check S3 config
        "ec2:DescribeSecurityGroups",      // Read security groups
        "iam:ListUsers",                   // List IAM users
        "iam:ListMFADevices"               // Check MFA status
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "sns:Publish",
      "Resource": "arn:aws:sns:eu-central-1:123456789012:my-project-security-alerts"
    }
  ]
}
```

**Environment Variables**:
- `SNS_TOPIC_ARN`: Where to send alerts
- `IAM_ANALYZER_ARN`: Which analyzer to check
- `PROJECT_PREFIX`: Resource naming prefix

---

### 6. EventBridge Daily Schedule

**What it does**: Triggers Lambda function once per day

**Schedule**: `cron(0 8 * * ? *)`
- Minute: 0
- Hour: 8 (UTC, 9 AM CET, 10 AM CEST)
- Day of month: * (every day)
- Month: * (every month)
- Day of week: ? (don't care)
- Year: * (every year)

**How it works**:
1. EventBridge evaluates cron expression every minute
2. At 8:00 AM UTC, rule matches
3. Rule invokes Lambda function `my-project-security-monitor`
4. Lambda executes security checks
5. Returns findings and sends email if needed

---

## Data Flow Examples

### Scenario 1: Root Account Login (Real-time Alert)

```
1. User logs in with root account
   ↓
2. CloudTrail logs event:
   {
     "eventName": "ConsoleLogin",
     "userIdentity": { "type": "Root" }
   }
   ↓
3. Event written to CloudWatch Logs
   ↓
4. Metric filter matches pattern:
   "{ $.userIdentity.type = \"Root\" }"
   ↓
5. Metric RootAccountUsage increments to 1
   ↓
6. CloudWatch Alarm detects: 1 > 0 (threshold)
   ↓
7. Alarm state changes: OK → ALARM
   ↓
8. SNS publishes notification
   ↓
9. Email sent to security@example.com

Time: < 5 minutes from login to email
```

### Scenario 2: Daily Security Report

```
1. EventBridge: It's 8:00 AM UTC
   ↓
2. EventBridge invokes Lambda function
   ↓
3. Lambda starts execution
   ↓
4. Check 1: Call IAM Access Analyzer
   └─> No active findings

5. Check 2: List S3 buckets
   ├─> my-project-cloudtrail-123456789012
   │   └─> Has all public access blocks ✓
   ├─> my-project-terraform-state-123456789012
   │   └─> Has all public access blocks ✓
   └─> my-project-logging-123456789012
       └─> Has all public access blocks ✓

6. Check 3: Describe security groups
   └─> No groups with 0.0.0.0/0 ingress

7. Check 4: List IAM users + MFA devices
   ├─> carl-admin
   │   └─> MFA enabled ✓
   └─> No users without MFA

8. Generate report:
   ========================================
   AWS SECURITY MONITOR REPORT
   ========================================
   Total Findings: 0
   Critical Findings: 0
   ========================================
   ✅ No security issues detected!

9. No critical findings → Skip SNS alert

10. Return success:
    {
      "statusCode": 200,
      "findings_count": 0,
      "critical_findings": 0
    }

Time: ~5-10 seconds
```

### Scenario 3: Security Group Modified (Real-time + Daily)

```
Real-time Detection:
1. User modifies security group via Console
   ↓
2. CloudTrail logs: AuthorizeSecurityGroupIngress
   ↓
3. Metric filter matches
   ↓
4. SecurityGroupChanges metric = 1
   ↓
5. Alarm triggers
   ↓
6. Email sent immediately

Daily Detection (next morning):
1. Lambda runs at 8 AM UTC
   ↓
2. Describes all security groups
   ↓
3. Finds rule: 0.0.0.0/0 on port 22
   ↓
4. Creates finding:
   {
     "type": "SECURITY_GROUP_OPEN",
     "severity": "MEDIUM",
     "resource": "sg-abc123",
     "description": "Security group allows 0.0.0.0/0 on port 22"
   }
   ↓
5. Report includes finding
   ↓
6. Not critical (MEDIUM severity) → No SNS alert
   ↓
7. Finding logged to CloudWatch Logs for review
```

---

## Cost Breakdown

### Why $0.00/month?

**IAM Access Analyzer**:
- Always free, no usage limits
- Cost: $0

**CloudWatch Logs**:
- First 5GB ingestion/month: FREE
- CloudTrail generates ~100MB/month (well under 5GB)
- 7-day retention (minimal storage)
- Cost: $0

**CloudWatch Metric Filters**:
- No charge for metric filters
- Cost: $0

**CloudWatch Alarms**:
- First 10 standard alarms: FREE
- We have 7 alarms total (5 security + 2 billing)
- Cost: $0

**Lambda**:
- 1M requests/month: FREE
- 400,000 GB-seconds compute: FREE
- We run 30 times/month (0.003% of free tier)
- Each run: 60 seconds × 0.128GB = 7.68 GB-seconds
- Monthly: 30 × 7.68 = 230.4 GB-seconds (0.06% of free tier)
- Cost: $0

**CloudWatch Logs (Lambda)**:
- Logs from Lambda execution
- ~1KB per execution = 30KB/month (negligible)
- Cost: $0

**SNS**:
- First 1,000 email notifications: FREE
- Expected: ~60 emails/month (6% of free tier)
- Cost: $0

**EventBridge**:
- All AWS service events: FREE
- Cost: $0

**Total**: $0.00/month indefinitely

---

## Security Considerations

### Defense in Depth
- **Layer 1**: CloudTrail captures all API activity
- **Layer 2**: Metric filters detect suspicious patterns
- **Layer 3**: Alarms provide real-time alerts
- **Layer 4**: Lambda performs comprehensive daily scans
- **Layer 5**: IAM Access Analyzer continuously monitors policies

### Least Privilege
- Lambda IAM role has minimal permissions (read-only security checks)
- No write permissions to modify resources
- SNS publish limited to single topic

### Encryption
- CloudTrail logs encrypted with KMS
- SNS topic encrypted with KMS
- Lambda environment variables encrypted at rest

### Monitoring Gaps (Intentional)
**Not Monitored** (would cost money):
- GuardDuty (intelligent threat detection): $0.50+/month
- AWS Config (resource configuration tracking): $0.003/rule/month
- Security Hub (centralized security findings): $0.0010/check/month
- VPC Flow Logs (network traffic): $0.50/GB

**Rationale**: FREE tier only, these services exceed budget

---

## Troubleshooting

### No Email Received

**Check 1**: SNS Subscription Status
```bash
aws sns list-subscriptions-by-topic \
  --topic-arn arn:aws:sns:eu-central-1:123456789012:my-project-security-alerts \
  --region eu-central-1
```

Look for `"SubscriptionArn": "arn:..."` (not "PendingConfirmation")

**Check 2**: Spam Folder
- Sender: no-reply@sns.amazonaws.com
- Subject: "AWS Notification - Subscription Confirmation" or "ALARM: ..."

**Check 3**: Alarm State
```bash
aws cloudwatch describe-alarms \
  --alarm-names my-project-root-usage \
  --region eu-central-1 \
  --query 'MetricAlarms[0].StateValue'
```

Should be "OK" (no events) or "ALARM" (event detected)

### Lambda Not Running

**Check 1**: EventBridge Target
```bash
aws events list-targets-by-rule \
  --rule my-project-security-monitor-daily \
  --region eu-central-1
```

Should show Lambda ARN as target

**Check 2**: Lambda Permissions
```bash
aws lambda get-policy \
  --function-name my-project-security-monitor \
  --region eu-central-1
```

Should include EventBridge as allowed principal

**Check 3**: Manual Test
```bash
aws lambda invoke \
  --function-name my-project-security-monitor \
  --region eu-central-1 \
  output.json && cat output.json
```

### Viewing Logs

**CloudWatch Logs (Lambda)**:
```bash
aws logs tail /aws/lambda/my-project-security-monitor \
  --since 1h \
  --format short \
  --region eu-central-1
```

**CloudTrail Events**:
```bash
aws logs tail /aws/cloudtrail/my-project \
  --since 10m \
  --format short \
  --region eu-central-1
```

---

## Comparison: Before vs After

### Before Security Monitoring

```
AWS Account
    │
    ├── CloudTrail (audit logs only)
    ├── Budget alerts (cost monitoring)
    └── Manual security reviews (infrequent)

Threats:
❌ Unauthorized API calls go unnoticed
❌ Root account usage not monitored
❌ IAM policy changes invisible
❌ Security group modifications undetected
❌ S3 public exposure risk
❌ No compliance automation
```

### After Security Monitoring

```
AWS Account
    │
    ├── CloudTrail (audit logs)
    ├── Budget alerts (cost)
    ├── IAM Access Analyzer (policy analysis)
    ├── 5 CloudWatch Alarms (real-time detection)
    ├── Lambda Security Monitor (daily scans)
    └── SNS Notifications (immediate alerts)

Protection:
✅ Unauthorized API calls → Immediate email
✅ Root account usage → Immediate email
✅ IAM policy changes → Immediate email
✅ Security group changes → Immediate email
✅ S3 exposure → Daily detection
✅ Automated compliance checks
✅ Comprehensive audit trail
✅ $0/month cost
```

---

## Future Enhancements (Not Implemented)

### Automated Remediation
```python
# Auto-fix example: Disable exposed S3 bucket
if finding['type'] == 'S3_PUBLIC_ACCESS':
    s3.put_public_access_block(
        Bucket=finding['bucket'],
        PublicAccessBlockConfiguration={
            'BlockPublicAcls': True,
            'IgnorePublicAcls': True,
            'BlockPublicPolicy': True,
            'RestrictPublicBuckets': True
        }
    )
```

**Why not implemented**: Requires careful testing, could break intentional public access

### Multi-Channel Notifications
- Slack webhook integration
- Microsoft Teams connector
- PagerDuty for on-call rotation

**Why not implemented**: SNS email sufficient for personal account

### Historical Trending
- Store findings in DynamoDB
- Track security posture over time
- Generate monthly reports

**Why not implemented**: CloudWatch Logs provide sufficient history

---

**Status**: ✅ Fully Operational
**Documentation**: Complete
**Next Review**: After first daily report (tomorrow 8 AM UTC)
