# AWS Self-Healing Logic Configuration Guide
This document details how to configure the SNS topic, Lambda function, and CloudWatch / EventBridge alert rules in the AWS Console.

---

## Step 1: Create the SNS Topic for Notifications
We will use Amazon Simple Notification Service (SNS) to broadcast alerts to your email.

1. Navigate to the **SNS Console**.
2. Click **Topics** on the left menu, then click **Create topic**.
3. **Type:** Select **Standard**.
4. **Name:** `Self-Healing-Alerts`
5. **Display name:** `AutoHeal`
6. Click **Create topic**.
7. Copy the **ARN** (e.g. `arn:aws:sns:us-east-1:123456789012:Self-Healing-Alerts`).
8. Scroll down to **Subscriptions** and click **Create subscription**.
   - **Protocol:** Select **Email**.
   - **Endpoint:** Enter your personal email address.
   - Click **Create subscription**.
9. **CRITICAL:** Check your email inbox. You will receive a confirmation email from AWS Notifications. Click the **Confirm Subscription** link in the email to activate alerts.

---

## Step 2: Create the Lambda Function
This Lambda function parses deployment failures and invokes the rollback.

### 1. Create the Lambda IAM Execution Role:
1. Go to the **IAM Console** -> **Roles** -> **Create role**.
2. Trust entity: **AWS service**, Service/Use Case: **Lambda**. Click **Next**.
3. Attach permissions:
   - AWS Managed Policy: **`AWSLambdaBasicExecutionRole`** (allows writing logs to CloudWatch).
4. Click **Next**, name the role **`Lambda-Self-Healing-Role`**, and click **Create role**.
5. Open the created `Lambda-Self-Healing-Role`, click **Add permissions** -> **Create inline policy**, choose **JSON** tab, and paste the following policy:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "codedeploy:ListDeployments",
        "codedeploy:GetDeployment",
        "codedeploy:CreateDeployment"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "sns:Publish"
      ],
      "Resource": "YOUR-SNS-TOPIC-ARN"
    }
  ]
}
```
*(Replace `YOUR-SNS-TOPIC-ARN` with the actual SNS ARN you copied in Step 1. Click **Review policy**, name it `LambdaCodeDeploySNSPolicy`, and click **Create policy**).*

### 2. Create the Lambda Function:
1. Navigate to the **Lambda Console** and click **Create function**.
2. Select **Author from scratch**.
3. **Function name:** `Self-Healing-Rollback-Lambda`
4. **Runtime:** Select **Python 3.9** (or Python 3.10/3.11/3.12).
5. **Change default execution role:** Choose **Use an existing role** and select `Lambda-Self-Healing-Role`.
6. Click **Create function**.
7. In the **Code source** editor, double-click `lambda_function.py`, delete the default code, and copy-paste the entire contents of your [lambda/self_healing_handler.py](file:///c:/Users/Vinayak/Desktop/CICD/lambda/self_healing_handler.py).
8. Click the **Deploy** button (top of the editor).
9. Go to the **Configuration** tab -> **Environment variables** (left sub-menu) -> **Edit**.
   - Click **Add environment variable**.
   - **Key:** `SNS_TOPIC_ARN`
   - **Value:** Paste your actual SNS Topic ARN.
   - Click **Save**.

---

## Step 3: Configure CloudWatch Alarm for EC2 Health (1-Minute Interval)
This alarm monitors host availability and triggers notification if the EC2 instance status check fails.

1. Navigate to the **CloudWatch Console**.
2. Click **Alarms** -> **All alarms** (left menu), then click **Create alarm**.
3. Click **Select metric**.
   - Navigate to: **EC2** -> **Per-Instance Metrics**.
   - Search for your instance `Self-Healing-Production-Server`.
   - Select the checkbox for Metric Name: **`StatusCheckFailed`**.
   - Click **Select metric**.
4. **Metric Settings:**
   - **Statistic:** Select **Maximum**.
   - **Period:** Select **1 minute**.
5. **Conditions:**
   - **Threshold type:** Select **Static**.
   - **Whenever StatusCheckFailed is...** Select **Greater than or equal to (>=)**.
   - Enter value: `1`. (This means the alarm goes off if any status check fails).
   - Click **Next**.
6. **Configure Actions:**
   - **Alarm state trigger:** Select **In alarm**.
   - **Send a notification to the following SNS topic:** Select **Select an existing SNS topic** and choose `Self-Healing-Alerts`.
   - Click **Next**.
7. **Name and description:**
   - **Alarm name:** `Self-Healing-EC2-Health-Alarm`
   - Click **Next**, review settings, and click **Create alarm**.

---

## Step 4: Configure EventBridge Rules (Triggers)
We need to trigger our Lambda function on CodeDeploy failure, and send pipeline notifications on success.

### Rule 1: Trigger Lambda on CodeDeploy Failure
1. Navigate to the **Amazon EventBridge Console**.
2. Click **Rules** (left menu) -> **Create rule**.
3. **Name:** `Trigger-Rollback-On-CodeDeploy-Failure`
4. **Rule type:** Select **Rule with an event pattern**. Click **Next**.
5. **Event source:** Select **AWS services**.
6. **Creation method:** Select **Use pattern form**.
7. **Event pattern:**
   - **AWS service:** Select **CodeDeploy**.
   - **Event type:** Select **CodeDeploy Deployment State-change Notification**.
   - **Specific state(s):** Check the box for **FAILURE**.
   - Click **Next**.
8. **Select targets:**
   - **Target 1:** Select **AWS service**.
   - **Target type:** Select **Lambda function**.
   - **Function:** Select `Self-Healing-Rollback-Lambda`.
   - Click **Next** -> **Next**, review, and click **Create rule**.

### Rule 2: Alert SNS on CodePipeline Success
1. In EventBridge Rules, click **Create rule**.
2. **Name:** `Pipeline-Success-Notification`
3. **Rule type:** Select **Rule with an event pattern**. Click **Next**.
4. **Event pattern:**
   - **AWS service:** Select **CodePipeline**.
   - **Event type:** Select **CodePipeline Pipeline Execution State Change**.
   - **Specific state(s):** Check the box for **SUCCEEDED**.
   - Click **Next**.
5. **Select targets:**
   - **Target 1:** Select **AWS service**.
   - **Target type:** Select **SNS topic**.
   - **Topic:** Select `Self-Healing-Alerts`.
   - Click **Next** -> **Next**, review, and click **Create rule**.
