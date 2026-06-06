"""
app.py - Main Flask Application Module
This file defines the routes, health checks, and configuration for our Python Flask Web App.
It runs on Python 3.9 and includes production-grade configurations.
"""

from flask import Flask, jsonify, render_template

app = Flask(__name__)

# Application version. This is critical for testing self-healing rollbacks.
# When we deploy a new version, this version will change.
APP_VERSION = "2.0.0-broken"

@app.route("/")
def home():
    """
    Home page route.
    Displays a welcome message, status, and the current version of the application.
    """
    return render_template("home.html", version=APP_VERSION)

@app.route("/about")
def about():
    """
    About page route.
    Provides info about the Self-Healing CI/CD Deployment Engine project.
    """
    return render_template("about.html")

@app.route("/health")
def health():
    """
    Health check endpoint.
    BROKEN VERSION - simulating failed deployment
    """
    response = {
        "status": "error",
        "version": APP_VERSION,
        "description": "BROKEN - deployment failed!"
    }
    return jsonify(response), 500

if __name__ == "__main__":
    # Host 0.0.0.0 makes the server accessible from outside the container/host.
    # Port 8080 is configured for non-root execution.
  app.run(host="0.0.0.0", port=5000, debug=False)
