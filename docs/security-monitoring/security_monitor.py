"""
AWS Security Monitor Lambda Function
Performs daily security checks across AWS account (100% FREE tier)
"""

import json
import boto3
import os
from datetime import datetime

# Initialize AWS clients
iam_analyzer = boto3.client('accessanalyzer')
s3_client = boto3.client('s3')
ec2_client = boto3.client('ec2')
iam_client = boto3.client('iam')
sns_client = boto3.client('sns')

def lambda_handler(event, context):
    """
    Main Lambda handler - runs daily security checks
    """
    print(f"Starting security scan at {datetime.utcnow().isoformat()}")

    findings = []

    # Check 1: IAM Access Analyzer findings
    iam_findings = check_iam_analyzer()
    if iam_findings:
        findings.extend(iam_findings)

    # Check 2: S3 public buckets
    s3_findings = check_s3_public_buckets()
    if s3_findings:
        findings.extend(s3_findings)

    # Check 3: Security groups with 0.0.0.0/0
    sg_findings = check_security_groups()
    if sg_findings:
        findings.extend(sg_findings)

    # Check 4: IAM users without MFA
    mfa_findings = check_iam_mfa()
    if mfa_findings:
        findings.extend(mfa_findings)

    # Generate report
    report = generate_report(findings)
    print(report)

    # Send alert if critical findings
    if any(f['severity'] == 'HIGH' for f in findings):
        send_sns_alert(report, findings)

    return {
        'statusCode': 200,
        'body': json.dumps({
            'findings_count': len(findings),
            'critical_findings': len([f for f in findings if f['severity'] == 'HIGH']),
            'timestamp': datetime.utcnow().isoformat()
        })
    }


def check_iam_analyzer():
    """
    Check IAM Access Analyzer for active findings
    """
    findings = []
    analyzer_arn = os.environ.get('IAM_ANALYZER_ARN')

    try:
        response = iam_analyzer.list_findings(
            analyzerArn=analyzer_arn,
            filter={'status': {'eq': ['ACTIVE']}}
        )

        for finding in response.get('findings', []):
            findings.append({
                'type': 'IAM_ACCESS_ANALYZER',
                'severity': 'MEDIUM',
                'resource': finding.get('resource', 'Unknown'),
                'message': f"IAM policy allows external access: {finding.get('resourceType', 'Unknown')}"
            })

        print(f"IAM Access Analyzer: {len(findings)} active findings")

    except Exception as e:
        print(f"Error checking IAM Analyzer: {str(e)}")

    return findings


def check_s3_public_buckets():
    """
    Check for S3 buckets with public access
    """
    findings = []

    try:
        response = s3_client.list_buckets()

        for bucket in response.get('Buckets', []):
            bucket_name = bucket['Name']

            try:
                # Check public access block
                public_access = s3_client.get_public_access_block(Bucket=bucket_name)
                config = public_access['PublicAccessBlockConfiguration']

                if not all([
                    config.get('BlockPublicAcls'),
                    config.get('BlockPublicPolicy'),
                    config.get('IgnorePublicAcls'),
                    config.get('RestrictPublicBuckets')
                ]):
                    findings.append({
                        'type': 'S3_PUBLIC_ACCESS',
                        'severity': 'HIGH',
                        'resource': bucket_name,
                        'message': f"S3 bucket '{bucket_name}' does not have all public access blocks enabled"
                    })

            except s3_client.exceptions.NoSuchPublicAccessBlockConfiguration:
                findings.append({
                    'type': 'S3_PUBLIC_ACCESS',
                    'severity': 'HIGH',
                    'resource': bucket_name,
                    'message': f"S3 bucket '{bucket_name}' has no public access block configuration"
                })
            except Exception as e:
                if 'AccessDenied' not in str(e):
                    print(f"Error checking bucket {bucket_name}: {str(e)}")

        print(f"S3 Public Access: {len(findings)} findings")

    except Exception as e:
        print(f"Error checking S3 buckets: {str(e)}")

    return findings


