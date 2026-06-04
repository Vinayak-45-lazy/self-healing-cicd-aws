# AWS CI/CD Pipeline Setup Guide
This document provides click-by-click instructions to create your pipeline using AWS CodePipeline, CodeBuild, and CodeDeploy.

---

## Step 1: Push Code to GitHub
1. Create a new repository on GitHub (e.g., `self-healing-flask-app`).
2. Push all project files (`src/`, `tests/`, `requirements.txt`, `buildspec.yml`, `appspec.yml`, `scripts/`, `aws_setup/`) to the repository.

---

## Step 2: Create a CodeDeploy Application & Deployment Group
AWS CodeDeploy requires a logical Application and a Deployment Group specifying where and how to deploy.

### 1. Create Application:
1. Navigate to the **AWS CodeDeploy Console**.
2. In the left menu, click **Applications**, then click **Create application**.
3. **Application name:** `Self-Healing-App`
4. **Compute platform:** Select **EC2/On-premises**.
5. Click **Create application**.

### 2. Create Deployment Group:
1. In the `Self-Healing-App` details page, click **Create deployment group**.
2. **Deployment group name:** `Self-Healing-Production-DG`
3. **Service role:** Select `CodeDeploy-Service-Role` (created in Part 2).
4. **Deployment type:** Select **In-place**.
5. **Environment configuration:**
   - Check the **Amazon EC2 instances** box.
   - **Key:** Select `Name` from the dropdown.
   - **Value:** Select `Self-Healing-Production-Server` (the tag of the EC2 instance).
6. **Agent configuration with AWS Systems Manager:** Select **Now and schedule updates** or **Never** (since we installed the agent manually).
7. **Deployment configuration:** Select **CodeDeployDefault.OneAtATime**.
8. **Load balancer:** Uncheck **Enable load balancing** (to keep it simple and Free Tier friendly).
9. Click **Create deployment group**.

---

## Step 3: Create CodeBuild Project
1. Navigate to the **AWS CodeBuild Console**.
2. In the left menu, click **Build projects**, then click **Create build project**.
3. **Project name:** `Self-Healing-Build`
4. **Source:**
   - **Source provider:** Select **GitHub**.
   - Select **Connect using OAuth** (and authorize AWS to access your repositories) or select your connected GitHub account.
   - **Repository:** Choose **Repository in my GitHub account** and select your repo (e.g., `yourusername/self-healing-flask-app`).
5. **Environment:**
   - **Environment image:** Select **Managed image**.
   - **Operating system:** Select **Amazon Linux** (or **Ubuntu**).
   - **Runtime(s):** Select **Standard**.
   - **Image:** Select the latest version (e.g., `aws/codebuild/standard:7.0`).
   - **Service role:** Select **Existing service role** and choose `CodeBuild-Service-Role`.
6. **Buildspec:**
   - Select **Use a buildspec file** (it will look for the `buildspec.yml` in the repository root by default).
7. **Artifacts:**
   - **Type:** Select **No artifacts** (as CodePipeline will manage the input/output artifacts between stages).
8. **Logs:**
   - Check **CloudWatch logs** (group name: `/aws/codebuild/Self-Healing-Build`).
9. Click **Create build project**.

---

## Step 4: Create the CodePipeline
This orchestrates the entire pipeline from code commit to testing, packaging, and deploying.

1. Navigate to the **AWS CodePipeline Console**.
2. Click **Create pipeline**.
3. **Pipeline name:** `Self-Healing-Pipeline`
4. **Service role:** Select **Existing service role** and choose `CodePipeline-Service-Role`. Click **Next**.
5. **Source Stage:**
   - **Source provider:** Select **GitHub (Version 2)**.
   - **Connection:** Click **Connect to GitHub**. Follow the prompts to create a connection name and install/authorize the AWS Connector for GitHub.
   - **Repository name:** Select your repository (e.g., `yourusername/self-healing-flask-app`).
   - **Branch name:** Select `main` (or your active branch).
   - **Output artifact format:** Select **CodePipeline default**. Click **Next**.
6. **Build Stage:**
   - **Build provider:** Select **AWS CodeBuild**.
   - **Region:** Select the region where you created CodeBuild.
   - **Project name:** Select `Self-Healing-Build`.
   - **Build type:** Select **Single build**. Click **Next**.
7. **Deploy Stage:**
   - **Deploy provider:** Select **AWS CodeDeploy**.
   - **Application name:** Select `Self-Healing-App`.
   - **Deployment group:** Select `Self-Healing-Production-DG`. Click **Next**.
8. **Review:** Verify your settings and click **Create pipeline**.

*The pipeline will immediately run its first execution: pulling code from GitHub, running testing with CodeBuild, and executing the deployment to EC2 with CodeDeploy.*
