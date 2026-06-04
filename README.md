# AWS Self-Healing CI/CD Deployment Engine

A production-grade, fault-tolerant Continuous Integration & Continuous Deployment (CI/CD) system built on AWS Free Tier. The pipeline automates code validation, testing, and deployment to an EC2 instance. It features a custom serverless **Self-Healing Automation Engine** using AWS Lambda and Amazon EventBridge. When a bad deployment release fails live health checks, the system intercepts the failure event, searches the CodeDeploy registry for the last known stable deployment ID, and programmatically triggers a zero-downtime rollback, notifying the DevOps team via Amazon SNS.

---

## 🏗️ System Architecture

```text
                       +--------------------------------------------------------+
                       |                        GitHub                          |
                       +---------------------------+----------------------------+
                                                   | Push to main
                                                   v
                       +--------------------------------------------------------+
                       |                   AWS CodePipeline                     |
                       +-----+---------------------+----------------------+-----+
                             |                     |                      |
                             | (Source)            | (Build)              | (Deploy)
                             v                     v                      v
                       +-----+-----+         +-----+-----+          +-----+-----+
                       |   GitHub  |         |   AWS     |          |   AWS     |
                       |  Webhook  |         | CodeBuild |          |CodeDeploy |
                       +-----------+         +-----+-----+          +-----+-----+
                                                   |                      |
                                                   | Pulls & tests        | Deploys using
                                                   v                      | lifecycle scripts
                                             +-----+-----+                v
                                             |  Artifact |          +-----+-----+
                                             |  S3 Bucket|          | AWS EC2   |
                                             +-----+-----+          | Host      |
                                                   ^                +-----+-----+
                                                   |                      |
                                                   +----------------------+
                                                                          |
                                                                          | Unhealthy Deploy?
                                                                          v
+------------------+         +---------------------+            +---------+---------+
|     SNS Email    |<--------+  AWS Lambda Engine  |<-----------+  Amazon EventBridge|
|    Notification  |  Alerts | (Get last stable ID &|   Triggers |  (Detects Failed  |
+------------------+         |  execute rollback)  |   on failure|  Deploy Status)   |
                             +---------------------+            +-------------------+
```

---

## 🛠️ Tech Stack

| Category | Technology | Usage Description |
| :--- | :--- | :--- |
| **Language** | Python 3.9 | Core application logic and Lambda functions |
| **Web Framework** | Flask (v2.2.5) | Web serving, routing, and JSON API interfaces |
| **WSGI Server** | Gunicorn (v20.1.0) | Production-ready HTTP server interface running Python app |
| **Service Manager** | Linux systemd | System service unit managing Gunicorn execution and logs |
| **Testing Suite** | pytest (v7.4.0) | Automated unit testing executed during CodeBuild phase |
| **CI/CD Pipeline** | AWS CodePipeline | Orchestrates automated source retrieval, builds, and deploys |
| **Build Engine** | AWS CodeBuild | Standard Linux container compiling, testing, and archiving artifacts |
| **Deployment Engine**| AWS CodeDeploy | Controls file installation, configures host, and runs hook scripts |
| **Serverless Logic** | AWS Lambda | Programmatic rollback processor using Python `boto3` SDK |
| **Monitoring** | AWS CloudWatch | 1-Minute interval metric alarms verifying EC2 instance health |
| **Notification** | Amazon SNS | Multi-state email alerts (Failure -> Rollback -> Success) |

---

## 📋 Prerequisites
Before launching this deployment engine, ensure you have:
1. An **AWS Free Tier Account** with admin permissions.
2. A **GitHub Account** (with the code pushed to a private or public repository).
3. A local terminal with `git` installed.
4. An **EC2 SSH Key Pair** (.pem format) created in your target region.

---

## 🚀 Step-by-Step Setup Guide