def check_security_groups():
    """
    Check for security groups with overly permissive rules
    """
    findings = []

    try:
        response = ec2_client.describe_security_groups()

        for sg in response.get('SecurityGroups', []):
            sg_id = sg['GroupId']
            sg_name = sg.get('GroupName', 'Unknown')

            for rule in sg.get('IpPermissions', []):
                for ip_range in rule.get('IpRanges', []):
                    if ip_range.get('CidrIp') == '0.0.0.0/0':
                        from_port = rule.get('FromPort', 'All')
                        to_port = rule.get('ToPort', 'All')

                        # Only alert on dangerous ports
                        dangerous_ports = [22, 3389, 3306, 5432, 6379, 27017]
                        if from_port in dangerous_ports or to_port in dangerous_ports:
                            findings.append({
                                'type': 'SECURITY_GROUP_OPEN',
                                'severity': 'HIGH',
                                'resource': f"{sg_id} ({sg_name})",
                                'message': f"Security group allows 0.0.0.0/0 access on port {from_port}-{to_port}"
                            })

        print(f"Security Groups: {len(findings)} findings")

    except Exception as e:
        print(f"Error checking security groups: {str(e)}")

    return findings


def check_iam_mfa():
    """
    Check for IAM users without MFA enabled
    """
    findings = []

    try:
        response = iam_client.list_users()

        for user in response.get('Users', []):
            username = user['UserName']

            try:
                mfa_devices = iam_client.list_mfa_devices(UserName=username)

                if not mfa_devices.get('MFADevices'):
                    findings.append({
                        'type': 'IAM_NO_MFA',
                        'severity': 'MEDIUM',
                        'resource': username,
                        'message': f"IAM user '{username}' does not have MFA enabled"
                    })

            except Exception as e:
                print(f"Error checking MFA for user {username}: {str(e)}")

        print(f"IAM MFA: {len(findings)} findings")

    except Exception as e:
        print(f"Error checking IAM users: {str(e)}")

    return findings


def generate_report(findings):
    """
    Generate human-readable security report
    """
    project_prefix = os.environ.get('PROJECT_PREFIX', 'aws')

    report = f"""
========================================
AWS SECURITY MONITOR REPORT
========================================
Project: {project_prefix}
Timestamp: {datetime.utcnow().isoformat()}
Total Findings: {len(findings)}
Critical Findings: {len([f for f in findings if f['severity'] == 'HIGH'])}
========================================

"""

    if not findings:
        report += "✅ No security issues detected!\n"
    else:
        # Group by severity
        high = [f for f in findings if f['severity'] == 'HIGH']
        medium = [f for f in findings if f['severity'] == 'MEDIUM']

        if high:
            report += f"\n🔴 HIGH SEVERITY ({len(high)} findings):\n"
            for f in high:
                report += f"  - [{f['type']}] {f['message']}\n"

        if medium:
            report += f"\n🟡 MEDIUM SEVERITY ({len(medium)} findings):\n"
            for f in medium:
                report += f"  - [{f['type']}] {f['message']}\n"

    report += "\n========================================\n"
    return report


def send_sns_alert(report, findings):
    """
    Send SNS notification for critical findings
    """
    sns_topic_arn = os.environ.get('SNS_TOPIC_ARN')

    if not sns_topic_arn:
        print("SNS topic ARN not configured, skipping alert")
        return

    try:
        subject = f"🚨 AWS Security Alert - {len([f for f in findings if f['severity'] == 'HIGH'])} Critical Findings"

        sns_client.publish(
            TopicArn=sns_topic_arn,
            Subject=subject,
            Message=report
        )

        print(f"Alert sent to SNS topic: {sns_topic_arn}")

    except Exception as e:
        print(f"Error sending SNS alert: {str(e)}")


if __name__ == "__main__":
    # For local testing
    test_event = {}
    test_context = {}
    result = lambda_handler(test_event, test_context)
    print(json.dumps(result, indent=2))
