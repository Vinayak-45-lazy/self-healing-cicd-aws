#!/bin/bash
# application_start.sh - Lifecycle script executed by AWS CodeDeploy to spin up the application
# This script configures a Python virtual environment, installs dependencies, 
# writes the systemd unit file, and starts the Flask app via Gunicorn under systemd.

set -e

echo "=== Executing APPLICATION_START hook ==="

DEPLOY_DIR="/home/ubuntu/flask-app"
VENV_DIR="$DEPLOY_DIR/venv"

# 1. Navigate to deployment folder and ensure ownership is correct
cd "$DEPLOY_DIR"
chown -R ubuntu:ubuntu "$DEPLOY_DIR"

# 2. Setup Python Virtual Environment as the ubuntu user
echo "Setting up Python virtual environment..."
sudo -u ubuntu python3 -m venv "$VENV_DIR"

# 3. Install requirements inside virtual environment
echo "Installing application dependencies..."
sudo -u ubuntu "$VENV_DIR/bin/pip" install --upgrade pip
sudo -u ubuntu "$VENV_DIR/bin/pip" install -r "$DEPLOY_DIR/requirements.txt"

# 4. Create systemd service unit file dynamically
echo "Creating systemd service file..."
cat <<EOF | sudo tee /etc/systemd/system/flaskapp.service > /dev/null
[Unit]
Description=Gunicorn production server running Flask Application
After=network.target

[Service]
User=ubuntu
WorkingDirectory=$DEPLOY_DIR
ExecStart=$VENV_DIR/bin/gunicorn --workers 3 --bind 0.0.0.0:8080 src.app:app
Restart=always
RestartSec=5
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=flaskapp

[Install]
WantedBy=multi-user.target
EOF

# 5. Reload systemd daemon, enable, and start service
echo "Reloading systemd and starting service..."
sudo systemctl daemon-reload
sudo systemctl enable flaskapp
sudo systemctl start flaskapp

echo "=== APPLICATION_START hook completed successfully ==="
