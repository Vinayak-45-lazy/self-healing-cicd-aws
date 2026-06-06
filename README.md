# 🚀 Self-Healing CI/CD Deployment Engine on AWS

A production-ready CI/CD pipeline that **automatically tests, deploys, and recovers from failures** without human intervention.

---

## 📌 Project Overview

This project demonstrates a **self-healing deployment system** using GitHub Actions and AWS.

Whenever code is pushed:

* ✅ Tests are executed automatically
* 🚀 Application is deployed to EC2 if tests pass
* 🔁 If deployment fails, the system **rolls back to the last stable version automatically**

👉 Goal: Ensure **zero downtime deployments** and **high reliability**

---

## 🧠 Key Features

* ⚙️ Automated CI/CD using GitHub Actions
* 🧪 Unit testing with pytest
* 🚀 Zero-touch deployment to AWS EC2
* 🔁 Automatic rollback (Self-Healing)
* 📦 Artifact and version handling
* 🌐 Live health monitoring via API

---

## 🏗️ Architecture

```
Developer → GitHub Push
        ↓
GitHub Actions (CI)
        ↓
Run Tests (pytest)
        ↓
If Passed → Deploy to EC2
        ↓
Health Check (/health)
        ↓
If Failed → Auto Rollback
```

---

## 🛠️ Tech Stack

* **Backend:** Python Flask
* **CI/CD:** GitHub Actions
* **Cloud:** AWS EC2 (Amazon Linux 2023)
* **Server:** Gunicorn
* **Testing:** pytest
* **Storage:** AWS S3
* **Scripting:** Bash

---

## 📂 Project Structure

```
CICD/
├── .github/workflows/deploy.yml   # CI/CD pipeline
├── src/                           # Flask app
├── tests/                         # Unit tests
├── scripts/                       # Deployment scripts
├── lambda/                        # Self-healing logic (future use)
├── aws_setup/                     # Setup documentation
├── requirements.txt
└── README.md
```

---

## 🔄 CI/CD Workflow

### 1. Run Tests

* Executes pytest on every push
* Stops pipeline if any test fails

### 2. Deploy to EC2

* SSH into EC2
* Pull latest code
* Install dependencies
* Restart application using Gunicorn

### 3. Self-Healing Rollback

* Triggered automatically if deployment fails
* Restores last working version
* Ensures application stays available

---

## 🌐 Live Application

* 🏠 Home: http://13.206.89.236:5000
* 📊 Health Check: http://13.206.89.236:5000/health
* ℹ️ About: http://13.206.89.236:5000/about

---

## 🧪 Sample Test Cases

* Home page loads successfully
* About page loads successfully
* Health API returns status 200

---

## 🔥 Real Proof of Self-Healing

* Deployed a **broken version intentionally**
* Health check failed ❌
* Pipeline triggered rollback automatically 🔁
* Previous stable version restored ✅

👉 Result: **No downtime for users**

---

## 🚀 How to Run Locally

```bash
git clone https://github.com/Vinayak-45-lazy/self-healing-cicd-aws.git
cd self-healing-cicd-aws

pip install -r requirements.txt
python src/app.py
```

---

## 📌 Future Improvements

* Add Docker containerization
* Integrate Kubernetes (EKS)
* Use AWS CodeDeploy for advanced deployments
* Add monitoring with CloudWatch / Prometheus

---

## 👨‍💻 Author

**Vinayak**
Aspiring DevOps Engineer

---

## ⭐ Why This Project Stands Out

* Real-world DevOps problem solving
* Demonstrates **automation + reliability**
* Implements **self-healing infrastructure**
* Production-style deployment pipeline

---

> 💡 This project showcases how modern DevOps systems ensure stability by automatically recovering from failures — a key requirement in real-world systems.
