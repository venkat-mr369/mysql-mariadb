Perfect, Venkata.

You already have:

```text
AWS Account       ✅
terraform-admin   ✅
AWS CLI           ✅
Terraform         ✅
Working Folder    ✅
```

Current working directory:

```text
E:\terraform-SW\aws-deployment
```

This is where we will create the complete project.

### Create Project Structure

From PowerShell:

```powershell
mkdir terraform
mkdir ansible
mkdir scripts
mkdir docs
mkdir .github
mkdir .github\workflows
```

Then:

```powershell
cd terraform
```

---

### Target Structure

```text
E:\terraform-SW\aws-deployment
│
├── terraform
│   ├── backend.tf
│   ├── providers.tf
│   ├── variables.tf
│   ├── main.tf
│   ├── vpc.tf
│   ├── subnets.tf
│   ├── security_groups.tf
│   ├── ec2.tf
│   ├── ebs.tf
│   ├── nlb.tf
│   ├── outputs.tf
│   └── terraform.tfvars
│
├── ansible
│
├── scripts
│
├── docs
│
└── .github
    └── workflows
```

---

### First Create providers.tf

```hcl
terraform {
  required_version = ">=1.14"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
```

---

### Create variables.tf

```hcl
variable "aws_region" {
  default = "us-east-1"
}

variable "environment" {
  default = "prod"
}
```

---

### Create terraform.tfvars

```hcl
aws_region = "us-east-1"

environment = "prod"
```

---

### Create backend.tf

⚠️ First create S3 bucket and DynamoDB table before enabling backend.

Temporarily create:

```hcl
terraform {
}
```

Later we will replace it with:

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

---

### Create main.tf

```hcl
data "aws_caller_identity" "current" {}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "user_arn" {
  value = data.aws_caller_identity.current.arn
}
```

---

### Test Terraform

Inside:

```text
E:\terraform-SW\aws-deployment\terraform
```

Run:

```powershell
terraform init
```

Then:

```powershell
terraform plan
```

Then:

```powershell
terraform apply
```

Type:

```text
yes
```

Expected:

```text
account_id = 102882775921

user_arn = arn:aws:iam::102882775921:user/terraform-admin
```

---

### After This

We'll create the Terraform backend:

```text
S3 Bucket
DynamoDB Locking
```

and then build:

```text
VPC
3 AZs
Private Subnets
Security Groups
3 PXC Nodes
2 ProxySQL Nodes
EBS Volumes
Network Load Balancer
Route Tables
NAT Gateway
```

in a production-grade structure.
