Below is the **fully updated Setup-6.md** reflecting the final design, including the fixes we discovered during deployment (IMDSv2, EBS AZ mismatch, Multi-AZ validation, bootstrap wait logic, etc.).

---

### Setup-6 : Server Bootstrap (Terraform)

### Objective

Automatically prepare Linux servers immediately after EC2 creation.

No manual server preparation should be required.

Terraform executes bootstrap scripts using:

```text
user_data
```

to prepare operating systems, storage, packages, and AWS management services.

---

### Setup-6 Architecture

```text
Terraform
    |
    +--> EC2 Creation
            |
            +--> user_data
                    |
                    +--> bootstrap-pxc.sh
                    |
                    +--> bootstrap-proxysql.sh
```

---
<<<<<<< HEAD
Recommended Structure
```bash
AWS/
│
├── terraform/
│
├── ansible/
│   ├── inventory
│   ├── ansible.cfg
│   ├── playbook.yml
│   │
│   └── roles/
│       ├── storage/
│       ├── pxc/
│       └── proxysql/
│
├── scripts/
│
├── docs/
│
├── setup-1.md
├── setup-2.md
├── setup-3.md
├── setup-4.md
├── setup-5.md
└── setup-6.md
```

### Setup-6 (Ansible)
=======

### Bootstrap Flow
>>>>>>> 7093065 (12-july-reviewed again)

```text
PXC1
PXC2
PXC3
    |
    +--> bootstrap-pxc.sh
            |
            +--> OS Update
            +--> Install Packages
            +--> Install SSM Agent
            +--> Wait For EBS
            +--> Format Disk
            +--> Mount /data/mysql
            +--> Update /etc/fstab

ProxySQL1
ProxySQL2
    |
    +--> bootstrap-proxysql.sh
            |
            +--> OS Update
            +--> Install Packages
            +--> Install Git
            +--> Install SSM Agent
```

---

### Setup-6.1 Bootstrap Scripts

Directory:

```text
terraform/
└── scripts/
    ├── bootstrap-pxc.sh
    └── bootstrap-proxysql.sh
```

---

### bootstrap-pxc.sh

Purpose:

```text
PXC1
PXC2
PXC3
```

Responsibilities:

```text
OS Update

Install Base Packages

Install SSM Agent

Wait For EBS Device

Format Data Disk

Create /data/mysql

Mount Filesystem

Update /etc/fstab
```

Content:

```bash
#!/bin/bash

exec > /var/log/bootstrap.log 2>&1

dnf update -y

dnf install -y \
wget \
vim \
rsync \
socat \
net-tools \
xfsprogs \
amazon-ssm-agent

systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

while [ ! -b /dev/nvme1n1 ]; do
  sleep 10
done

mkfs.xfs -f /dev/nvme1n1

mkdir -p /data/mysql

mount /dev/nvme1n1 /data/mysql

UUID=$(blkid -s UUID -o value /dev/nvme1n1)

echo "UUID=$UUID /data/mysql xfs defaults,nofail 0 0" >> /etc/fstab
```

---

### Why Wait For EBS?

During deployment, Terraform successfully created EC2 instances before EBS attachment completed.

Without waiting:

```text
EC2 Boots
     |
Bootstrap Starts
     |
/dev/nvme1n1 Not Present
     |
mkfs.xfs Fails
```

Solution:

```bash
while [ ! -b /dev/nvme1n1 ]; do
  sleep 10
done
```

This guarantees EBS is available before formatting.

---

### bootstrap-proxysql.sh

Purpose:

<<<<<<< HEAD
```text id="x07"
ProxySQL1 (or) Ansible-VM
```

as the Ansible Control Node. i am using ProxySQL1 Server, Because i am using Personal Subcription due that 
=======
```text
ProxySQL1
ProxySQL2
```

Responsibilities:
>>>>>>> 7093065 (12-july-reviewed again)

```text
OS Update

Install Base Packages

Install Git

Install SSM Agent
```

Content:

```bash
#!/bin/bash

exec > /var/log/bootstrap.log 2>&1

dnf update -y

dnf install -y \
wget \
vim \
net-tools \
git \
amazon-ssm-agent

systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent
```

---

### Setup-6.2 EC2 Integration

Update:

```text
ec2.tf
```

PXC Nodes:

```hcl
user_data = file("${path.module}/scripts/bootstrap-pxc.sh")
```

Apply to:

```text
pxc1
pxc2
pxc3
```

ProxySQL Nodes:

```hcl
user_data = file("${path.module}/scripts/bootstrap-proxysql.sh")
```

Apply to:

```text
proxysql1
proxysql2
```

---

### Setup-6.2.1 EC2 Metadata Security

Enable IMDSv2.

Add to all EC2 instances:

```hcl
metadata_options {

  http_endpoint = "enabled"

  http_tokens = "required"
}
```

Purpose:

```text
Improve EC2 Security

Prevent Metadata Abuse

AWS Best Practice

IMDSv2 Enforcement
```

