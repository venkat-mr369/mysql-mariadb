Venkata, for a **Percona XtraDB Cluster (PXC) 8.0 on AWS**, the recommended production approach is:

**GitHub → GitHub Actions → Terraform → AWS Infrastructure → Ansible/SSM → PXC Cluster**

Do not manually create EC2 instances. Everything should be Infrastructure as Code (IaC).

### Target Architecture

```text
GitHub Repository
│
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── vpc.tf
│   ├── subnet.tf
│   ├── securitygroup.tf
│   ├── ec2.tf
│   ├── ebs.tf
│   ├── nlb.tf
│   ├── iam.tf
│   └── terraform.tfvars
│
├── ansible/
│   ├── inventory
│   ├── playbook.yml
│   └── roles/
│       ├── pxc/
│       └── proxysql/
│
├── scripts/
│   ├── bootstrap.sh
│   ├── mysql_secure.sh
│   └── healthcheck.sh
│
├── .github/
│   └── workflows/
│       ├── terraform-plan.yml
│       └── terraform-apply.yml
│
└── docs/
    ├── architecture.png
    └── deployment-guide.md
```

---

# AWS Infrastructure

### VPC Design

```text
VPC 10.10.0.0/16

├── Private-DB-Subnet-AZ1
│      10.10.1.0/24
│
├── Private-DB-Subnet-AZ2
│      10.10.2.0/24
│
├── Private-DB-Subnet-AZ3
│      10.10.3.0/24
│
├── Public-Management-Subnet-AZ1
│      10.10.10.0/24
│
└── Public-Management-Subnet-AZ2
       10.10.11.0/24
```

---

# EC2 Layout

```text
pxc-node1   10.10.1.10
pxc-node2   10.10.2.10
pxc-node3   10.10.3.10

proxysql1   10.10.10.10
proxysql2   10.10.11.10
```

Deploy across 3 Availability Zones.

```text
us-east-1a
us-east-1b
us-east-1c
```

---

# Storage Design

Use dedicated EBS volumes.

```text
Node1
 ├── Root Volume
 └── EBS Data Volume

Node2
 ├── Root Volume
 └── EBS Data Volume

Node3
 ├── Root Volume
 └── EBS Data Volume
```

Terraform creates:

```hcl
aws_ebs_volume

aws_volume_attachment

aws_instance
```

Mount point:

```bash
/data/mysql
```

MySQL Datadir:

```bash
/data/mysql
```

---

# Security Groups

### MySQL

```text
3306
```

### Galera Replication

```text
4567
4568
4444
```

### SSH

```text
22
```

### ProxySQL

```text
6032
6033
```

### ICMP

```text
Ping
```

---

# AWS Resources Created

Terraform provisions:

```text
VPC
Subnets
Route Tables
Internet Gateway
NAT Gateway
Security Groups
EC2 Instances
EBS Volumes
IAM Roles
Network Load Balancer
CloudWatch Alarms
S3 Bucket
Elastic IPs
```

---

# Terraform Deployment Flow

```text
terraform init

terraform fmt

terraform validate

terraform plan

terraform apply
```

---

# PXC Cluster Bootstrap

### Node1

```bash
systemctl stop mysql

systemctl start mysql@bootstrap.service
```

Verify:

```sql
show status like 'wsrep_cluster_size';
```

Output:

```text
1
```

---

### Node2

```bash
systemctl start mysql
```

---

### Node3

```bash
systemctl start mysql
```

---

Verify Cluster

```sql
show status like 'wsrep_cluster_size';
```

Output:

```text
3
```

---

# ProxySQL Layer

### ProxySQL Servers

```text
proxysql1
proxysql2
```

Configured for:

```text
Read/Write Split

Automatic Failover

Connection Pooling

Query Routing
```

---

# Load Balancer Design

Use AWS NLB.

```text
Network Load Balancer
          |
    ----------------
    |              |
ProxySQL1      ProxySQL2
```

Application connects only to:

```text
pxc-prod.company.com
```

Never directly to MySQL.

---

# Backup Strategy

Use Percona XtraBackup.

```bash
xtrabackup --backup
```

Upload backups to:

```text
Amazon S3
```

Example:

```text
pxc-prod-backup
```

Lifecycle Policy:

```text
30 Days
90 Days
180 Days
365 Days
```

---

# Monitoring

### CloudWatch

```text
CPU

Memory

Disk Usage

Network

EBS IOPS
```

### PMM

```text
Percona Monitoring and Management
```

Components:

```text
PMM Server

PMM Client
```

---

# Production Storage Layout

```text
/data/mysql

/data/mysql/log

/data/mysql/binlog

/data/mysql/backup
```

Recommended:

```text
EBS-1 → Datadir

EBS-2 → Backup

EBS-3 → Binary Logs
```

---

# GitHub Actions CI/CD

### terraform-plan.yml

```text
Developer Push
        ↓
Terraform Init
        ↓
Terraform Validate
        ↓
Terraform Plan
```

---

### terraform-apply.yml

```text
Merge to Main
        ↓
Terraform Apply
        ↓
AWS Infrastructure
        ↓
Ansible Deployment
        ↓
PXC Installation
        ↓
ProxySQL Configuration
```

---

# High Availability Architecture

```text
                    AWS NLB
                       |
        --------------------------------
        |                              |
    ProxySQL1                     ProxySQL2
        |                              |
        --------------------------------
                       |
    ------------------------------------------------
    |                      |                       |
PXC Node1             PXC Node2              PXC Node3
AZ-1                  AZ-2                   AZ-3
```

---

# Disaster Recovery (Optional)

```text
Primary Region
   us-east-1
        |
        |
Async Replica
        |
        |
Secondary Region
   us-west-2
```

---

# GitHub Repository Structure

```text
pxc-aws-terraform/
│
├── terraform/
├── ansible/
├── scripts/
├── docs/
├── .github/workflows/
│
├── README.md
├── LICENSE
└── .gitignore
```

### Enterprise Deployment Flow

```text
GitHub
   ↓
GitHub Actions
   ↓
Terraform
   ↓
AWS VPC
   ↓
EC2 + EBS
   ↓
Percona XtraDB Cluster
   ↓
ProxySQL
   ↓
NLB
   ↓
Application
```

This is the typical production-grade AWS architecture used for self-managed Percona XtraDB Cluster instead of Amazon RDS/Aurora.
