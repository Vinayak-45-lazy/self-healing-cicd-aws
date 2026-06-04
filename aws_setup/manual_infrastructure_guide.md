# Step-by-Step AWS Infrastructure Manual Setup Guide
This document lists the exact AWS Management Console clicks and settings required to provision the infrastructure for our project manually.

---

## Step 1: Create a Custom VPC (Virtual Private Cloud)
1. Open the **AWS Management Console** and navigate to the **VPC Console**.
2. Click the **Create VPC** button (top right).
3. Select **VPC only** (we will create subnets and route tables manually for learning).
4. **Name tag:** `Self-Healing-VPC`
5. **IPv4 CIDR block:** Manual Input: `10.0.0.0/16`
6. Keep other settings at defaults and click **Create VPC**.

---

## Step 2: Create Subnet & Internet Gateway
### Subnet
1. In the left navigation pane of the VPC console, click **Subnets**, then click **Create subnet**.
2. **VPC ID:** Select `Self-Healing-VPC`.
3. **Subnet name:** `Public-Subnet-1`
4. **Availability Zone:** Select your preferred zone (e.g., `us-east-1a`).
5. **IPv4 CIDR block:** `10.0.1.0/24`
6. Click **Create subnet**.
7. Select `Public-Subnet-1` from the list, click **Actions** (top right) -> **Edit subnet settings**.
8. Check the box for **Enable auto-assign public IPv4 address**. Click **Save**.

### Internet Gateway (IGW)
1. In the left navigation pane, click **Internet gateways**, then click **Create internet gateway**.
2. **Name tag:** `Self-Healing-IGW`
3. Click **Create internet gateway**.
4. Once created, click **Actions** -> **Attach to VPC**.
5. Select `Self-Healing-VPC` and click **Attach internet gateway**.

### Route Table Setup
1. In the left navigation pane, click **Route tables**. You will see a main route table created automatically for the VPC.
2. Select it, click **Actions** -> **Edit routes**.
3. Click **Add route**.
   - **Destination:** `0.0.0.0/0` (all IPv4 traffic)
   - **Target:** Select **Internet Gateway**, then choose `Self-Healing-IGW`.
4. Click **Save changes**.

---

## Step 3: Create Security Group
1. In the left navigation pane of the VPC or EC2 console, click **Security Groups** under Network & Security.
2. Click **Create security group**.
3. **Security group name:** `Self-Healing-EC2-SG`
4. **Description:** `Security Group for Flask App and SSH`
5. **VPC:** Select `Self-Healing-VPC`.
6. **Inbound rules:** Click **Add rule** for each:
   * **Rule 1:** Type: `SSH` | Port: `22` | Source: `My IP` (or `Anywhere-IPv4` / `0.0.0.0/0` if testing from different IPs)
   * **Rule 2:** Type: `HTTP` | Port: `80` | Source: `Anywhere-IPv4` (`0.0.0.0/0`)
   * **Rule 3:** Type: `Custom TCP` | Port: `8080` | Source: `Anywhere-IPv4` (`0.0.0.0/0`) (Flask application port)
7. **Outbound rules:** Leave default (Allows all outbound traffic).
8. Click **Create security group**.

---

## Step 4: Create IAM Roles in IAM Console
Go to the **IAM Console** (Search for IAM in the AWS Search bar).

### 1. EC2 Instance Role:
1. Click **Roles** in the left menu, then **Create role**.
2. Select **AWS service** as the Trusted entity type and **EC2** as the Service/Use Case. Click **Next**.
3. In the permissions search box, find and check:
   - `AmazonS3ReadOnlyAccess`
   - `AmazonSSMManagedInstanceCore`
4. Click **Next**.
5. **Role name:** `EC2-CodeDeploy-Role`
6. Click **Create role**.

### 2. CodeDeploy Service Role:
1. Click **Create role**.
2. Select **AWS service**, then select **CodeDeploy** from the dropdown/use case options. (Select the standard use case `CodeDeploy`). Click **Next**.
3. The managed policy `AWSCodeDeployRole` will be automatically selected. Click **Next**.
4. **Role name:** `CodeDeploy-Service-Role`
5. Click **Create role**.

### 3. CodeBuild Service Role:
1. Click **Create role**.
2. Select **AWS service** and select **CodeBuild**. Click **Next**.
3. Click **Next** (we will attach an inline policy after creation).
4. **Role name:** `CodeBuild-Service-Role`
5. Click **Create role**.
6. Find the newly created `CodeBuild-Service-Role` in the role list, click on it, go to the **Permissions** tab, click **Add permissions** -> **Create inline policy**.
7. Click the **JSON** tab, paste the CodeBuild JSON policy from `iam_policies.md` (replace `YOUR-ARTIFACTS-S3-BUCKET` with your bucket name).
8. Click **Review policy**, name it `CodeBuildS3LogPolicy`, and click **Create policy**.

### 4. CodePipeline Service Role:
1. Create a role for **CodePipeline** using the same process.
2. **Role name:** `CodePipeline-Service-Role`
3. Add the CodePipeline Custom JSON policy from `iam_policies.md` as an inline policy named `CodePipelineInlinePolicy`.

---

## Step 5: Create S3 Bucket for Build Artifacts
1. Navigate to the **S3 Console**.
2. Click **Create bucket**.
3. **Bucket name:** `self-healing-artifacts-bucket-[your-lastname]-[date]` (Must be globally unique).
4. **Region:** Select the same region as your VPC (e.g., `us-east-1`).
5. Leave **Block all public access** checked (artifacts do not need to be public).
6. Click **Create bucket**.

---

## Step 6: Launch the EC2 Instance & Install CodeDeploy Agent
1. Navigate to the **EC2 Console** and click **Launch instance**.
2. **Name:** `Self-Healing-Production-Server`
3. **Application and OS Image (AMI):** Select **Ubuntu**, then select **Ubuntu Server 22.04 LTS (HVM), SSD Volume Type** (Free Tier eligible).
4. **Instance type:** `t2.micro` (Free Tier).
5. **Key pair (login):** Select or create a new key pair (.pem) and download it.
6. **Network settings:** Click **Edit** (top right of Network panel):
   - **VPC:** Select `Self-Healing-VPC`.
   - **Subnet:** Select `Public-Subnet-1`.
   - **Auto-assign public IP:** Ensure this is set to **Enable**.
   - **Firewall (security groups):** Choose **Select existing security group** and select `Self-Healing-EC2-SG`.
7. **Advanced details:** Expand this section (at the bottom):
   - **IAM instance profile:** Select `EC2-CodeDeploy-Role`.
8. Click **Launch instance**.

### Install CodeDeploy Agent on the Launched Instance:
Once the instance is running, connect to it via SSH (using your Key Pair) or AWS Systems Manager, and run the following commands to install Python, Ruby, and the AWS CodeDeploy Agent:

```bash
# Update repository index and install dependencies
sudo apt-get update
sudo apt-get install -y ruby-full wget python3-pip

# Download and install the CodeDeploy Agent (adjust region if needed, e.g. us-east-1)
cd /home/ubuntu
wget https://aws-codedeploy-us-east-1.s3.us-east-1.amazonaws.com/latest/install
chmod +x ./install
sudo ./install auto

# Check if the service is running
sudo service codedeploy-agent status
```
*Note: If the status shows `active (running)`, the agent is ready to receive deployments!*
