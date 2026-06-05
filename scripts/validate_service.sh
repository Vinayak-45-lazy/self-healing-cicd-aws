#!/bin/bash
# validate_service.sh - Lifecycle script executed by AWS CodeDeploy to verify health
# This script polls the /health JSON endpoint to ensure the app is responding correctly.

echo "=== Executing VALIDATE_SERVICE hook ==="

APP_PORT=5000
HEALTH_URL="http://localhost:${APP_PORT}/health"
MAX_ATTEMPTS=6
WAIT_SECONDS=5

echo "Testing health check endpoint: $HEALTH_URL"

for ((i=1; i<=MAX_ATTEMPTS; i++)); do
    echo "Attempt $i of $MAX_ATTEMPTS: Querying health check..."
    
    # Perform HTTP request to the health endpoint
    # -s: Silent mode
    # -f: Fail silently on server errors (HTTP 400+)
    # -o /dev/null: Discard response body
    # -w "%{http_code}": Print the HTTP status code
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$HEALTH_URL" || true)
    
    if [ "$HTTP_STATUS" -eq 200 ]; then
        # Double check if response content has the expected healthy status
        RESPONSE_CONTENT=$(curl -s "$HEALTH_URL")
        if echo "$RESPONSE_CONTENT" | grep -q '"status":\s*"healthy"'; then
            echo "SUCCESS: Flask application is healthy and running!"
            echo "Response: $RESPONSE_CONTENT"
            exit 0
        else
            echo "WARNING: Status code was 200, but health response content was unexpected: $RESPONSE_CONTENT"
        fi
    else
        echo "WARNING: App returned status code $HTTP_STATUS or connection failed."
    fi
    
    echo "Waiting $WAIT_SECONDS seconds before next check..."
    sleep $WAIT_SECONDS
done

echo "ERROR: Health check validation failed after $MAX_ATTEMPTS attempts."
echo "Checking service logs for troubleshooting:"
sudo journalctl -u flaskapp -n 20 --no-pager
exit 1
