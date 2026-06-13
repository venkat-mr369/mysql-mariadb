### Setup-4 : Route Tables, NAT Gateway and Security Groups

#### Objective

Configure network routing and security controls for the Percona XtraDB Cluster (PXC) environment.

This phase creates:

- Elastic IP
- NAT Gateway
- Public Route Table
- Private Route Table
- Route Table Associations
- Security Group

These components provide:

- Internet access for public resources
- Outbound Internet access for private database servers
- Secure communication between PXC nodes
- Secure communication between ProxySQL and PXC

---

### Terraform Files Used in This Phase

| File | Purpose |
|--------|---------|
| nat_gateway.tf | Create Elastic IP and NAT Gateway |
| route_tables.tf | Create Public and Private Route Tables |
| security_groups.tf | Create Security Groups |
| outputs.tf | Output Network and Security Information |

---

### Components Created in This Phase

```text
Elastic IP

NAT Gateway

Public Route Table

Private Route Table

Route Table Associations

PXC Security Group
```

---

### Network Architecture After Setup-4

```text
                                   Internet
                                       |
                                       |
                               Internet Gateway
                                       |
                  -----------------------------------------
                  |                                       |
                  |                                       |
          Public Route Table                     Private Route Table
                  |                                       |
        ----------------------                  ------------------------
        |                    |                  |          |           |
        |                    |                  |          |           |
 Public Subnet AZ1    Public Subnet AZ2      DB AZ1     DB AZ2      DB AZ3
 10.10.10.0/24         10.10.11.0/24       10.10.1    10.10.2     10.10.3

        |                    |
        |                    |
   ProxySQL1            ProxySQL2
        |
        |
   NAT Gateway
```

---

### Why Public and Private Subnets Are Required

#### Public Subnets

Used For:

```text
ProxySQL

Network Load Balancer

NAT Gateway

Bastion Host (Optional)
```

Reason:

```text
These resources require communication
with applications or the Internet.
```

---

#### Private Subnets

Used For:

```text
PXC Node1

PXC Node2

PXC Node3
```

Reason:

```text
Database servers should never
be directly exposed to the Internet.
```

Benefits:

```text
No Public IP

Improved Security

Reduced Attack Surface

Production Best Practice
```

---

### Database Server Internet Access Flow

Private servers require:

```text
Operating System Updates

Percona Package Downloads

Monitoring Agent Installation

Security Updates

Backup Agent Installation
```

Traffic Flow:

```text
PXC Node
    |
Private DB Subnet
    |
Private Route Table
    |
NAT Gateway
    |
Public Route Table
    |
Internet Gateway
    |
Internet
```

Example:

```text
PXC Node1
10.10.1.10
    |
db-subnet-az1
    |
private-route-table
    |
nat-gateway
    |
internet-gateway
    |
repo.percona.com
```

---

### Application Access Flow

```text
Application
     |
Network Load Balancer
     |
ProxySQL
     |
Percona XtraDB Cluster
```

Example:

```text
Application
     |
NLB
     |
ProxySQL1 / ProxySQL2
     |
PXC Node1
PXC Node2
PXC Node3
```

---

### Why NAT Gateway is Required

PXC Nodes are deployed in private subnets.

Private subnets cannot directly access the Internet.

However database servers still need:

- OS package updates
- Percona package downloads
- Monitoring agent installation
- Security updates

Benefits:

```text
No Public IP on Database Servers

Outbound Internet Access Available

Improved Security

Production Architecture
```

---

### Why Route Tables are Required

Route tables determine how traffic flows inside the VPC.

We need:

```text
Public Route Table

Private Route Table
```

---

### Public Route Table

Used By:

```text
ProxySQL1

ProxySQL2

NAT Gateway

Network Load Balancer
```

Route:

```text
0.0.0.0/0
    |
Internet Gateway
```

---

### Private Route Table

Used By:

```text
PXC Node1

PXC Node2

PXC Node3
```

Route:

```text
0.0.0.0/0
    |
NAT Gateway
```

---

### Why Security Groups are Required

Security Groups act as virtual firewalls.

Control:

```text
Who can connect

Which port

Which protocol
```

---

### Required Ports

#### SSH

```text
22
```

Purpose:

```text
Administration
```

---

#### MySQL

```text
3306
```

Purpose:

```text
Application Connections

ProxySQL Connections
```

---

#### SST (State Snapshot Transfer)

```text
4444
```

Purpose:

```text
Initial Node Synchronization
```

---

#### Galera Replication

```text
4567
```

Purpose:

```text
Cluster Communication
```

---

#### Incremental State Transfer

```text
4568
```

Purpose:

```text
Incremental Node Synchronization
```

---

#### ProxySQL Admin

```text
6032
```

Purpose:

```text
ProxySQL Administration
```

---

#### ProxySQL Client Port

```text
6033
```

Purpose:

```text
Application Connections
```

---

### Create File : nat_gateway.tf

```hcl
resource "aws_eip" "nat_eip" {

  domain = "vpc"

  tags = {
    Name = "pxc-nat-eip"
  }
}

resource "aws_nat_gateway" "nat_gw" {

  allocation_id = aws_eip.nat_eip.id

  subnet_id = aws_subnet.public_subnet_az1.id

  tags = {
    Name = "pxc-nat-gateway"
  }

  depends_on = [
    aws_internet_gateway.pxc_igw
  ]
}
```

---

### Create File : route_tables.tf

