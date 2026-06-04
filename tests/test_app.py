"""
test_app.py - Unit tests for the Flask Web Application
These tests are executed during the AWS CodeBuild phase to ensure code quality
before packaging and deployment.
"""

import json
import pytest
from src.app import app

@pytest.fixture
def client():
    """
    Configures the Flask app for testing.
    Creates a test client that can simulate requests to the application.
    """
    app.config["TESTING"] = True
    with app.test_client() as client:
        yield client

def test_home_page(client):
    """
    Verifies that the home page loads successfully and contains expected text.
    """
    response = client.get("/")
    assert response.status_code == 200
    assert b"App is running" in response.data
    assert b"Version" in response.data

def test_about_page(client):
    """
    Verifies that the about page loads successfully.
    """
    response = client.get("/about")
    assert response.status_code == 200
    assert b"About" in response.data

def test_health_check(client):
    """
    Verifies that the /health endpoint returns JSON status 'healthy' with HTTP 200.
    """
    response = client.get("/health")
    assert response.status_code == 200
    data = json.loads(response.data.decode("utf-8"))
    assert data["status"] == "healthy"
    assert "version" in data
