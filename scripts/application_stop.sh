#!/bin/bash
# application_stop.sh - Stop Flask app
echo "=== Executing APPLICATION_STOP hook ==="

pkill -f "gunicorn.*src.app:app" || echo "No gunicorn process found."
sleep 2

echo "=== APPLICATION_STOP hook finished ===