```hcl
resource "aws_route_table" "public_rt" {

  vpc_id = aws_vpc.pxc_vpc.id

  route {

    cidr_block = "0.0.0.0/0"

    gateway_id = aws_internet_gateway.pxc_igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route_table" "private_rt" {

  vpc_id = aws_vpc.pxc_vpc.id

  route {

    cidr_block = "0.0.0.0/0"

    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = "private-route-table"
  }
}

resource "aws_route_table_association" "public_assoc_az1" {

  subnet_id = aws_subnet.public_subnet_az1.id

  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_assoc_az2" {

  subnet_id = aws_subnet.public_subnet_az2.id

  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "private_assoc_az1" {

  subnet_id = aws_subnet.db_subnet_az1.id

  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_assoc_az2" {

  subnet_id = aws_subnet.db_subnet_az2.id

  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_assoc_az3" {

  subnet_id = aws_subnet.db_subnet_az3.id

  route_table_id = aws_route_table.private_rt.id
}
```

---

### Create File : security_groups.tf

```hcl
resource "aws_security_group" "pxc_sg" {

  name        = "pxc-security-group"

  description = "Percona XtraDB Cluster Security Group"

  vpc_id = aws_vpc.pxc_vpc.id

  ingress {

    from_port = 22

    to_port = 22

    protocol = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {

    from_port = 3306

    to_port = 3306

    protocol = "tcp"

    cidr_blocks = ["10.10.0.0/16"]
  }

  ingress {

    from_port = 4444

    to_port = 4444

    protocol = "tcp"

    cidr_blocks = ["10.10.0.0/16"]
  }

  ingress {

    from_port = 4567

    to_port = 4568

    protocol = "tcp"

    cidr_blocks = ["10.10.0.0/16"]
  }

  egress {

    from_port = 0

    to_port = 0

    protocol = "-1"

    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {

    Name = "pxc-sg"
  }
}
```

---

### Update File : outputs.tf

```hcl
output "vpc_id" {
  value = aws_vpc.pxc_vpc.id
}

output "public_subnet_az1" {
  value = aws_subnet.public_subnet_az1.id
}

output "public_subnet_az2" {
  value = aws_subnet.public_subnet_az2.id
}

output "db_subnet_az1" {
  value = aws_subnet.db_subnet_az1.id
}

output "db_subnet_az2" {
  value = aws_subnet.db_subnet_az2.id
}

output "db_subnet_az3" {
  value = aws_subnet.db_subnet_az3.id
}

output "pxc_security_group" {
  value = aws_security_group.pxc_sg.id
}
```

---

### Format Terraform Files

```bash
terraform fmt
```

Expected Output:

```text
nat_gateway.tf

route_tables.tf

security_groups.tf

outputs.tf
```

---

### Validate Configuration

```bash
terraform validate
```

Expected Output:

```text
Success! The configuration is valid.
```

---

### Review Execution Plan

```bash
terraform plan
```

Expected Resources:

```text
aws_eip.nat_eip

aws_nat_gateway.nat_gw

aws_route_table.public_rt

aws_route_table.private_rt

aws_route_table_association.public_assoc_az1

aws_route_table_association.public_assoc_az2

aws_route_table_association.private_assoc_az1

aws_route_table_association.private_assoc_az2

aws_route_table_association.private_assoc_az3

aws_security_group.pxc_sg
```

Total:

```text
10 Resources
```

---

### Deploy Infrastructure

```bash
terraform apply
```

Expected Output:

```text
Apply complete!

Resources: 17 added, 0 changed, 0 destroyed.
```

---

### Actual Outputs Generated

```text
db_subnet_az1 = subnet-01b7cfce27eeeb25b

db_subnet_az2 = subnet-0df2d9b2aac8dbcb6

db_subnet_az3 = subnet-0a408be872dd48077

public_subnet_az1 = subnet-04460a2a8ea159152

public_subnet_az2 = subnet-0174d924ce54ef660

pxc_security_group = sg-02d9982fa520005fc

vpc_id = vpc-008a34cad804e31c3
```

---

### Verify Terraform State

```bash
terraform state list
```

Expected:

```text
17 Resources Managed by Terraform
```

---

### Verify NAT Gateway

```bash
aws ec2 describe-nat-gateways --output table
```

Expected:

```text
State = available
```

---

### Verify Route Tables

```bash
aws ec2 describe-route-tables --output table
```

Expected:

```text
public-route-table

private-route-table
```

---

### Verify Security Group

```bash
aws ec2 describe-security-groups \
--filters Name=group-name,Values=pxc-security-group \
--output table
```

Expected:

```text
pxc-security-group
```

---

### Result

Successfully Created:

- VPC
- Internet Gateway
- Public Subnets
- Private Subnets
- Elastic IP
- NAT Gateway
- Public Route Table
- Private Route Table
- Route Table Associations
- PXC Security Group

Infrastructure is now ready for:

- IAM Role
- SSH Key Pair
- EC2 Instances
- EBS Volumes
- ProxySQL
- Percona XtraDB Cluster

---

### Cost Optimization Note

Production:

```text
Use NAT Gateway
```

Reason:

```text
Managed Service

Highly Available

Production Best Practice
```

Lab Environment:

```text
NAT Gateway can be removed
to reduce AWS cost.
```

---

### Next Activity

### Setup-5

Topics:

- keypair.tf
- iam.tf
- ec2.tf
- ebs.tf
- outputs.tf

Resources:

- PXC Node1
- PXC Node2
- PXC Node3
- ProxySQL1
- ProxySQL2
- EBS Volumes
- IAM Role
- Instance Profile
- SSH Access