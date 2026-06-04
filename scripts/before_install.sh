#!/bin/bash
# before_install.sh - Lifecycle script executed by AWS CodeDeploy before installing files
# This script ensures dependencies like python3-venv are present and cleans up old installation folders.

set -e

echo "=== Executing BEFORE_INSTALL hook ==="

# Update package repository list and ensure Python virtualenv package is installed
apt-get update -y
apt-get install -y python3-pip python3-venv curl

# Clean up the deployment directory if it exists to ensure a clean slate,
# but keep the logs folder if required (optional)
DEPLOY_DIR="/home/ubuntu/flask-app"
if [ -d "$DEPLOY_DIR" ]; then
    echo "Cleaning up existing installation folder: $DEPLOY_DIR"
    rm -rf "$DEPLOY_DIR"
fi

# Ensure target directories exist and are owned by the ubuntu user
mkdir -p "$DEPLOY_DIR"
chown -R ubuntu:ubuntu "$DEPLOY_DIR"

echo "=== BEFORE_INSTALL hook finished successfully ==="
