````md
### Setup-5 : EC2 Instances, EBS Storage, IAM Role and Key Pair

#### Objective

Deploy the infrastructure required for Percona XtraDB Cluster and ProxySQL.

This setup creates:

- AWS Key Pair
- IAM Role
- IAM Instance Profile
- Amazon Linux 2023 AMI Lookup
- 3 PXC Nodes
- 2 ProxySQL Nodes
- 3 EBS Data Volumes
- 3 EBS Volume Attachments
- Terraform Outputs

---

### Architecture

```text
                     Internet
                         |
                 Internet Gateway
                         |
                 Public Subnets
                         |
        --------------------------------
        |                              |
    ProxySQL1                     ProxySQL2
    t3.micro                      t3.micro
        |                              |
        --------------------------------
                         |
                 Private Subnets
                         |
 -------------------------------------------------
 |                    |                         |
PXC1                PXC2                     PXC3
t3.small            t3.small                 t3.small
25GB gp3            25GB gp3                 25GB gp3
```

---

### Why Private Subnets for PXC

Database servers should not be exposed to the Internet.

Benefits:

```text
No Public IP
Reduced Attack Surface
Better Security
Production Design
```

---

### Why Public Subnets for ProxySQL

ProxySQL acts as the entry point.

Benefits:

```text
SSH Access
Application Connectivity
Load Balancing
Read/Write Routing
```

---

### File Structure

```text
terraform/

├── backend.tf
├── providers.tf
├── variables.tf

├── data.tf
├── keypair.tf
├── iam.tf
├── ec2.tf
├── ebs.tf

├── outputs.tf

├── vpc.tf
├── subnets.tf
├── nat_gateway.tf
├── route_tables.tf
├── security_groups.tf
```

---

### data.tf

Purpose:

```text
Automatically discover latest Amazon Linux 2023 AMI.
```

```hcl
data "aws_ami" "amazon_linux" {

  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}
```

---

### keypair.tf

Purpose:

```text
Register existing SSH public key in AWS.
```

```hcl
resource "aws_key_pair" "pxc_key" {

  key_name = "pxc-key"

  public_key = file("id_rsa.pub")
}
```

---

### IAM Flow

```text
EC2 Instance
      |
IAM Instance Profile
      |
IAM Role
      |
AWS Services
```

---

### iam.tf

```hcl
resource "aws_iam_role" "ec2_role" {

  name = "pxc-ec2-role"

  assume_role_policy = jsonencode({

    Version = "2012-10-17"

    Statement = [

      {

        Action = "sts:AssumeRole"

        Effect = "Allow"

        Principal = {

          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {

  name = "pxc-instance-profile"

  role = aws_iam_role.ec2_role.name
}
```

---

### EC2 Design

#### PXC Nodes

```text
Instance Type : t3.small
OS            : Amazon Linux 2023
Root Disk     : 10 GB gp3
Data Disk     : 25 GB gp3
Subnet        : Private
Public IP     : No
```

#### ProxySQL Nodes

```text
Instance Type : t3.micro
OS            : Amazon Linux 2023
Root Disk     : 10 GB gp3
Subnet        : Public
Public IP     : Yes
```

---

### ec2.tf

Creates:

```text
pxc-node1
pxc-node2
pxc-node3

proxysql1
proxysql2
```

Important settings:

```hcl
ami = data.aws_ami.amazon_linux.id

associate_public_ip_address = false

root_block_device {

  volume_size = 10

  volume_type = "gp3"
}
```

For ProxySQL:

```hcl
associate_public_ip_address = true
```

---

### EBS Storage Design

```text
PXC1
 ├── Root Disk 10GB
 └── Data Disk 25GB

PXC2
 ├── Root Disk 10GB
 └── Data Disk 25GB

PXC3
 ├── Root Disk 10GB
 └── Data Disk 25GB
```

---

### ebs.tf

Creates:

```text
pxc1-data
pxc2-data
pxc3-data
```

Size:

```text
25 GB
```

Type:

```text
gp3
```

Attachment:

```text
/dev/sdf
```

---

### Volume Attachment Flow

