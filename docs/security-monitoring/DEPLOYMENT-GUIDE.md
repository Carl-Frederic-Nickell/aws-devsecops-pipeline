# AWS Security Monitoring - Deployment Complete

**Date**: November 23, 2025
**Status**: ✅ Fully Operational
**Cost**: $0.00/month (100% FREE tier)

---

## Deployment Summary

Successfully deployed a complete AWS security monitoring stack using FREE tier services only.

### Deployed Resources (19 total)

#### IAM Access Analyzer (1)
- **Analyzer**: `my-project-iam-analyzer`
- **Status**: ACTIVE
- **ARN**: `arn:aws:access-analyzer:eu-central-1:123456789012:analyzer/my-project-iam-analyzer`
- **Deployment**: Terraform
- **Cost**: Always FREE

#### CloudWatch Log Metric Filters (5)
- `my-project-unauthorized-api-calls` → Metric: `UnauthorizedAPICalls`
- `my-project-root-usage` → Metric: `RootAccountUsage`
- `my-project-iam-policy-changes` → Metric: `IAMPolicyChanges`
- `my-project-security-group-changes` → Metric: `SecurityGroupChanges`
- `my-project-s3-policy-changes` → Metric: `S3BucketPolicyChanges`
- **Deployment**: Terraform
- **Cost**: FREE

#### CloudWatch Alarms (5)
- `my-project-unauthorized-api-calls` (Threshold: > 1)
- `my-project-root-usage` (Threshold: > 0)
- `my-project-iam-policy-changes` (Threshold: > 0)
- `my-project-security-group-changes` (Threshold: > 0)
- `my-project-s3-policy-changes` (Threshold: > 0)
- **Deployment**: Terraform
- **Alert Target**: `my-project-security-alerts` SNS topic
- **Cost**: FREE (first 10 alarms)

#### Lambda Security Monitor (6 resources)
- **IAM Role**: `my-project-security-monitor-lambda`
- **IAM Policy**: `SecurityMonitorPermissions` (inline)
- **Lambda Function**: `my-project-security-monitor`
- **EventBridge Rule**: `my-project-security-monitor-daily`
- **EventBridge Target**: Connected to Lambda
- **Lambda Permission**: EventBridge invocation
- **Deployment**: AWS Console (root user) + CloudShell
- **Cost**: FREE (30 runs/month, within 1M free tier)

#### SNS Topic (1)
- **Topic**: `my-project-security-alerts`
- **Status**: Email subscription confirmed
- **Email**: security@example.com
- **Deployment**: Terraform (already existed)

#### EventBridge Schedule (1)
- **Rule**: `my-project-security-monitor-daily`
- **Schedule**: `cron(0 8 * * ? *)` - Daily at 8 AM UTC
- **Deployment**: Terraform

---

## Deployment Methods

### Terraform Deployment (13 resources)
Deployed via manual `terraform apply` with targeted resources:

```bash
cd /Users/carl/Node-1/git-repos-local/infra-aws-cloud/terraform/base-infrastructure

aws-vault exec personal -- terraform apply -auto-approve \
  -target=aws_accessanalyzer_analyzer.main \
  -target=aws_cloudwatch_log_metric_filter.unauthorized_api_calls \
  -target=aws_cloudwatch_log_metric_filter.root_usage \
  -target=aws_cloudwatch_log_metric_filter.iam_policy_changes \
  -target=aws_cloudwatch_log_metric_filter.security_group_changes \
  -target=aws_cloudwatch_log_metric_filter.s3_bucket_policy_changes \
  -target=aws_cloudwatch_metric_alarm.unauthorized_api_calls \
  -target=aws_cloudwatch_metric_alarm.root_usage \
  -target=aws_cloudwatch_metric_alarm.iam_policy_changes \
  -target=aws_cloudwatch_metric_alarm.security_group_changes \
  -target=aws_cloudwatch_metric_alarm.s3_bucket_policy_changes \
  -target=aws_cloudwatch_event_rule.security_monitor_daily
```

