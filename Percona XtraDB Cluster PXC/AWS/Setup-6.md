Yes, that's exactly what I would do now, Venkata. 👍

Since the infrastructure is already created, let's **pivot Setup-6 to Ansible** and follow a production-style approach.

### Revised Roadmap

```text id="x01"
Terraform (Completed)
---------------------
Setup-1  AWS Access
Setup-2  Backend
Setup-3  VPC + Subnets
Setup-4  Network + Security
Setup-5  EC2 + EBS + IAM

Ansible (Starting Now)
----------------------
Setup-6  Storage + OS Preparation
Setup-7  PXC Installation
Setup-8  ProxySQL Installation
Setup-9  Validation
Setup-10 GitHub Actions CI/CD
```

---
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

Instead of manually repeating commands on:

```text id="x02"
PXC1
PXC2
PXC3
```

we will create:

```text id="x03"
ansible/

├── inventory
├── ansible.cfg
├── playbook.yml

└── roles
    └── storage
        ├── tasks
        │   └── main.yml
        └── defaults
```

---

## What Storage Role Will Do

Automatically on all PXC nodes:

```text id="x04"
Format /dev/nvme1n1

Create /data/mysql

Mount filesystem

Update /etc/fstab

Install:
  wget
  vim
  rsync
  socat
  net-tools
  xfsprogs
```

---

## First Question

Where will Ansible run?

### Option A

Your laptop

```text id="x05"
Windows
   |
Ansible
   |
ProxySQL1
   |
PXC Nodes
```

Not ideal on Windows.

### Option B (Recommended)

Use ProxySQL1 as Ansible Control Node.

```text id="x06"
ProxySQL1
   |
Ansible
   |
PXC1
PXC2
PXC3
```

This is simpler and closer to real-world Linux administration.

---

## My Recommendation

Use:

```text id="x07"
ProxySQL1
```

as the Ansible Control Node.

We'll:

### Step 1

SSH to ProxySQL1

```bash id="x08"
ssh -i ~/.ssh/id_rsa ec2-user@100.59.2.106
```

### Step 2

Install Ansible

```bash id="x09"
sudo dnf update -y

sudo dnf install -y ansible-core git
```

Verify:

```bash id="x10"
ansible --version
```

### Step 3

Create project structure

```bash id="x11"
mkdir -p ~/ansible-pxc

cd ~/ansible-pxc
```

### Step 4

Create inventory

```ini id="x12"
[pxc]
10.10.1.97
10.10.2.169
10.10.3.132

[all:vars]
ansible_user=ec2-user
ansible_ssh_private_key_file=/home/ec2-user/id_rsa
```

### Step 5

Test connectivity

```bash id="x13"
ansible pxc -i inventory -m ping
```

Expected:

```text id="x14"
10.10.1.97 | SUCCESS
10.10.2.169 | SUCCESS
10.10.3.132 | SUCCESS
```

---

### Important

Before creating any playbooks, let's verify Ansible can reach all 3 PXC nodes.

On **ProxySQL1**, run:

```bash id="x15"
sudo dnf install -y ansible-core git

ansible --version
```

Send me the output, and then we'll build the complete **Setup-6 Ansible role** for storage and OS preparation. 🚀