```text
EBS Volume
      |
aws_volume_attachment
      |
EC2 Instance
      |
OS
      |
/dev/nvme1n1
```

Amazon Linux typically shows:

```text
/dev/nvme1n1
```

instead of:

```text
/dev/sdf
```

---

### outputs.tf

Purpose:

```text
Display important information after deployment.
```

```hcl
output "pxc1_private_ip" {
  value = aws_instance.pxc1.private_ip
}

output "pxc2_private_ip" {
  value = aws_instance.pxc2.private_ip
}

output "pxc3_private_ip" {
  value = aws_instance.pxc3.private_ip
}

output "proxysql1_public_ip" {
  value = aws_instance.proxysql1.public_ip
}

output "proxysql2_public_ip" {
  value = aws_instance.proxysql2.public_ip
}
```

---

### Validation

```bash
terraform fmt
```

Expected:

```text
ec2.tf
ebs.tf
```

---

### Validate

```bash
terraform validate
```

Expected:

```text
Success! The configuration is valid.
```

---

### Create Execution Plan

```bash
terraform plan -out=pxc-prod.tfplan
```

Expected:

```text
Plan: 14 to add, 1 to change, 0 to destroy.
```

---

### Why Save Plan

Without saving:

```bash
terraform plan
terraform apply
```

Terraform recalculates the plan.

With saved plan:

```bash
terraform plan -out=pxc-prod.tfplan
terraform apply pxc-prod.tfplan
```

Benefits:

```text
Predictable Deployment
Enterprise Standard
Used in CI/CD
```

---

### Verify Saved Plan

```bash
ls -lh *.tfplan
```

Expected:

```text
pxc-prod.tfplan
```

Display:

```bash
terraform show pxc-prod.tfplan
```

---

### Deploy Infrastructure

```bash
terraform apply pxc-prod.tfplan
```

Type:

```text
yes
```

Expected:

```text
Apply complete!
```

---

### Resources Created

```text
aws_key_pair.pxc_key

aws_iam_role.ec2_role

aws_iam_instance_profile.ec2_profile

aws_instance.pxc1
aws_instance.pxc2
aws_instance.pxc3

aws_instance.proxysql1
aws_instance.proxysql2

aws_ebs_volume.pxc1_data
aws_ebs_volume.pxc2_data
aws_ebs_volume.pxc3_data

aws_volume_attachment.pxc1_attach
aws_volume_attachment.pxc2_attach
aws_volume_attachment.pxc3_attach
```

---

### Verify Outputs

```bash
terraform output
```

Expected:

```text
pxc1_private_ip = 10.10.1.x

pxc2_private_ip = 10.10.2.x

pxc3_private_ip = 10.10.3.x

proxysql1_public_ip = xx.xx.xx.xx

proxysql2_public_ip = xx.xx.xx.xx
```

---

### Verify EC2 Instances

```bash
aws ec2 describe-instances \
--query 'Reservations[*].Instances[*].[InstanceId,PrivateIpAddress,State.Name]' \
--output table
```

Expected:

```text
running
running
running
running
running
```

---

### Verify EBS Volumes

```bash
aws ec2 describe-volumes --output table
```

Expected:

```text
pxc1-data

pxc2-data

pxc3-data
```

---

### Verify Key Pair

```bash
aws ec2 describe-key-pairs --output table
```

Expected:

```text
pxc-key
```

---

### Verify IAM Role

```bash
aws iam get-role \
--role-name pxc-ec2-role
```

Expected:

```text
Role Exists
```

---

### Result

Successfully created:

```text
3 PXC Nodes

2 ProxySQL Nodes

3 EBS Volumes

IAM Role

Instance Profile

AWS Key Pair

Terraform Outputs
```

Infrastructure is now ready for:

```text
Filesystem Creation

Mount Data Volumes

Percona Repository Setup

PXC Installation

Cluster Bootstrap

ProxySQL Configuration
```

---

### Next Activity

Setup-6.md

Topics:

```text
Connect to EC2

Verify Disks

Format EBS Volumes

Mount /data/mysql

Persist Mounts

Install Percona XtraDB Cluster

Bootstrap Node1

Join Node2

Join Node3

Verify wsrep_cluster_size=3
```
````
