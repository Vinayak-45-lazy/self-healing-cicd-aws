#!/bin/bash
# before_install.sh - Executed by CodeDeploy before installing files

set -e

echo "=== Executing BEFORE_INSTALL hook ==="

# Update package repository and install dependencies
yum update -y
yum install -y python3-pip python3 curl

# Clean up deployment directory for fresh install
DEPLOY_DIR="/home/ec2-user/flask-app"
if [ -d "$DEPLOY_DIR" ]; then
    echo "Cleaning up existing installation: $DEPLOY_DIR"
    rm -rf "$DEPLOY_DIR"
fi

# Create target directory with correct ownership
mkdir -p "$DEPLOY_DIR"
chown -R ec2-user:ec2-user "$DEPLOY_DIR"

echo "=== BEFORE_INSTALL completed successfully ==="