---

### Setup-6.3 IAM and SSM Integration

Update:

```text
iam.tf
```

Attach:

```hcl
resource "aws_iam_role_policy_attachment" "ssm" {

  role = aws_iam_role.ec2_role.name

  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
```

Purpose:

```text
AWS Systems Manager

Session Manager

Patch Manager

Remote Commands

Automation
```

---

### Setup-6.4 Storage Validation

Login:

```bash
ssh ec2-user@<pxc-private-ip>
```

Verify:

```bash
lsblk

df -h

cat /etc/fstab
```

Expected:

```text
/dev/nvme1n1

Mounted On:

/data/mysql
```

Example:

```text
/dev/nvme1n1       25G   212M   25G   1% /data/mysql
```

---

### Setup-6.4.1 Package Validation

Verify:

```bash
which rsync

which socat

which wget
```

Expected:

```text
/usr/bin/rsync

/usr/bin/socat

/usr/bin/wget
```

---

### Setup-6.4.2 SSM Validation

Verify:

```bash
systemctl status amazon-ssm-agent
```

Expected:

```text
active (running)
```

---

### Setup-6.4.3 Bootstrap Log Validation

Verify:

```bash
sudo cat /var/log/bootstrap.log
```

Expected:

```text
No Errors

Package Installation Successful

Filesystem Mounted
```

---

### Setup-6.4.4 Multi-AZ Validation

Verify PXC nodes are distributed correctly.

Command:

```bash
aws ec2 describe-instances \
--query 'Reservations[*].Instances[*].[Tags[?Key==`Name`].Value|[0],SubnetId,Placement.AvailabilityZone,PrivateIpAddress]' \
--output table
```

Expected:

```text
pxc-node1  us-east-1a  10.10.1.x

pxc-node2  us-east-1b  10.10.2.x

pxc-node3  us-east-1c  10.10.3.x
```

---

### Setup-6.4.5 EBS Validation

Verify:

```bash
aws ec2 describe-volumes \
--query 'Volumes[*].[Tags[?Key==`Name`].Value|[0],AvailabilityZone,State]' \
--output table
```

Expected:

```text
pxc1-data us-east-1a in-use

pxc2-data us-east-1b in-use

pxc3-data us-east-1c in-use
```

Requirement:

```text
EBS AZ MUST Match EC2 AZ
```

---

### Setup-6.4.6 Infrastructure Validation

Verify:

```bash
terraform state list
```

Expected:

```text
aws_vpc.pxc_vpc

aws_subnet.*

aws_security_group.*

aws_instance.*

aws_ebs_volume.*

aws_volume_attachment.*

aws_nat_gateway.*

aws_iam_role.*
```

---

### Setup-6.5 Lessons Learned

During deployment the following issues were identified and fixed.

#### Issue-1

```text
EBS Volume ZoneMismatch
```

Cause:

```text
Hardcoded Availability Zones
```

Solution:

```hcl
availability_zone = aws_instance.pxc1.availability_zone
```

---

#### Issue-2

```text
All PXC Nodes Deployed To Same Subnet
```

Cause:

```hcl
subnet_id = aws_subnet.db_subnet_az1.id
```

was configured for:

```text
pxc1
pxc2
pxc3
```

Solution:

```hcl
pxc1 -> db_subnet_az1

pxc2 -> db_subnet_az2

pxc3 -> db_subnet_az3
```

---

#### Issue-3

```text
Bootstrap Script Started Before EBS Attachment
```

Solution:

```bash
while [ ! -b /dev/nvme1n1 ]; do
  sleep 10
done
```

---

#### Issue-4

```text
Deprecated Backend Locking
```

Old:

```hcl
dynamodb_table = "terraform-locks"
```

New:

```hcl
use_lockfile = true
```

---

### Setup-6 Deliverables

After Terraform Apply:

```text
VPC Created

Subnets Created

NAT Gateway Created

Security Groups Created

IAM Configured

EC2 Created

EBS Attached

OS Updated

SSM Enabled

IMDSv2 Enabled

Packages Installed

Filesystem Mounted

/data/mysql Ready

Multi-AZ Validation Complete

Infrastructure Ready For PXC
```

---

### Setup-7 Starts Here

Ansible begins from Setup-7.

```text
Setup-7
--------
Ansible Control Node Setup

Setup-8
--------
Percona Repository Installation

Setup-9
--------
PXC Package Installation

Setup-10
---------
PXC Configuration

Setup-11
---------
Cluster Bootstrap

Setup-12
---------
ProxySQL Installation

Setup-13
---------
ProxySQL Configuration

Setup-14
---------
Validation

Setup-15
---------
GitHub Actions CI/CD
```

---

### Final Architecture

```text
Terraform
    |
Infrastructure
    |
Bootstrap (user_data)
    |
Servers Ready
    |
Ansible
    |
PXC Installation
    |
ProxySQL Installation
    |
Validation
    |
GitHub Actions Automation
```
