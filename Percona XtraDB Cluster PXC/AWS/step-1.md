### Phase 1: AWS IAM Setup

#### Step 1: Login to AWS Account

```text
Account ID: 102882775921
```

Login URL:

```text
https://janve-aws.signin.aws.amazon.com/console
```

---

#### Step 2: Verify Existing User

Checked IAM user:

```text
janve
```

Observed:

```text
Access Denied
No AdministratorAccess
Unable to manage IAM resources
```

Decision:

```text
Created dedicated Terraform user
```

---

#### Step 3: Create Terraform User

<img width="1741" height="862" alt="image" src="https://github.com/user-attachments/assets/669d73ed-cfac-499a-a1d0-3de099674f8b" />


AWS Console:

```text
IAM
 → Users
 → Create User
```

Created:

```text
terraform-admin
```

---

#### Step 4: Assign Permissions

Attached policy:

```text
AdministratorAccess
```

Verification:

```text
IAM
 → Users
 → terraform-admin
 → Permissions
```

Result:

```text
AdministratorAccess attached successfully
```

---

#### Step 5: Create Access Key

AWS Console:

```text
IAM
 → Users
 → terraform-admin
 → Security Credentials
 → Create Access Key
```

Selected:

```text
Command Line Interface (CLI)
```

Generated:

```text
Access Key ID
Secret Access Key
```

Downloaded credentials.(.CSV file)
<img width="802" height="388" alt="image" src="https://github.com/user-attachments/assets/2c2ad23e-d4ef-460f-9d0e-cc14fab234a0" />


---

### Phase 2: AWS CLI Configuration


#### Download and run the AWS CLI MSI installer for Windows (64-bit):
```bash
https://awscli.amazonaws.com/AWSCLIV2.msi
````

#### Step 6: Configure AWS CLI

Command:

```bash
aws configure
```

Entered:

```text
AWS Access Key ID
AWS Secret Access Key
Region: us-east-1
Output: json
```

<img width="1540" height="417" alt="image" src="https://github.com/user-attachments/assets/95c006fa-8ebe-4853-af17-b16335d72da6" />


AWS created:

```text
C:\Users\venkat\.aws\credentials

C:\Users\venkat\.aws\config
```

---

#### Step 7: Verify Authentication

Command:

```bash
aws sts get-caller-identity
```

Output:

```powershell
PS E:\terraform-SW\aws-deployment> aws sts get-caller-identity
{
    "UserId": "AIDARP5CKSNYR5IDF5G5V",
    "Account": "102882775921",
    "Arn": "arn:aws:iam::102882775921:user/terraform-admin"
}

```

Verification:

```text
AWS CLI authentication successful
```

---

#### Step 8: Verify AWS Permissions

Command:

```bash
aws ec2 describe-regions --region us-east-1
aws ec2 describe-regions --query "Regions[*].RegionName" --output table

aws ec2 describe-regions `
--query "Regions[*].[RegionName,Endpoint]" `
--output table

```

Result:

```text
List of AWS regions returned successfully
```

Verification:

```text
EC2 permissions working
AdministratorAccess confirmed
```

---

### Phase 3: Terraform Setup

#### Step 9: Verify Terraform Installation

Command:

```powershell
terraform version
```

Output:

```powershell
PS E:\terraform-SW\aws-deployment> terraform version
Terraform v1.14.7
on windows_amd64

Your version of Terraform is out of date! The latest version
is 1.15.6. You can update by downloading from https://developer.hashicorp.com/terraform/install
```

Status:

```text
Terraform installed successfully
```

---

#### Step 10: Create Working Directory

Location:

```powershell
E:\terraform-SW\aws-deployment
```

Verification:

```powershell
pwd
```

Output:

```text
E:\terraform-SW\aws-deployment
```

Status:

```text
Terraform project directory created
```

---

### Current Status

```text
✓ AWS Account Ready

✓ terraform-admin User Created

✓ AdministratorAccess Assigned

✓ Access Keys Generated

✓ AWS CLI Configured

✓ Authentication Verified

✓ EC2 Permissions Verified

✓ Terraform Installed

✓ Project Folder Created

Location:
E:\terraform-SW\aws-deployment
```

### Next Phase

```text
Phase 4
---------
Create Terraform Backend

1. S3 Bucket for tfstate
2. DynamoDB Table for state locking

Phase 5
---------
Create Terraform Project Structure

providers.tf
backend.tf
variables.tf
vpc.tf
subnets.tf
security_groups.tf
ec2.tf
ebs.tf
nlb.tf
outputs.tf

Phase 6
---------
Deploy PXC Infrastructure
```

One important note: the Access Key ID and Secret Access Key were visible in an earlier screenshot. After completing setup, rotate (delete and recreate) that access key for security.