**Why targeted deployment?**
- IAM Account Password Policy resource had authentication errors
- Deployed only new security monitoring resources
- Avoided modifying existing infrastructure

### Manual Deployment (6 resources)
Lambda function and IAM role deployed manually due to IAM permission constraints on `carl-admin` user.

**Challenge**: Terraform deployment failed with:
```
Error: creating IAM Role (my-project-security-monitor-lambda):
operation error IAM: CreateRole, https response error StatusCode: 403,
RequestID: d77ab916-4938-4705-950c-3fc386a6fe09,
api error InvalidClientTokenId: The security token included in the request is invalid
```

**Solution**: Used AWS Console (root user) + CloudShell:

1. **IAM Role Creation** (AWS Console):
   - Created role: `my-project-security-monitor-lambda`
   - Attached managed policy: `AWSLambdaBasicExecutionRole`
   - Created inline policy: `SecurityMonitorPermissions`

2. **Lambda Function Deployment** (AWS CloudShell):
   ```bash
   # Upload lambda_security_monitor.zip to CloudShell

   # Create Lambda function
   aws lambda create-function \
     --function-name my-project-security-monitor \
     --runtime python3.11 \
     --role arn:aws:iam::123456789012:role/my-project-security-monitor-lambda \
     --handler security_monitor.lambda_handler \
     --zip-file fileb://lambda_security_monitor.zip \
     --timeout 60 \
     --region eu-central-1 \
     --environment 'Variables={SNS_TOPIC_ARN=arn:aws:sns:eu-central-1:123456789012:my-project-security-alerts,IAM_ANALYZER_ARN=arn:aws:access-analyzer:eu-central-1:123456789012:analyzer/my-project-iam-analyzer,PROJECT_PREFIX=my-project}'

   # Add EventBridge permission
   aws lambda add-permission \
     --function-name my-project-security-monitor \
     --statement-id AllowEventBridge \
     --action lambda:InvokeFunction \
     --principal events.amazonaws.com \
     --source-arn arn:aws:events:eu-central-1:123456789012:rule/my-project-security-monitor-daily \
     --region eu-central-1

   # Connect EventBridge to Lambda
   aws events put-targets \
     --rule my-project-security-monitor-daily \
     --targets Id=1,Arn=arn:aws:lambda:eu-central-1:123456789012:function:my-project-security-monitor \
     --region eu-central-1
   ```

---

## Security Monitoring Coverage

### Real-time CloudWatch Alarms
Monitor CloudTrail events and send immediate SNS alerts:

| Alarm | Metric | Detection | Response Time |
|-------|--------|-----------|---------------|
| Unauthorized API Calls | UnauthorizedAPICalls | AccessDenied/UnauthorizedOperation errors | < 5 minutes |
| Root Account Usage | RootAccountUsage | Any root account activity | < 5 minutes |
| IAM Policy Changes | IAMPolicyChanges | IAM policy CRUD operations | < 5 minutes |
| Security Group Changes | SecurityGroupChanges | Firewall rule modifications | < 5 minutes |
| S3 Bucket Policy Changes | S3BucketPolicyChanges | S3 policy/ACL changes | < 5 minutes |

### Daily Lambda Security Checks
Automated security scans running at 8 AM UTC:

1. **IAM Access Analyzer Findings**
   - Detects overly permissive IAM policies
   - Identifies external resource access
   - Severity: HIGH, MEDIUM, LOW

2. **S3 Public Access**
   - Lists all S3 buckets
   - Checks public access block configuration
   - Flags buckets without all 4 blocks enabled
   - Severity: HIGH

3. **Security Groups**
   - Scans all security groups
   - Detects 0.0.0.0/0 ingress rules
   - Reports overly permissive firewall rules
   - Severity: MEDIUM

4. **IAM MFA Compliance**
   - Lists all IAM users
   - Checks MFA device enrollment
   - Reports users without MFA
   - Severity: MEDIUM

