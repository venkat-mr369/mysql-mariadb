````md
### Setup-3 : AWS VPC and Subnet Configuration for Percona XtraDB Cluster

#### Objective

Create the foundational AWS networking components required for deploying a highly available Percona XtraDB Cluster (PXC).

This phase creates:

- VPC
- Internet Gateway
- Public Subnets
- Private Database Subnets

These resources will be used later by:

- PXC Node1
- PXC Node2
- PXC Node3
- ProxySQL1
- ProxySQL2
- Network Load Balancer (NLB)

---

### Network Architecture

```text
VPC : 10.10.0.0/16

├── Public Subnet AZ1
│      10.10.10.0/24
│
├── Public Subnet AZ2
│      10.10.11.0/24
│
├── Private DB Subnet AZ1
│      10.10.1.0/24
│
├── Private DB Subnet AZ2
│      10.10.2.0/24
│
└── Private DB Subnet AZ3
       10.10.3.0/24
```

---

### Why We Need a VPC

A Virtual Private Cloud (VPC) provides an isolated network inside AWS.

Benefits:

- Network isolation
- Custom IP addressing
- Security control
- High availability design
- Multi-AZ deployment support

CIDR Selected:

```text
10.10.0.0/16
```

Available IP Range:

```text
10.10.0.1 - 10.10.255.254
```

Total Available Addresses:

```text
65,536 IP Addresses
```

---

### Why Public Subnets Are Required

Public subnets are used for resources that need Internet access.

Examples:

```text
ProxySQL Servers
NAT Gateway
Load Balancer
Bastion Host (optional)
```

Characteristics:

```text
Can have Public IP
Can communicate with Internet
Route through Internet Gateway
```

Subnets:

| Subnet | CIDR | AZ |
|----------|---------|---------|
| public-subnet-az1 | 10.10.10.0/24 | us-east-1a |
| public-subnet-az2 | 10.10.11.0/24 | us-east-1b |

---

### Why Private Subnets Are Required

Database servers should never be exposed directly to the Internet.

Security Best Practice:

```text
Application
    |
ProxySQL
    |
Percona XtraDB Cluster
```

Not:

```text
Internet
    |
MySQL Database
```

Characteristics:

```text
No Public IP
No Direct Internet Access
Accessible only through approved network paths
Higher Security
```

Subnets:

| Subnet | CIDR | AZ |
|----------|---------|---------|
| db-subnet-az1 | 10.10.1.0/24 | us-east-1a |
| db-subnet-az2 | 10.10.2.0/24 | us-east-1b |
| db-subnet-az3 | 10.10.3.0/24 | us-east-1c |

---

### Why Three Database Subnets

Percona XtraDB Cluster uses three nodes.

Recommended Deployment:

| Node | Availability Zone | Subnet |
|---------|---------|---------|
| PXC Node1 | us-east-1a | 10.10.1.0/24 |
| PXC Node2 | us-east-1b | 10.10.2.0/24 |
| PXC Node3 | us-east-1c | 10.10.3.0/24 |

Benefits:

```text
Zone Failure Protection
High Availability
Quorum Protection
Automatic Failover
```

---

### Terraform File : vpc.tf

```hcl
resource "aws_vpc" "pxc_vpc" {

  cidr_block = "10.10.0.0/16"

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "pxc-vpc"
    Environment = "prod"
  }
}

resource "aws_internet_gateway" "pxc_igw" {

  vpc_id = aws_vpc.pxc_vpc.id

  tags = {
    Name = "pxc-igw"
  }
}
```

---

### Terraform File : subnets.tf

#### Private Subnet AZ1

```hcl
resource "aws_subnet" "db_subnet_az1" {

  vpc_id            = aws_vpc.pxc_vpc.id
  cidr_block        = "10.10.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "db-subnet-az1"
  }
}
```

#### Private Subnet AZ2

```hcl
resource "aws_subnet" "db_subnet_az2" {

  vpc_id            = aws_vpc.pxc_vpc.id
  cidr_block        = "10.10.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "db-subnet-az2"
  }
}
```

#### Private Subnet AZ3

```hcl
resource "aws_subnet" "db_subnet_az3" {

  vpc_id            = aws_vpc.pxc_vpc.id
  cidr_block        = "10.10.3.0/24"
  availability_zone = "us-east-1c"

  tags = {
    Name = "db-subnet-az3"
  }
}
```

#### Public Subnet AZ1

```hcl
resource "aws_subnet" "public_subnet_az1" {

  vpc_id                  = aws_vpc.pxc_vpc.id
  cidr_block              = "10.10.10.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-az1"
  }
}
```

#### Public Subnet AZ2

```hcl
resource "aws_subnet" "public_subnet_az2" {

  vpc_id                  = aws_vpc.pxc_vpc.id
  cidr_block              = "10.10.11.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-az2"
  }
}
```

---

### Terraform File : outputs.tf

```hcl
output "vpc_id" {
  value = aws_vpc.pxc_vpc.id
}
```

---

### Format Terraform Code

Command:

```bash
terraform fmt
```

Expected Output:

```text
vpc.tf
subnets.tf
outputs.tf
```

Status:

```text
Terraform files formatted successfully
```

---

### Validate Configuration

Command:

```bash
terraform validate
```

Expected Output:

```text
Success! The configuration is valid.
```

Status:

```text
Terraform syntax validation successful
```

---

### Review Deployment Plan

Command:

```bash
terraform plan
```

Expected Output:

```text
Plan: 7 to add, 0 to change, 0 to destroy.
```

Resources:

```text
aws_vpc.pxc_vpc

aws_internet_gateway.pxc_igw

aws_subnet.db_subnet_az1
aws_subnet.db_subnet_az2
aws_subnet.db_subnet_az3

aws_subnet.public_subnet_az1
aws_subnet.public_subnet_az2
```

---

### Deploy Infrastructure

Command:

```bash
terraform apply
```

Type:

```text
yes
```

Expected Output:

```text
Apply complete!

Resources: 7 added, 0 changed, 0 destroyed.
```

---

### Verify Terraform State

Command:

```bash
terraform state list
```

Expected Output:

```text
aws_internet_gateway.pxc_igw

aws_subnet.db_subnet_az1
aws_subnet.db_subnet_az2
aws_subnet.db_subnet_az3

aws_subnet.public_subnet_az1
aws_subnet.public_subnet_az2

aws_vpc.pxc_vpc
```

---

### Verify VPC from AWS CLI

Command:

```bash
aws ec2 describe-vpcs \
--filters Name=tag:Name,Values=pxc-vpc \
--output table
```

Expected Output

```text
--------------------------------------------
|               DescribeVpcs               |
+----------------------+-------------------+
| VpcId                | vpc-xxxxxxxx      |
| CidrBlock            | 10.10.0.0/16      |
| State                | available         |
+----------------------+-------------------+
```

---

### Verify Subnets from AWS CLI

Command:

```bash
aws ec2 describe-subnets \
--filters Name=tag:Name,Values=*subnet* \
--output table
```

Expected Output

```text
db-subnet-az1

db-subnet-az2

db-subnet-az3

public-subnet-az1

public-subnet-az2
```

---

### Result

Successfully created:

- 1 VPC
- 1 Internet Gateway
- 3 Private Database Subnets
- 2 Public Subnets

Infrastructure is now ready for:

- Route Tables
- NAT Gateway
- Security Groups
- EC2 Instances
- Percona XtraDB Cluster Deployment

---

### Next Activity

Setup-4.md

Topics:

- Elastic IP
- NAT Gateway
- Public Route Table
- Private Route Table
- Route Associations
- Security Groups
````


