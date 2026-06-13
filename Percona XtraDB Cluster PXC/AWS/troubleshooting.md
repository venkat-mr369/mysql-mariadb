Below is a ready-to-save **troubleshooting.md** based on what happened during Setup-5. It documents the issue, root cause, investigation, commands used, and resolution. The log shows AWS initially blocked EC2 creation due to account validation, then after AWS approved access, only `proxysql2` remained to be created and was successfully deployed. 

````md
### Troubleshooting Guide - Setup-5 EC2 Deployment

#### Environment

```text
AWS Region      : us-east-1
Terraform       : v1.14.7
OS              : Windows + Git Bash
Project         : Percona XtraDB Cluster on AWS
```

---

### Issue Summary

During Terraform deployment, infrastructure creation partially succeeded.

Successfully Created:

```text
VPC
Subnets
Internet Gateway
NAT Gateway
Route Tables
Security Group
IAM Role
IAM Instance Profile
Key Pair
PXC1
PXC2
PXC3
ProxySQL1
EBS Volumes
EBS Attachments
```

Failed Resource:

```text
ProxySQL2
```

---

### Error Message

Terraform Apply failed with:

```text
PendingVerification

Your request for accessing resources in this region is being validated.

You will not be able to launch additional resources in this region until validation is complete.
```

AWS Reference:

```text
EC2 RunInstances
StatusCode: 400
```

---

### Root Cause

AWS Account Verification was not completed.

AWS temporarily blocked creation of new EC2 resources.

Existing resources created before validation completed remained intact.

---

### Investigation Steps

#### Check Existing Terraform State

Command:

```bash
terraform state list
```

---

#### Verify ProxySQL Resources

Command:

```bash
terraform state list | grep proxysql
```

Output:

```text
aws_instance.proxysql1
```

Observation:

```text
proxysql2 missing from Terraform state
```

---

### Verify Existing Infrastructure

Command:

```bash
terraform refresh
```

Output confirmed:

```text
aws_instance.pxc1
aws_instance.pxc2
aws_instance.pxc3
aws_instance.proxysql1
```

Infrastructure already existed.

---

### AWS Validation Email Received

AWS sent:

```text
Your Request For Accessing AWS Resources Has Been Validated
```

Meaning:

```text
EC2 access approved
Resource creation allowed
```

---

### Recheck Terraform Plan

Command:

```bash
terraform plan
```

Result:

```text
Plan: 1 to add, 0 to change, 0 to destroy.
```

Terraform detected only:

```text
aws_instance.proxysql2
```

needed creation. :contentReference[oaicite:1]{index=1}

---

### Deploy Missing Resource

Command:

```bash
terraform apply
```

Terraform Output:

```text
aws_instance.proxysql2: Creating...
aws_instance.proxysql2: Creation complete
```

Result:

```text
Apply complete!
Resources: 1 added
```

:contentReference[oaicite:2]{index=2}

---

### Final Outputs

```text
proxysql1_public_ip = 100.59.2.106
proxysql2_public_ip = 32.197.56.207

pxc1_private_ip = 10.10.1.97
pxc2_private_ip = 10.10.2.169
pxc3_private_ip = 10.10.3.132
```

:contentReference[oaicite:3]{index=3}

---

### Final Architecture

```text
VPC
10.10.0.0/16

├── Public Subnet AZ1
│     └── ProxySQL1
│         100.59.2.106
│
├── Public Subnet AZ2
│     └── ProxySQL2
│         32.197.56.207
│
├── Private Subnet AZ1
│     └── PXC1
│         10.10.1.97
│
├── Private Subnet AZ2
│     └── PXC2
│         10.10.2.169
│
└── Private Subnet AZ3
      └── PXC3
          10.10.3.132
```

---

### Lessons Learned

#### Terraform State Is Important

Terraform tracks resources already created.

Command:

```bash
terraform state list
```

helps identify missing resources.

---

#### AWS Validation Can Interrupt Deployments

New AWS accounts may receive:

```text
PendingVerification
```

for EC2 creation.

Wait for AWS approval email.

---

#### Refresh State Before Retrying

Command:

```bash
terraform refresh
```

Benefits:

```text
Synchronizes Terraform state with AWS
Prevents duplicate resource creation
```

---

#### Use Terraform Plan Before Apply

Command:

```bash
terraform plan
```

Allowed verification that only:

```text
proxysql2
```

needed creation.

---

### Recommended Workflow

```text
terraform fmt
        |
terraform validate
        |
terraform plan -out=prod.tfplan
        |
Review Plan
        |
terraform apply prod.tfplan
```

---

### Resolution Status

```text
Issue Resolved Successfully

PXC1      Running
PXC2      Running
PXC3      Running

ProxySQL1 Running
ProxySQL2 Running

EBS Attached

Terraform State Healthy
```

---

### Next Activity

```text
Setup-6

Connect to EC2
Verify EBS Disks
Format Volumes
Mount /data/mysql
Install Percona XtraDB Cluster
Bootstrap Cluster
Join Nodes
Verify Cluster Health
```
````