---

## Testing & Verification

### Manual Lambda Test
```bash
aws lambda invoke \
  --function-name my-project-security-monitor \
  --region eu-central-1 \
  output.json

cat output.json
```

**Result**:
```json
{
  "statusCode": 200,
  "body": {
    "findings_count": 1,
    "critical_findings": 0,
    "timestamp": "2025-11-23T18:30:15.632603"
  }
}
```

### Verification Commands

**Check IAM Access Analyzer**:
```bash
aws-vault exec personal -- aws accessanalyzer list-analyzers --region eu-central-1
```

**List CloudWatch Alarms**:
```bash
aws-vault exec personal -- aws cloudwatch describe-alarms \
  --alarm-name-prefix "my-project-" \
  --region eu-central-1 \
  --query 'MetricAlarms[].{Name:AlarmName,State:StateValue,Metric:MetricName}' \
  --output table
```

**Check EventBridge Trigger**:
```bash
aws-vault exec personal -- aws events list-targets-by-rule \
  --rule my-project-security-monitor-daily \
  --region eu-central-1
```

**View Lambda Logs**:
```bash
aws-vault exec personal -- aws logs tail /aws/lambda/my-project-security-monitor \
  --since 1h \
  --format short \
  --region eu-central-1
```

---

## Files Created/Modified

### Code Files
- `security_monitor.py` - Lambda function (318 lines)
- `package_lambda.sh` - Lambda packaging script
- `lambda_security_monitor.zip` - Deployment package (2.5KB)

### Documentation
- `SECURITY-MONITORING-ADDED.md` - Initial documentation
- `SNS-CONFIGURATION.md` - SNS troubleshooting guide
- `DEPLOYMENT-SUMMARY.md` - Partial deployment summary
- `DEPLOYMENT-COMPLETE.md` - This file (final documentation)
- `fix_sns_subscription.sh` - SNS helper script

### Terraform Configuration
- `main.tf` (lines 572-882) - Security monitoring resources:
  - IAM Access Analyzer
  - 5 CloudWatch metric filters
  - 5 CloudWatch alarms
  - Lambda IAM role and policy
  - Lambda function resource (not deployed via TF)
  - EventBridge rule and target
  - CloudWatch log group

---

## Cost Analysis

### Monthly Cost: $0.00

**Breakdown**:
- IAM Access Analyzer: $0 (always free)
- CloudWatch Metric Filters (5): $0 (no charge)
- CloudWatch Alarms (7 total): $0 (first 10 free)
- Lambda (30 invocations/month): $0 (within 1M free tier)
- Lambda execution time (60s × 30): $0 (within 400,000 GB-seconds free)
- CloudWatch Logs (7-day retention): $0 (minimal data, within 5GB free)
- SNS email notifications (~60/month): $0 (within 1,000 free)
- EventBridge rule: $0 (AWS service events free)

**Annual Cost**: $0.00 (remains within free tier permanently)

---

## Expected Email Alerts

| Alert Type | Frequency | Trigger | Severity |
|------------|-----------|---------|----------|
| Daily Security Report | 1/day | Lambda runs at 8 AM UTC | INFO |
| Critical Findings | As detected | HIGH severity issues | CRITICAL |
| Unauthorized API Calls | Real-time | AccessDenied errors | HIGH |
| Root Account Usage | Real-time | Root login/activity | HIGH |
| IAM Policy Changes | Real-time | Policy modifications | MEDIUM |
| Security Group Changes | Real-time | Firewall changes | MEDIUM |
| S3 Policy Changes | Real-time | Bucket policy changes | MEDIUM |

**Typical Volume**: 1-2 emails/day (unless security incidents detected)

---

## Lessons Learned

### IAM Permissions Challenge
**Issue**: `carl-admin` user lacked IAM role creation permissions
**Error**: `InvalidClientTokenId: The security token included in the request is invalid`
**Root Cause**: Custom policy `my-project-lambda-deployment` was created, but aws-vault cached credentials didn't refresh
**Solution**: Used root account via AWS Console for IAM role, CloudShell for Lambda deployment

