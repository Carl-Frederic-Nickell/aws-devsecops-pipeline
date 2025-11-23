#!/bin/bash
# Package Lambda function for deployment

set -e

echo "Packaging Lambda security monitor..."

# Create temp directory
rm -rf lambda_package
mkdir -p lambda_package

# Copy Python file
cp security_monitor.py lambda_package/

# Create zip file
cd lambda_package
zip -r ../lambda_security_monitor.zip .
cd ..

# Cleanup
rm -rf lambda_package

echo "✅ Lambda package created: lambda_security_monitor.zip"
ls -lh lambda_security_monitor.zip
