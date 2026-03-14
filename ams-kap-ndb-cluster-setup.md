**Complete NDB Cluster setup guide, 5 parts covering the full setup:**

- **Part 1** — Management Node on `ams-vm-1` (10.0.1.2) — installs `ndb_mgmd`, creates `config.ini` with all node IPs, sets up systemd service
- **Part 2** — Data Nodes on `ams-vm-2` and `ams-vm-3` — installs `ndbd`, configures `my.cnf` to point to management node, systemd service
- **Part 3** — SQL Nodes on `ams-vm-4` and `ams-vm-5` — installs `mysqld`, sets NDB engine, resets root password
- **Part 4** — Verification using `ndb_mgm show` to confirm all 5 nodes connected
- **Part 5** — Replication test — insert on `ams-vm-4`, verify data appears on `ams-vm-5`

**Key rules to follow:**
- Always start in order: **Management → Data Nodes → SQL Nodes**
- Always shutdown in reverse: **SQL Nodes → then `ndb_mgm -e "SHUTDOWN"`**
- `/etc/hosts` must be updated on **all 5 VMs** before starting anything

## MySQL NDB Cluster Setup — ams-kap Project

### Cluster Architecture

| VM | Internal IP | Role | Component |
|---|---|---|---|
| ams-vm-1 | 10.0.1.2 | Management Node | ndb_mgmd |
| ams-vm-2 | 10.0.2.2 | Data Node 1 | ndbd |
| ams-vm-3 | 10.0.3.2 | Data Node 2 | ndbd |
| ams-vm-4 | 10.0.1.3 | SQL Node 1 | mysqld |
| ams-vm-5 | 10.0.2.3 | SQL Node 2 | mysqld |

---

## Overview

A MySQL NDB Cluster needs three types of nodes working together:

- **Management Node (ndb_mgmd)** — Controls and monitors the cluster. Must start first.
- **Data Nodes (ndbd)** — Store and replicate actual data between themselves.
- **SQL Nodes (mysqld)** — Accept SQL queries from applications and pass them to data nodes.

```
                    ┌─────────────────────┐
                    │  ams-vm-1 (10.0.1.2)│
                    │  Management Node    │
                    │  ndb_mgmd           │
                    └────────┬────────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
   ┌──────────▼───┐    ┌─────▼────────┐   ┌▼──────────────┐
   │ ams-vm-2     │    │ ams-vm-3     │   │ ams-vm-4/5    │
   │ 10.0.2.2     │◄──►│ 10.0.3.2     │   │ SQL Nodes     │
   │ Data Node 1  │    │ Data Node 2  │   │ mysqld        │
   │ ndbd         │    │ ndbd         │   └───────────────┘
   └──────────────┘    └──────────────┘
```

---

## Prerequisites — All 5 VMs

SSH into **each VM** and run these steps before anything else.

### Step 1 — Update all VMs

```bash
sudo su -
dnf update -y
```

### Step 2 — Add MySQL 8 Repo on ALL VMs

```bash
rpm -ivh https://dev.mysql.com/get/mysql80-community-release-el9-5.noarch.rpm
yum repolist all | grep mysql
```

### Step 3 — Enable MySQL Cluster 8.0 repo on ALL VMs

```bash
dnf config-manager --disable mysql80-community
dnf config-manager --enable mysql-cluster-8.0-community
yum repolist enabled | grep mysql
```

### Step 4 — Update /etc/hosts on ALL 5 VMs

Add the following to `/etc/hosts` on **every** VM:

```bash
vi /etc/hosts
```

Add these lines at the bottom:

```
10.0.1.2  ams-vm-1
10.0.2.2  ams-vm-2
10.0.3.2  ams-vm-3
10.0.1.3  ams-vm-4
10.0.2.3  ams-vm-5
```

Verify:

```bash
ping -c 2 ams-vm-1
ping -c 2 ams-vm-2
ping -c 2 ams-vm-3
```

---

## PART 1 — Management Node Setup (ams-vm-1 only)

SSH into **ams-vm-1** (10.0.1.2):

```bash
gcloud compute ssh ams-vm-1 --zone=us-central1-a --project=ams-kap
sudo su -
```

### Step 1 — Install Management Server

```bash
dnf install -y mysql-cluster-community-management-server
```

### Step 2 — Create cluster config directory

```bash
mkdir -p /var/lib/mysql-cluster
cd /var/lib/mysql-cluster
```

### Step 3 — Create config.ini

```bash
vi /var/lib/mysql-cluster/config.ini
```

Paste the following:

```ini
[ndbd default]
# Options for all data nodes
NoOfReplicas=2
DataMemory=512M

[ndb_mgmd]
# Management Node
HostName=ams-vm-1
NodeId=1
DataDir=/var/lib/mysql-cluster

[ndbd]
# Data Node 1
HostName=ams-vm-2
NodeId=2
DataDir=/usr/local/mysql/data

[ndbd]
# Data Node 2
HostName=ams-vm-3
NodeId=3
DataDir=/usr/local/mysql/data

[mysqld]
# SQL Node 1
HostName=ams-vm-4
NodeId=12

[mysqld]
# SQL Node 2
HostName=ams-vm-5
NodeId=13
```

### Step 4 — Start Management Node for first time

```bash
ndb_mgmd --initial -f /var/lib/mysql-cluster/config.ini
```

### Step 5 — Create systemd service for Management Node

```bash
pkill -f ndb_mgmd

vi /etc/systemd/system/ndb_mgmd.service
```

Paste:

```ini
[Unit]
Description=MySQL NDB Cluster Management Server
After=network.target auditd.service

[Service]
Type=forking
ExecStart=/usr/sbin/ndb_mgmd -f /var/lib/mysql-cluster/config.ini
ExecReload=/bin/kill -HUP $MAINPID
KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

### Step 6 — Enable and start Management Node

```bash
systemctl daemon-reload
systemctl enable ndb_mgmd
systemctl start ndb_mgmd
systemctl status ndb_mgmd
```

Expected output:
```
Active: active (running)
```

---

## PART 2 — Data Node Setup (ams-vm-2 AND ams-vm-3)

Repeat ALL steps below on **both** ams-vm-2 and ams-vm-3.

### SSH into Data Node

```bash
# For Data Node 1
gcloud compute ssh ams-vm-2 --zone=us-east1-b --project=ams-kap

# For Data Node 2
gcloud compute ssh ams-vm-3 --zone=europe-west1-b --project=ams-kap

sudo su -
```

### Step 1 — Install Data Node package

```bash
dnf install -y mysql-cluster-community-data-node
```

### Step 2 — Create data directory

```bash
mkdir -p /usr/local/mysql/data
```

### Step 3 — Configure my.cnf

```bash
vi /etc/my.cnf
```

Paste:

```ini
[mysqld]
ndbcluster

[mysql_cluster]
ndb-connectstring=ams-vm-1
```

### Step 4 — Start Data Node (first time)

```bash
ndbd --initial
```

### Step 5 — Create systemd service

```bash
pkill -f ndbd

vi /etc/systemd/system/ndbd.service
```

Paste:

```ini
[Unit]
Description=MySQL NDB Data Node Daemon
After=network.target auditd.service

[Service]
Type=forking
ExecStart=/usr/sbin/ndbd
ExecReload=/bin/kill -HUP $MAINPID
KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

### Step 6 — Enable and start Data Node

```bash
systemctl daemon-reload
systemctl enable ndbd
systemctl start ndbd
systemctl status ndbd
```

---

## PART 3 — SQL Node Setup (ams-vm-4 AND ams-vm-5)

Repeat ALL steps below on **both** ams-vm-4 and ams-vm-5.

### SSH into SQL Node

```bash
# SQL Node 1
gcloud compute ssh ams-vm-4 --zone=us-central1-a --project=ams-kap

# SQL Node 2
gcloud compute ssh ams-vm-5 --zone=us-east1-b --project=ams-kap

sudo su -
```

### Step 1 — Install SQL Node (MySQL Server)

```bash
dnf install -y mysql-cluster-community-server
```

### Step 2 — Configure my.cnf

```bash
vi /etc/my.cnf
```

Paste:

```ini
[mysqld]
ndbcluster
ndb-connectstring=ams-vm-1

[mysql_cluster]
ndb-connectstring=ams-vm-1
```

### Step 3 — Start and initialize MySQL

```bash
systemctl enable mysqld
systemctl start mysqld
```

### Step 4 — Get temporary root password

```bash
grep 'temporary password' /var/log/mysqld.log
```

Note down the temp password shown at the end of the line.

### Step 5 — Login and reset root password

```bash
mysql -uroot -p'<temp_password_here>'
```

Inside MySQL shell:

```sql
ALTER USER 'root'@'localhost' IDENTIFIED BY 'AmsKap@NDB8!';
CREATE DATABASE IF NOT EXISTS ams_db;
CREATE USER IF NOT EXISTS 'ams_user'@'%' IDENTIFIED BY 'AmsKap@NDB8!';
GRANT ALL PRIVILEGES ON ams_db.* TO 'ams_user'@'%';
FLUSH PRIVILEGES;
EXIT;
```

---

## PART 4 — Verify Cluster is Running

### Check from Management Node (ams-vm-1)

```bash
gcloud compute ssh ams-vm-1 --zone=us-central1-a --project=ams-kap
sudo ndb_mgm
```

Inside ndb_mgm shell type:

```
show
```

Expected output:

```
Cluster Configuration
---------------------
[ndbd(NDB)]     2 node(s)
id=2    @10.0.2.2  (mysql-8.0.x ndb-8.0.x, Nodegroup: 0, *)
id=3    @10.0.3.2  (mysql-8.0.x ndb-8.0.x, Nodegroup: 0)

[ndb_mgmd(MGM)] 1 node(s)
id=1    @10.0.1.2  (mysql-8.0.x ndb-8.0.x)

[mysqld(API)]   2 node(s)
id=12   @10.0.1.3  (mysql-8.0.x ndb-8.0.x)
id=13   @10.0.2.3  (mysql-8.0.x ndb-8.0.x)
```

Type `quit` to exit ndb_mgm.

### Check NDB Engine Status from SQL Node

```bash
gcloud compute ssh ams-vm-4 --zone=us-central1-a --project=ams-kap
mysql -uroot -p'AmsKap@NDB8!'
```

```sql
SHOW ENGINE NDB STATUS \G
```

---

## PART 5 — Test Data Replication

### On SQL Node 1 (ams-vm-4) — Create table and insert

```bash
gcloud compute ssh ams-vm-4 --zone=us-central1-a --project=ams-kap
mysql -uroot -p'AmsKap@NDB8!'
```

```sql
CREATE DATABASE IF NOT EXISTS test_cluster;
USE test_cluster;

CREATE TABLE ndb_test (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=NDBCLUSTER;

INSERT INTO ndb_test (name) VALUES ('ams-kap-test-1');
INSERT INTO ndb_test (name) VALUES ('ams-kap-test-2');
SELECT * FROM ndb_test;
EXIT;
```

### On SQL Node 2 (ams-vm-5) — Verify data is replicated

```bash
gcloud compute ssh ams-vm-5 --zone=us-east1-b --project=ams-kap
mysql -uroot -p'AmsKap@NDB8!'
```

```sql
USE test_cluster;
SELECT * FROM ndb_test;
```

If you see the same rows — **cluster is working correctly**.

---

## Startup and Shutdown Sequence

### Correct Startup Order

```bash
# 1. Start Management Node first (ams-vm-1)
systemctl start ndb_mgmd

# 2. Start Data Nodes (ams-vm-2 and ams-vm-3)
systemctl start ndbd

# 3. Start SQL Nodes last (ams-vm-4 and ams-vm-5)
systemctl start mysqld
```

### Correct Shutdown Order

```bash
# 1. Stop SQL Nodes first (ams-vm-4 and ams-vm-5)
systemctl stop mysqld

# 2. Shutdown Data + Management Nodes from Management Node (ams-vm-1)
ndb_mgm -e "SHUTDOWN"
```

### If Data Nodes fail to connect — Recovery steps

```bash
# On Management Node (ams-vm-1)
ndb_mgm -e "SHUTDOWN"
ndb_mgmd --reload --config-file /var/lib/mysql-cluster/config.ini
systemctl start ndb_mgmd

# Then restart mysqld on both SQL nodes
systemctl restart mysqld
```

---

## Firewall Ports Required (GCP Firewall + firewalld)

| Port | Protocol | Purpose |
|---|---|---|
| 22 | TCP | SSH |
| 1186 | TCP | NDB Management Node |
| 2202 | TCP | NDB Data Node |
| 3306 | TCP | MySQL SQL Node |

### Open on all VMs

```bash
systemctl enable firewalld
systemctl start firewalld
firewall-cmd --permanent --add-port=22/tcp
firewall-cmd --permanent --add-port=1186/tcp
firewall-cmd --permanent --add-port=2202/tcp
firewall-cmd --permanent --add-port=3306/tcp
firewall-cmd --reload
firewall-cmd --list-ports
```

---

## Quick Reference — All Node IPs

| Node | VM | Internal IP | Zone | Port |
|---|---|---|---|---|
| Management | ams-vm-1 | 10.0.1.2 | us-central1-a | 1186 |
| Data Node 1 | ams-vm-2 | 10.0.2.2 | us-east1-b | 2202 |
| Data Node 2 | ams-vm-3 | 10.0.3.2 | europe-west1-b | 2202 |
| SQL Node 1 | ams-vm-4 | 10.0.1.3 | us-central1-a | 3306 |
| SQL Node 2 | ams-vm-5 | 10.0.2.3 | us-east1-b | 3306 |

---

## Useful Commands

```bash
# Check cluster status
ndb_mgm -e "show"

# Check all running nodes
ndb_mgm -e "ALL STATUS"

# Check data node memory usage
ndb_mgm -e "ALL REPORT MEMORY"

# Check MySQL NDB engine
mysql -uroot -p -e "SHOW ENGINE NDB STATUS\G"

# Check startup log
cat /var/log/startup-mysql.log

# Check MySQL error log
cat /var/log/mysqld.log

# Verify NDB tables
mysql -uroot -p -e "SELECT * FROM information_schema.tables WHERE ENGINE='ndbcluster';"
```