**Future Prevention**:
1. Grant `carl-admin` full IAM permissions upfront
2. Use `aws-vault clear` after IAM policy changes
3. Consider AWS SSO instead of IAM users for better credential management
4. Document required IAM permissions before deployment

### Region Confusion
**Issue**: Initially created Lambda in Stockholm (eu-north-1) instead of Frankfurt (eu-central-1)
**Impact**: EventBridge trigger couldn't connect (different regions)
**Solution**: Deleted Stockholm Lambda, recreated in Frankfurt
**Prevention**: Always verify region in AWS Console top-right corner

### AWS CLI Tag Syntax
**Issue**: CloudShell couldn't parse multi-line tag commands
**Error**: `Invalid type for parameter Tags.CostOptimized`
**Root Cause**: Line breaks splitting tag key-value pairs
**Solution**: Used single-line commands or skipped tags (added manually later)

---

## Portfolio Value

### Technical Skills Demonstrated
✅ AWS security service configuration
✅ CloudWatch log metric filter pattern matching (complex JSON queries)
✅ Lambda serverless automation (Python + boto3)
✅ Event-driven architecture (EventBridge scheduling)
✅ Infrastructure as Code (Terraform)
✅ AWS CLI scripting and CloudShell
✅ IAM policy design and troubleshooting
✅ Cost optimization (100% free tier architecture)
✅ Security monitoring best practices
✅ Documentation and knowledge sharing

### Security Principles Applied
✅ **Defense in Depth**: Multiple monitoring layers (real-time + daily)
✅ **Continuous Monitoring**: Automated security checks without manual intervention
✅ **Automated Response**: SNS alerts enable rapid incident response
✅ **Least Privilege**: Lambda IAM role has minimal required permissions
✅ **Audit Trail**: CloudWatch Logs retain security check results
✅ **Detection Coverage**: IAM, S3, network, and account security monitored

---

## Next Steps

### Immediate
- [x] Deploy security monitoring stack
- [x] Test Lambda function manually
- [x] Verify EventBridge trigger
- [x] Document deployment process
- [ ] Add tags to Lambda function (optional)
- [ ] Monitor for first daily report (tomorrow 8 AM UTC)

### Future Enhancements (Optional)
- [ ] Add GuardDuty integration (costs $0.50+/month, not free tier)
- [ ] Implement automated remediation (Lambda auto-fixes)
- [ ] Add Slack/Teams webhook notifications
- [ ] Create CloudWatch dashboard for security metrics
- [ ] Implement security findings database (DynamoDB)
- [ ] Add compliance checks (CIS benchmarks)

---

## Console URLs

**IAM Access Analyzer**:
https://eu-central-1.console.aws.amazon.com/access-analyzer/home?region=eu-central-1#/analyzer/my-project-iam-analyzer

**Lambda Function**:
https://eu-central-1.console.aws.amazon.com/lambda/home?region=eu-central-1#/functions/my-project-security-monitor

**CloudWatch Alarms**:
https://eu-central-1.console.aws.amazon.com/cloudwatch/home?region=eu-central-1#alarmsV2:

**Raptor Dashboard**:
https://eu-central-1.console.aws.amazon.com/cloudwatch/home?region=eu-central-1#dashboards:name=my-project-mission-control

**EventBridge Rules**:
https://eu-central-1.console.aws.amazon.com/events/home?region=eu-central-1#/rules

---

**Status**: ✅ Fully Operational
**Cost**: $0.00/month (100% FREE tier)
**Maintenance**: Zero (fully automated)
**Security Coverage**: Comprehensive (IAM, S3, network, accounts)

---

*Deployed: November 23, 2025*
*Region: eu-central-1 (Frankfurt)*
*Account: 123456789012*
*Infrastructure: AWS Free Tier Only*
