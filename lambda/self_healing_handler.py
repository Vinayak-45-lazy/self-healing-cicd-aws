"""
self_healing_handler.py - AWS Lambda Function for Self-Healing CI/CD
This function is triggered by EventBridge when an AWS CodeDeploy deployment fails.
It retrieves the latest successful deployment revision, triggers an automatic
rollback (re-deployment of the stable revision), and publishes an SNS notification.
"""

import os
import logging
import boto3
from botocore.exceptions import ClientError

# Configure logger
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
codedeploy_client = boto3.client("codedeploy")
sns_client = boto3.client("sns")

# SNS Topic ARN passed as environment variable
SNS_TOPIC_ARN = os.environ.get("SNS_TOPIC_ARN")

def lambda_handler(event, context):
    """
    Main Lambda handler invoked by Amazon EventBridge on CodeDeploy Failure.
    """
    logger.info("Received EventBridge CodeDeploy failure event: %s", event)
    
    try:
        # Extract metadata from the EventBridge event
        detail = event.get("detail", {})
        app_name = detail.get("application")
        dg_name = detail.get("deploymentGroup")
        failed_deployment_id = detail.get("deploymentId")
        state = detail.get("state")
        
        if not app_name or not dg_name:
            logger.error("Application name or Deployment Group not found in event.")
            return {"status": "error", "message": "Missing metadata in event."}
            
        logger.warning(
            "Deployment %s failed for App: %s, Group: %s. Initiating self-healing process...",
            failed_deployment_id, app_name, dg_name
        )
        
        # 1. Publish SNS alert about deployment failure
        send_sns_notification(
            subject=f"🚨 DEPLOYMENT FAILED: {app_name} ({dg_name})",
            message=(
                f"AWS CodeDeploy has reported a failure.\n\n"
                f"Application: {app_name}\n"
                f"Deployment Group: {dg_name}\n"
                f"Failed Deployment ID: {failed_deployment_id}\n"
                f"Current Status: {state}\n\n"
                f"Action: Lambda Self-Healing engine is locating the last stable revision to rollback..."
            )
        )
        
        # 2. Get list of previous successful deployments
        # AWS returns these in reverse chronological order (newest first)
        response = codedeploy_client.list_deployments(
            applicationName=app_name,
            deploymentGroupName=dg_name,
            includeOnlyStatuses=["Succeeded"]
        )
        
        deployment_ids = response.get("deployments", [])
        if not deployment_ids:
            msg = f"Self-healing failed: No prior successful deployment found for {app_name} / {dg_name}."
            logger.error(msg)
            send_sns_notification(
                subject=f"❌ SELF-HEALING FAILED: {app_name}",
                message=f"Could not roll back deployment {failed_deployment_id}.\nReason: {msg}"
            )
            return {"status": "failed", "reason": "No successful deployments found"}
            
        # The first item in the list is the most recent successful deployment
        last_successful_id = deployment_ids[0]
        logger.info("Found last stable deployment ID: %s", last_successful_id)
        
        # 3. Retrieve deployment configuration (revision info) of the stable deployment
        dep_detail = codedeploy_client.get_deployment(deploymentId=last_successful_id)
        revision = dep_detail["deploymentInfo"]["revision"]
        logger.info("Retrieved revision details: %s", revision)
        
        # 4. Trigger deployment of the stable revision
        rollback_response = codedeploy_client.create_deployment(
            applicationName=app_name,
            deploymentGroupName=dg_name,
            revision=revision,
            deploymentConfigName="CodeDeployDefault.OneAtATime",
            description=f"Self-Healing Rollback: Reverting failed deployment {failed_deployment_id} to last stable revision {last_successful_id}."
        )
        
        rollback_deployment_id = rollback_response.get("deploymentId")
        logger.info("Successfully triggered rollback deployment. ID: %s", rollback_deployment_id)
        
        # 5. Publish SNS notification for successful rollback trigger
        send_sns_notification(
            subject=f"🔄 ROLLBACK INITIATED: {app_name}",
            message=(
                f"Self-Healing rollback triggered successfully!\n\n"
                f"Failed Deployment ID: {failed_deployment_id}\n"
                f"Restored to Stable Deployment ID: {last_successful_id}\n"
                f"New Rollback Deployment ID: {rollback_deployment_id}\n\n"
                f"Monitor the deployment status in the AWS Console."
            )
        )
        
        return {
            "status": "success",
            "failed_deployment": failed_deployment_id,
            "restored_to_deployment": last_successful_id,
            "rollback_deployment_id": rollback_deployment_id
        }
        
    except ClientError as e:
        error_msg = e.response["Error"]["Message"]
        logger.error("AWS ClientError: %s", error_msg)
        send_sns_notification(
            subject=f"❌ SELF-HEALING ERROR",
            message=f"An error occurred while executing the self-healing Lambda function:\n\n{error_msg}"
        )
        return {"status": "error", "message": error_msg}
    except Exception as e:
        logger.error("Unexpected error: %s", str(e))
        return {"status": "error", "message": str(e)}

def send_sns_notification(subject, message):
    """
    Sends an email alert via SNS topic.
    """
    if not SNS_TOPIC_ARN:
        logger.warning("SNS_TOPIC_ARN not set. Skipping email alert.")
        return
        
    try:
        sns_client.publish(
            TopicArn=SNS_TOPIC_ARN,
            Subject=subject,
            Message=message
        )
        logger.info("SNS notification sent: %s", subject)
    except ClientError as e:
        logger.error("Failed to send SNS notification: %s", e.response["Error"]["Message"])
