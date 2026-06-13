### Setup-6 : Server Preparation for Percona XtraDB Cluster

### Current Status

```text
Setup-1  AWS Access                    ✅
Setup-2  Terraform Backend             ✅
Setup-3  VPC + Subnets                 ✅
Setup-4  Network + Security            ✅
Setup-5  EC2 + EBS + IAM               ✅

Setup-6  Server Preparation            🔄
```

---

# Setup-6.1 : Verify EC2 Connectivity

### Login to ProxySQL1

```bash
ssh -i ~/.ssh/id_rsa ec2-user@100.59.2.106
```

### Login to PXC1

```bash
ssh -i ~/id_rsa ec2-user@10.10.1.97
```

### Verify

```bash
hostname
```

Expected:

```text
ip-10-10-1-97.ec2.internal
```

Status:

```text
PXC1 Access Verified ✅
```

---

# Setup-6.2 : Prepare Storage

Perform on:

```text
PXC1
PXC2
PXC3
```

### Verify Disk

```bash
lsblk
```

Expected:

```text
nvme0n1   10G   Root Disk
nvme1n1   25G   EBS Disk
```

### Format

```bash
sudo mkfs.xfs /dev/nvme1n1
```

### Create Mount Point

```bash
sudo mkdir -p /data/mysql
```

### Mount

```bash
sudo mount /dev/nvme1n1 /data/mysql
```

### Get UUID

```bash
sudo blkid /dev/nvme1n1
```

Example:

```text
UUID=8cde015a-9058-4f3c-9fae-54d1c7ca551e
```

### Add to fstab

```bash
sudo vi /etc/fstab
```

Add:

```text
UUID=<UUID> /data/mysql xfs defaults,nofail 0 0
```

### Test

```bash
sudo umount /data/mysql

sudo mount -a

df -h | grep mysql
```

Expected:

```text
/dev/nvme1n1 25G ... /data/mysql
```

Status:

```text
PXC1 Storage ✅
PXC2 Storage ⏳
PXC3 Storage ⏳
```

---

# Setup-6.3 : OS Preparation

Perform on:

```text
PXC1
PXC2
PXC3
```

### Update OS

```bash
sudo dnf update -y
```

### Install Packages

```bash
sudo dnf install -y \
wget \
vim \
rsync \
socat \
net-tools \
xfsprogs
```

### Verify

```bash
which rsync
which socat
```

Expected:

```text
/usr/bin/rsync
/usr/bin/socat
```

---

# Setup-6.4 : Network Validation

From PXC1

```bash
nc -zv 10.10.2.169 22

nc -zv 10.10.3.132 22
```

Expected:

```text
Connected
```

From PXC2

```bash
nc -zv 10.10.1.97 22

nc -zv 10.10.3.132 22
```

Expected:

```text
Connected
```

From PXC3

```bash
nc -zv 10.10.1.97 22

nc -zv 10.10.2.169 22
```

Expected:

```text
Connected
```

---

# Setup-6 Completion Checklist

### PXC1

```text
SSH Access            ✅
25GB Mounted          ✅
fstab Configured      ✅
OS Packages Installed ⏳
```

### PXC2

```text
SSH Access            ⏳
25GB Mounted          ⏳
fstab Configured      ⏳
OS Packages Installed ⏳
```

### PXC3

```text
SSH Access            ⏳
25GB Mounted          ⏳
fstab Configured      ⏳
OS Packages Installed ⏳
```

---

# Setup-7 (Next)

After Setup-6 is complete:

```text
Install Percona Repository
Install Percona XtraDB Cluster
Configure my.cnf
Bootstrap PXC1
Join PXC2
Join PXC3
Verify wsrep_cluster_size=3
```

At this moment, your **PXC1 Storage Preparation is already completed successfully**. The next practical task is to repeat **Setup-6.2** on **PXC2 and PXC3**, then perform **Setup-6.3 (OS Preparation)** on all three nodes.
