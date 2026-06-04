# Verification Plan: Testing the Self-Healing System
Follow these instructions to simulate failure scenarios, trigger alarms, invoke the rollback Lambda function, and verify email notifications.

---

## Part A: Test Case 1 — Simulating Application Deployment Failure & Self-Healing Rollback

We will simulate a bad code release that passes basic syntax/compilation checks but fails during live execution (a runtime error).

### Step 1: Establish the Stable Base (Version 1)
1. Ensure your working files are pushed to GitHub.
2. Verify that **CodePipeline** completes successfully with all green stages (Source -> Build -> Deploy).
3. Open your browser and navigate to `http://<EC2-PUBLIC-IP>:8080/`. You should see:
   - **Status badge:** `App is running` (Green)
   - **Deploy Version:** `v1.0.0`
4. Confirm that you received a **Pipeline Success Notification** email via SNS.

---

### Step 2: Push Bad Code (Version 2)
We will modify the health check to return a `500 Internal Server Error`, simulating a failed database connection or memory leak.

1. Open [src/app.py](file:///c:/Users/Vinayak/Desktop/CICD/src/app.py) in your editor.
2. Update the `APP_VERSION` variable and the `/health` endpoint to return an error:
```python
# Change version to 2.0.0
APP_VERSION = "2.0.0"

@app.route("/health")
def health():
    """
    Simulated runtime failure for testing self-healing rollbacks.
    Returns HTTP 500 status code.
    """
    response = {
        "status": "error",
        "version": APP_VERSION,
        "description": "Simulated database connection failure!"
    }
    return jsonify(response), 500
```
3. Save the file. Run unit tests locally (`python -m py_compile src/app.py tests/test_app.py`) to confirm syntax is valid.
4. Commit and push the changes to GitHub:
```bash
git add src/app.py
git commit -m "feat: release version 2.0.0 with database updates"
git push origin main
```

---

### Step 3: Monitor Pipeline & Watch ValidateService Fail
1. Open the **AWS CodePipeline Console**, select `Self-Healing-Pipeline`, and watch it trigger.
2. **Source Stage:** Succeeds.
3. **Build Stage:** Succeeds (since the bad code is syntactically correct and doesn't break pytest).
4. **Deploy Stage:** Starts.
5. Open the **AWS CodeDeploy Console** in a separate tab:
   - Click **Deployments** -> select the running deployment ID.
   - You will see the deployment lifecycle hooks running.
   - The pipeline will pause on the **`ValidateService`** step.
   - Behind the scenes, `validate_service.sh` is curl-polling `/health` and receiving HTTP 500.
   - After 6 attempts (30 seconds), the script exits with `exit 1`.
   - The CodeDeploy deployment transitions to status **`Failed`**.

---

### Step 4: Verify EventBridge and Lambda Rollback Trigger
Once the deployment is flagged as `Failed`, Amazon EventBridge immediately intercepts this state change and invokes your Lambda function.

1. Navigate to the **AWS Lambda Console** -> select `Self-Healing-Rollback-Lambda`.
2. Click the **Monitor** tab -> click **View CloudWatch logs**.
3. Select the latest Log Stream. You should see logs confirming:
   - Event received: `Received EventBridge CodeDeploy failure event...`
   - Target identification: `Deployment d-XXXXXXXXX failed for App: Self-Healing-App`
   - Querying stable revision: `Found last stable deployment ID: d-YYYYYYYYY`
   - Triggering rollback: `Successfully triggered rollback deployment. ID: d-ZZZZZZZZZ`

---

### Step 5: Verify Restoration of Version 1
1. Navigate back to the **CodeDeploy Console**.
2. You will see a new deployment automatically created by the Lambda function (description: *"Self-Healing Rollback: Reverting failed deployment..."*).
3. Watch this rollback deployment run. Since it is redeploying the stable `v1.0.0` code, the health checks will pass, and the status will transition to **`Succeeded`**.
4. Refresh your browser at `http://<EC2-PUBLIC-IP>:8080/`.
   - The page should reload successfully.
   - The version will display: **`v1.0.0`** (restored!).

---

### Step 6: Check SNS Email Inbox
Open your email client. You should have received two automated notifications from SNS:
1. **Subject:** `🚨 DEPLOYMENT FAILED: Self-Healing-App (Self-Healing-Production-DG)`
   - *Details the failed deployment ID and states that the self-healing engine is starting.*
2. **Subject:** `🔄 ROLLBACK INITIATED: Self-Healing-App`
   - *Provides the ID of the new rollback deployment, confirming the system has self-healed.*

---

## Part B: Test Case 2 — Testing the CloudWatch EC2 Health Alarm

Now we will test the infrastructure-level monitoring.

1. Navigate to the **AWS EC2 Console**.
2. Click **Instances** (left menu) -> Select `Self-Healing-Production-Server`.
3. Click **Instance State** (top right) -> Select **Stop instance** (this simulates an infrastructure outage or hypervisor failure).
4. Navigate to the **CloudWatch Console** -> Click **Alarms** -> **All Alarms**.
5. Locate `Self-Healing-EC2-Health-Alarm`.
6. Within 1 to 2 minutes of the instance stopping, you will see the Alarm state change from **`OK`** (Green) to **`In alarm`** (Red).
7. Check your email. You will receive an automated email from AWS:
   - **Subject:** `ALARM: "Self-Healing-EC2-Health-Alarm" in US East (N. Virginia)`
   - *This alerts the operations team that the underlying infrastructure is offline.*
8. Go back to the EC2 Console, select the instance, and click **Instance State** -> **Start instance** to restore the system.
