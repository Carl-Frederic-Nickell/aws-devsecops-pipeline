# Contributing to AWS DevSecOps Pipeline

Thank you for your interest in contributing! This project is designed for learning and collaboration.

## Ways to Contribute

### 🐛 Reporting Bugs

If you find a bug:

1. Check [existing issues](https://github.com/YOUR_USERNAME/aws-devsecops-pipeline/issues) first
2. Create a new issue with:
   - Clear title describing the problem
   - Steps to reproduce
   - Expected vs actual behavior
   - Your environment (OS, Terraform version, AWS region)
   - Relevant error messages or logs

### 💡 Suggesting Enhancements

We welcome suggestions for:

- Additional security configurations
- New security scanning tools
- Improved documentation
- Better error handling
- Performance optimizations

**Please open an issue first to discuss major changes!**

### 📝 Improving Documentation

Documentation improvements are always welcome:

- Fix typos or unclear wording
- Add examples or use cases
- Improve installation instructions
- Add troubleshooting tips
- Translate to other languages

### ✨ Adding Features

Before adding features:

1. Open an issue to discuss the feature
2. Wait for maintainer feedback
3. Fork the repository
4. Create a feature branch
5. Implement with tests
6. Submit pull request

## Development Setup

### Prerequisites

```bash
# Required
terraform >= 1.5.0
aws-cli >= 2.0
git

# Optional (for testing)
tfsec
checkov
trufflehog
```

### Local Development

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/aws-devsecops-pipeline.git
cd aws-devsecops-pipeline

# Create feature branch
git checkout -b feature/your-feature-name

# Make changes
# ...

# Test locally
cd terraform
terraform init
terraform validate
terraform plan

# Run security scans
tfsec .
checkov -d .
```

## Pull Request Process

### 1. Code Quality

- ✅ Run `terraform fmt -recursive` before committing
- ✅ Ensure `terraform validate` passes
- ✅ Run security scans (tfsec, checkov)
- ✅ Test your changes in a real AWS account
- ✅ Update documentation if needed

### 2. Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add CloudTrail integration
fix: correct S3 bucket naming issue
docs: improve installation instructions
refactor: simplify lifecycle configuration
test: add validation for bucket encryption
```

**Examples:**

- `feat: add KMS encryption option`
- `fix: resolve tfsec warning for public access`
- `docs: update QUICKSTART with troubleshooting section`
- `refactor: extract logging configuration to module`

### 3. Pull Request Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Refactoring

## Testing
- [ ] Tested locally with `terraform plan`
- [ ] Tested deployment to AWS
- [ ] Security scans pass (tfsec, checkov)
- [ ] No new warnings introduced

## Screenshots (if applicable)
Add screenshots of AWS Console showing deployed resources

## Checklist
- [ ] Code follows project style (`terraform fmt`)
- [ ] Documentation updated
- [ ] No sensitive data committed
- [ ] Tests pass
```

### 4. Review Process

1. Maintainer will review within 3-5 days
2. Address any feedback
3. Once approved, PR will be merged
4. You'll be added to contributors list!

## Security Guidelines

### ⚠️ NEVER Commit:

- AWS access keys or secret keys
- Account IDs (unless necessary for documentation)
- Private IP addresses
- Internal domain names
- Terraform state files (`.tfstate`)
- Credentials or passwords

### ✅ Always:

- Use example values in documentation
- Redact sensitive output in screenshots
- Run Trufflehog before committing
- Keep `.gitignore` up to date

## Code Style

### Terraform

```hcl
# Use meaningful resource names
resource "aws_s3_bucket" "app" {  # Good
  bucket = var.bucket_name
}

resource "aws_s3_bucket" "bucket1" {  # Bad
  bucket = "my-bucket"
}

# Add descriptive comments
# Server-side encryption with AES256 (free tier)
resource "aws_s3_bucket_server_side_encryption_configuration" "app" {
  # ...
}

# Use variables for configurable values
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

# Format code before committing
# Run: terraform fmt -recursive
```

### Documentation

- Use clear, concise language
- Include code examples
- Add troubleshooting sections
- Keep README up to date

## Testing Checklist

Before submitting a PR, test:

- [ ] `terraform init` works
- [ ] `terraform validate` passes
- [ ] `terraform plan` shows expected resources
- [ ] `terraform apply` succeeds
- [ ] Resources created in AWS Console
- [ ] Security controls verified (encryption, versioning, etc.)
- [ ] `terraform destroy` cleans up successfully
- [ ] Security scans pass (tfsec, checkov)
- [ ] No secrets detected (trufflehog)
- [ ] GitLab CI/CD pipeline passes (if applicable)

## Questions or Help?

- 💬 [Open a Discussion](https://github.com/YOUR_USERNAME/aws-devsecops-pipeline/discussions)
- 📧 Email: mail@carl-cyber.tech
- 🌐 Website: [carl-cyber.tech](https://carl-cyber.tech)

## Code of Conduct

### Our Standards

- Be respectful and inclusive
- Welcome newcomers
- Provide constructive feedback
- Focus on learning and collaboration

### Unacceptable Behavior

- Harassment or discrimination
- Trolling or insulting comments
- Publishing others' private information
- Spam or self-promotion

## Recognition

Contributors will be recognized in:

- README contributors section
- GitHub contributors graph
- Release notes (for significant contributions)

Thank you for helping make this project better! 🚀