This project is divided into structured, step-by-step documentation guides located in the [aws_setup/](file:///c:/Users/Vinayak/Desktop/CICD/aws_setup/) folder. Follow them in order:

1. **Provision IAM & S3 Resources:** 
   Refer to [iam_policies.md](file:///c:/Users/Vinayak/Desktop/CICD/aws_setup/iam_policies.md) for JSON permissions, and follow steps in [manual_infrastructure_guide.md](file:///c:/Users/Vinayak/Desktop/CICD/aws_setup/manual_infrastructure_guide.md) to set up S3, VPC, Security Groups, and EC2.
2. **Install host Agent:** 
   Follow the commands in Step 6 of [manual_infrastructure_guide.md](file:///c:/Users/Vinayak/Desktop/CICD/aws_setup/manual_infrastructure_guide.md) to log in to Ubuntu and install the CodeDeploy Agent.
3. **Assemble CI/CD Pipeline:** 
   Connect your GitHub repository, configure CodeBuild, and bind CodeDeploy using the instructions in [pipeline_setup_guide.md](file:///c:/Users/Vinayak/Desktop/CICD/aws_setup/pipeline_setup_guide.md).
4. **Deploy Self-Healing Automation:** 
   Setup the SNS topic, create the Lambda function, and wire up the CloudWatch and EventBridge rules following [self_healing_guide.md](file:///c:/Users/Vinayak/Desktop/CICD/aws_setup/self_healing_guide.md).
5. **Verify and Run Tests:** 
   Break the deployment intentionally and watch the rollback execute using the steps in [testing_self_healing.md](file:///c:/Users/Vinayak/Desktop/CICD/aws_setup/testing_self_healing.md).

---

## 🔄 How the Self-Healing Logic Works (Simply Explained)

1. **The Code Deploy Hook fails:** When CodeDeploy installs a new build, it executes `validate_service.sh` which polls the `/health` endpoint. If the app responds with an error (e.g., HTTP `500`), the script exits with an error code, and CodeDeploy marks the deployment status as `FAILED`.
2. **EventBridge Triggers Lambda:** Amazon EventBridge detects this state transition and instantly runs the `Self-Healing-Rollback-Lambda` function, passing it the deployment metadata.
3. **Lambda Rewinds History:** The Lambda function uses `boto3` to search CodeDeploy history for the latest deployment ID that has a status of `Succeeded`.
4. **Rollback Deployment starts:** Lambda requests CodeDeploy to start a new deployment, sourcing the exact file package revision from that last successful deployment.
5. **Email Alert Sent:** SNS sends an email to the administrator confirming the failure, the rollback start, and the final restored version.

---

## 📸 Screenshots (Add Yours Here)

*Add screenshots to your portfolio as you complete each test case:*

1. **CodePipeline Successful Execution**
   <!-- ![Pipeline Success](docs/images/pipeline_success.png) -->
2. **CodeDeploy ValidateService Hook Failing**
   <!-- ![Deploy Failure](docs/images/deploy_failure.png) -->
3. **Lambda Execution Logs showing Rollback Command**
   <!-- ![Lambda Execution](docs/images/lambda_logs.png) -->
4. **CodeDeploy Rollback Deployment Succeeding**
   <!-- ![Rollback Success](docs/images/rollback_success.png) -->
5. **SNS Email Alerts received in Inbox**
   <!-- ![SNS Notification](docs/images/sns_emails.png) -->

---

## 🎓 What I Learned (DevOps Placement Focus)

- **Enterprise CI/CD Pipelines:** Gained deep experience designing AWS native pipelines (`CodePipeline`, `CodeBuild`, `CodeDeploy`) and connecting webhooks to external VCS (`GitHub`).
- **Serverless Automation for Infrastructure:** Mastered Event-Driven automation. Used Lambda and EventBridge to monitor deployment state-machines and build self-healing scripts that reduce MTTR (Mean Time to Resolution) to zero.
- **Production-Grade Application Hosting:** Configured `systemd` unit files to manage Gunicorn application processes under non-privileged service users. Learned the importance of application log redirection to syslog/journald.
- **Defensive Scripting:** Wrote robust Bash scripts utilizing conditional check loops, status check filters (`curl`), and daemon process validations, ensuring host scripts fail gracefully.
- **IAM Least Privilege Hardening:** Configured trust policies and custom JSON statements, ensuring CodeBuild and CodeDeploy roles only have read/write access to resources they absolutely require.
