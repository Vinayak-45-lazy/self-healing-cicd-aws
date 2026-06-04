# Project Repository Folder Structure
Below is the complete file and directory layout for the Self-Healing CI/CD Deployment Engine repository.

```text
self-healing-flask-app/
├── appspec.yml                  # CodeDeploy instructions mapping source files and script hooks
├── buildspec.yml                # CodeBuild instructions to test, compile, and package the app
├── requirements.txt             # Python dependencies (Flask, Gunicorn, pytest)
│
├── src/                         # Flask Web Application Source Code
│   ├── app.py                   # Main Flask routes, health check API and configurations
│   ├── static/                  # Static assets folder
│   │   └── css/
│   │       └── style.css        # Premium, responsive dark mode CSS layout
│   └── templates/               # HTML UI pages
│       ├── base.html            # Main base HTML layout with standard header, nav, footer, & SEO meta tags
│       ├── home.html            # App home page displaying version and environment
│       └── about.html           # Technical overview page detailing self-healing steps
│
├── tests/                       # Automated Testing Suite
│   └── test_app.py              # Pytest file containing unit tests for health check & page rendering
│
├── scripts/                     # AWS CodeDeploy Hook Bash Scripts
│   ├── before_install.sh        # Dependency installation & environment cleanup
│   ├── application_stop.sh      # Halts the running Flask Gunicorn server
│   ├── application_start.sh     # Setups Python venv, Gunicorn service daemon & starts server
│   └── validate_service.sh      # Polls `/health` endpoint and prints journalctl error logs if validation fails
│
├── lambda/                      # AWS Lambda Automation Logic
│   └── self_healing_handler.py  # Python boto3 handler to capture failures, query, and rollback CodeDeploy
│
└── aws_setup/                   # Comprehensive Documentation & Setup Guides (Reference)
    ├── iam_policies.md          # IAM assume-role trust relationships & custom policies JSON
    ├── manual_infrastructure.md # AWS Console setup guide (VPC, Subnet, EC2, IAM, S3, Agent installation)
    ├── pipeline_setup_guide.md  # Continuous Integration & Deployment Pipeline guide (CodeBuild, CodeDeploy, CodePipeline)
    ├── self_healing_guide.md    # Guide for setting up SNS topic, Lambda trigger, CloudWatch alarm & EventBridge
    └── testing_self_healing.md  # Verification plan showing how to break the app and confirm auto-rollbacks
```
