#!/bin/bash
# application_stop.sh - Lifecycle script executed by AWS CodeDeploy before stopping the old app version
# This script safely stops the systemd service running our Flask application.

echo "=== Executing APPLICATION_STOP hook ==="

# Check if the systemd service exists and stop it
SERVICE_NAME="flaskapp"
if systemctl list-unit-files | grep -q "${SERVICE_NAME}.service"; then
    echo "Stopping existing systemd service: $SERVICE_NAME"
    sudo systemctl stop "$SERVICE_NAME" || echo "Service was not running."
else
    echo "Service $SERVICE_NAME.service does not exist yet. Skipping stop action."
fi

echo "=== APPLICATION_STOP hook finished ==="
