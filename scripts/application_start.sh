#!/bin/bash
# application_start.sh - Start Flask app via Gunicorn (GitHub Actions compatible)
set -e
echo "=== Executing APPLICATION_START hook ==="

DEPLOY_DIR="/home/ec2-user/flask-app"
cd "$DEPLOY_DIR"

# Kill any existing gunicorn process
pkill -f "gunicorn.*src.app:app" || true
sleep 2

# Start gunicorn as daemon
echo "Starting Flask app with Gunicorn..."
/home/ec2-user/.local/bin/gunicorn \
  --workers 2 \
  --bind 0.0.0.0:5000 \
  --daemon \
  --pid /tmp/gunicorn.pid \
  --access-logfile /tmp/gunicorn-access.log \
  --error-logfile /tmp/gunicorn-error.log \
  src.app:app

sleep 3

# Verify it started
if curl -s http://localhost:5000/health > /dev/null; then
  echo "=== APPLICATION_START completed successfully ==="
else
  echo "ERROR: App failed to start"
  exit 1
fi