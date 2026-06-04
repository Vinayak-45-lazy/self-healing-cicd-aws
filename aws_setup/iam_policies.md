# IAM Roles & Policies for Self-Healing CI/CD Deployment Engine
This document details the IAM Roles, their Trust Relationships (AssumeRole Policies), and specific Inline Policies required for our pipeline.

---

## 1. EC2 Instance IAM Role (`EC2-CodeDeploy-Role`)
**Purpose:** Attached as an Instance Profile to the EC2 instance. It allows the CodeDeploy Agent running on the EC2 instance to pull deployment artifacts from S3.

### Trust Relationship (Assume Role Policy):
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

### Permissions Policy (Inline or Customer Managed):
Attach the AWS Managed Policy:
- **`AmazonS3ReadOnlyAccess`** (Allows reading build artifacts from S3)
- **`AmazonSSMManagedInstanceCore`** (Recommended - allows SSH via Systems Manager Session Manager)

---

## 2. CodeDeploy Service IAM Role (`CodeDeploy-Service-Role`)
**Purpose:** Used by AWS CodeDeploy to interact with EC2, Auto Scaling, and CloudWatch.

### Trust Relationship (Assume Role Policy):
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codedeploy.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

### Permissions Policy:
Attach the AWS Managed Policy:
- **`AWSCodeDeployRole`** (Provides permissions for CodeDeploy to manage deployments on EC2/ASG)

---

## 3. CodeBuild Service IAM Role (`CodeBuild-Service-Role`)
**Purpose:** Used by AWS CodeBuild to pull sources, write build logs to CloudWatch, and upload artifacts to the S3 bucket.

### Trust Relationship (Assume Role Policy):
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

### Permissions Policy (Custom Inline Policy):
Replace `YOUR-ARTIFACTS-S3-BUCKET` with the actual name of your S3 bucket.
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:PutObject",
        "s3:GetBucketLocation"
      ],
      "Resource": [
        "arn:aws:s3:::YOUR-ARTIFACTS-S3-BUCKET",
        "arn:aws:s3:::YOUR-ARTIFACTS-S3-BUCKET/*"
      ]
    }
  ]
}
```

---

## 4. CodePipeline Service IAM Role (`CodePipeline-Service-Role`)
**Purpose:** Authorizes AWS CodePipeline to orchestrate the flow: pulling code, running CodeBuild, and invoking CodeDeploy.

### Trust Relationship (Assume Role Policy):
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

### Permissions Policy (Custom Inline Policy):
Replace `YOUR-ARTIFACTS-S3-BUCKET` with the actual name of your S3 bucket.
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketLocation",
        "s3:PutObject"
      ],
      "Resource": [
        "arn:aws:s3:::YOUR-ARTIFACTS-S3-BUCKET",
        "arn:aws:s3:::YOUR-ARTIFACTS-S3-BUCKET/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:StartBuild",
        "codebuild:BatchGetBuilds"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "codedeploy:CreateDeployment",
        "codedeploy:GetDeployment",
        "codedeploy:GetDeploymentConfig",
        "codedeploy:GetApplication",
        "codedeploy:RegisterApplicationRevision"
      ],
      "Resource": "*"
    }
  ]
}
```
