````md
### Setup-2 : Terraform Backend Configuration on AWS

#### Objective

Configure Terraform Remote State Management using:

- Amazon S3 Bucket
- Amazon DynamoDB State Locking
- AWS CLI
- Terraform Backend

This ensures Terraform state is stored centrally and prevents multiple users from modifying infrastructure simultaneously.

---

### Environment Details

| Parameter | Value |
|------------|---------|
| AWS Account ID | 102882775921 |
| IAM User | terraform-admin |
| Region | us-east-1 |
| Terraform Version | 1.14.7 |
| OS | Windows |
| Working Directory | E:\terraform-SW\aws-deployment\mysql-mariadb\Percona XtraDB Cluster PXC\AWS\terraform |

---

### Step 1: Verify AWS Authentication

Command:

```bash
aws sts get-caller-identity
```

Expected Output:

```json
{
    "Account": "102882775921",
    "Arn": "arn:aws:iam::102882775921:user/terraform-admin"
}
```

Status:

```text
Authentication Successful
```

---

### Step 2: Verify EC2 API Access

Command:

```bash
aws ec2 describe-regions --region us-east-1 --output table
```

Expected Output:

```text
--------------------------------------------------
|               DescribeRegions                  |
+----------------+-------------------------------+
| RegionName     | Endpoint                      |
+----------------+-------------------------------+
| us-east-1      | ec2.us-east-1.amazonaws.com   |
| us-east-2      | ec2.us-east-2.amazonaws.com   |
| us-west-1      | ec2.us-west-1.amazonaws.com   |
| ap-south-1     | ec2.ap-south-1.amazonaws.com  |
+----------------+-------------------------------+
```

Status:

```text
AWS Permissions Verified
```

---

### Step 3: Create S3 Bucket for Terraform State

Command:

```bash
aws s3api create-bucket \
  --bucket pxc-tfstate-102882775921 \
  --region us-east-1
```

Output:

```json
{
    "Location": "/pxc-tfstate-102882775921",
    "BucketArn": "arn:aws:s3:::pxc-tfstate-102882775921"
}
```

Verification:

```bash
aws s3 ls
```

Output:

```text
2026-06-12 12:50:00 pxc-tfstate-102882775921
```

Status:

```text
S3 Bucket Created Successfully
```

---

### Step 4: Create DynamoDB Table for State Locking

Command:

```bash
aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

Verification:

```bash
aws dynamodb list-tables
```

Output:

```json
{
    "TableNames": [
        "terraform-locks"
    ]
}
```

Status:

```text
DynamoDB Table Created Successfully
```

---

### Step 5: Create Terraform Project Structure

Directory Structure:

```text
terraform/
├── providers.tf
├── backend.tf
├── variables.tf
├── terraform.tfvars
├── main.tf
├── vpc.tf
├── subnets.tf
├── security_groups.tf
├── ec2.tf
├── ebs.tf
├── nlb.tf
└── outputs.tf
```

Status:

```text
Terraform Project Structure Created
```

---

### Step 6: Configure Terraform Backend

File:

```text
backend.tf
```

Content:

```hcl
terraform {
  backend "s3" {
    bucket         = "pxc-tfstate-102882775921"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
```

Status:

```text
Backend Configuration Completed
```

---

### Step 7: Initialize Terraform Backend

Command:

```bash
terraform init -reconfigure
```

Output:

```text
Successfully configured the backend "s3"

Terraform has been successfully initialized!
```

Status:

```text
Terraform Backend Initialized Successfully
```

---

### Step 8: Verify Terraform Providers

Command:

```bash
terraform providers
```

Output:

```text
Providers required by configuration:

.
└── provider[registry.terraform.io/hashicorp/aws] ~> 6.0
```

Status:

```text
AWS Provider Installed Successfully
```

---

### Step 9: Verify Terraform State

Command:

```bash
terraform state list
```

Output:

```text
No state file was found!
```

Explanation:

```text
This is expected because no AWS resources have been created yet.
Terraform creates the state file after the first successful resource deployment.
```

Status:

```text
Backend Ready
Waiting for Infrastructure Resources
```

---

### Current Project Status

| Component | Status |
|------------|---------|
| AWS Account | Completed |
| IAM User | Completed |
| AWS CLI Configuration | Completed |
| Terraform Installation | Completed |
| S3 Backend Bucket | Completed |
| DynamoDB Locking | Completed |
| Terraform Backend | Completed |
| VPC Creation | Pending |
| Subnet Creation | Pending |
| Security Groups | Pending |
| EC2 Deployment | Pending |
| EBS Volumes | Pending |
| NLB Deployment | Pending |

---

### Next Activity

Create first AWS resource:

```text
vpc.tf
```

Resource:

```text
aws_vpc.pxc_vpc
```

CIDR:

```text
10.10.0.0/16
```

Expected Result:

```text
terraform.tfstate file will be created in S3 bucket.
```
````


