#!/bin/bash
# application_start.sh - Start Flask app via Gunicorn

set -e

echo "=== Executing APPLICATION_START hook ==="

DEPLOY_DIR="/home/ec2-user/flask-app"
VENV_DIR="$DEPLOY_DIR/venv"

# Navigate to deployment folder
cd "$DEPLOY_DIR"
chown -R ec2-user:ec2-user "$DEPLOY_DIR"

# Setup Python Virtual Environment
echo "Setting up Python virtual environment..."
sudo -u ec2-user python3 -m venv "$VENV_DIR"

# Install requirements
echo "Installing dependencies..."
sudo -u ec2-user "$VENV_DIR/bin/pip" install --upgrade pip
sudo -u ec2-user "$VENV_DIR/bin/pip" install -r "$DEPLOY_DIR/requirements.txt"

# Create systemd service file
echo "Creating systemd service..."
cat <<EOF | sudo tee /etc/systemd/system/flaskapp.service > /dev/null
[Unit]
Description=Flask App running via Gunicorn
After=network.target

[Service]
User=ec2-user
WorkingDirectory=$DEPLOY_DIR
ExecStart=$VENV_DIR/bin/gunicorn --workers 3 --bind 0.0.0.0:5000 src.app:app
Restart=always
RestartSec=5
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=flaskapp

[Install]
WantedBy=multi-user.target
EOF

# Start service
echo "Starting Flask service..."
systemctl daemon-reload
systemctl enable flaskapp
systemctl start flaskapp

echo "=== APPLICATION_START completed successfully ==="