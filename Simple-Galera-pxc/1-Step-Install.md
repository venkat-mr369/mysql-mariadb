### Percona XtraDB Cluster (PXC) 8.0 — Setup

---

## Your Setup

| Node  | Hostname | IP       |
|-------|----------|----------|
| Node1 | ams-vm-1 | 10.0.1.2 |
| Node2 | ams-vm-2 | 10.0.2.2 |
| Node3 | ams-vm-3 | 10.0.3.2 |

**OS:** Oracle Linux 9

---

## What We Are Building

**Percona XtraDB Cluster (Galera-based)**

- Multi-master cluster (all nodes writable)
- Synchronous replication (certification-based)

| InnoDB Cluster | Galera (PXC)         |
|----------------|----------------------|
| Single Primary | Multi Primary        |
| Async-like     | Sync (certification) |
| Router needed  | No router needed     |

---

## STEP 0: Important Understanding

- Galera = multi-master (all nodes writable)
- Needs minimum 3 nodes (quorum)
- Ports used:
  - **3306** — MySQL client
  - **4567** — Galera replication
  - **4444** — SST (State Snapshot Transfer)
  - **4568** — IST (Incremental State Transfer)

---

## STEP 1: Common Setup (ALL 3 NODES)

Set hostname (change per node):

```bash
sudo hostnamectl set-hostname ams-vm-1   # ams-vm-2 on Node2, ams-vm-3 on Node3
```

Update `/etc/hosts` on ALL nodes:

```bash
sudo vi /etc/hosts
```

Add:

```
10.0.1.2 ams-vm-1
10.0.2.2 ams-vm-2
10.0.3.2 ams-vm-3
```

---

## STEP 2: Disable SELinux (ALL NODES — for lab)

```bash
sudo setenforce 0
sudo sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
```

---

## STEP 3: Firewall (ALL NODES)

```bash
sudo systemctl enable firewalld
sudo systemctl start firewalld

sudo firewall-cmd --permanent --add-port=3306/tcp
sudo firewall-cmd --permanent --add-port=4567/tcp
sudo firewall-cmd --permanent --add-port=4568/tcp
sudo firewall-cmd --permanent --add-port=4444/tcp
sudo firewall-cmd --reload
```

---

## STEP 4: Install Percona XtraDB Cluster (ALL NODES)

```bash
sudo dnf install -y https://repo.percona.com/yum/percona-release-latest.noarch.rpm

sudo percona-release setup pxc80

sudo dnf install -y percona-xtradb-cluster
```

---

## STEP 5: Get Temporary Root Password (ONLY Node1)

PXC 8.0 generates a temporary root password during installation.

```bash
sudo systemctl start mysqld
sudo grep 'temporary password' /var/log/mysqld.log
```

Log in and change it:

```bash
mysql -uroot -p
# paste the temporary password
```

```sql
ALTER USER 'root'@'localhost' IDENTIFIED BY 'YourNewRootPass1!';
```

Then stop MySQL:

```bash
sudo systemctl stop mysqld
```

---

## STEP 6: Configure Galera (ALL NODES)

```bash
sudo vi /etc/my.cnf
```

### Common Config (same on all nodes except server-id, node name, node address)

```ini
[mysqld]
server-id=1                          # 1 on Node1, 2 on Node2, 3 on Node3
datadir=/var/lib/mysql
socket=/var/lib/mysql/mysql.sock
log-error=/var/log/mysqld.log
pid-file=/var/run/mysqld/mysqld.pid

binlog_format=ROW
log_bin=binlog
binlog_expire_logs_seconds=604800
default_storage_engine=InnoDB
innodb_autoinc_lock_mode=2

# Galera
wsrep_on=ON
wsrep_provider=/usr/lib64/galera4/libgalera_smm.so
wsrep_cluster_name="pxc-cluster"
wsrep_cluster_address="gcomm://10.0.1.2,10.0.2.2,10.0.3.2"
wsrep_slave_threads=8
wsrep_log_conflicts=ON

# SST
wsrep_sst_method=xtrabackup-v2

# ╔══════════════════════════════════════════════════════════════╗
# ║  REMOVED: wsrep_sst_auth — deprecated/removed in PXC 8.0   ║
# ║  PXC 8.0 handles SST authentication automatically via the   ║
# ║  internal mysql.pxc.sst.user account.                       ║
# ╚══════════════════════════════════════════════════════════════╝

pxc_strict_mode=ENFORCING
pxc-encrypt-cluster-traffic=OFF       # Set to ON in production with proper certs
```

### Node-Specific Lines (change per node)

**Node1 (ams-vm-1):**

```ini
wsrep_node_name="ams-vm-1"
wsrep_node_address="10.0.1.2"
server-id=1
```

**Node2 (ams-vm-2):**

```ini
wsrep_node_name="ams-vm-2"
wsrep_node_address="10.0.2.2"
server-id=2
```

**Node3 (ams-vm-3):**

```ini
wsrep_node_name="ams-vm-3"
wsrep_node_address="10.0.3.2"
server-id=3
```

---

## STEP 7: Bootstrap Cluster (ONLY Node1)

```bash
sudo systemctl stop mysqld
sudo systemctl start mysql@bootstrap.service
```

Verify it is running:

```bash
mysql -uroot -p -e "SHOW STATUS LIKE 'wsrep_cluster_size';"
```

Should show: `1`

---

## STEP 8: Start Other Nodes

**On Node2:**

```bash
sudo systemctl start mysqld
```

**On Node3:**

```bash
sudo systemctl start mysqld
```

Each node will perform SST automatically from Node1 to get a full data copy.

---

## STEP 9: Verify Cluster

Login on any node:

```bash
mysql -uroot -p
```

### Check cluster size (expect 3)

```sql
SHOW STATUS LIKE 'wsrep_cluster_size';
```

### Check node status (expect "Synced")

```sql
SHOW STATUS LIKE 'wsrep_local_state_comment';
```

### Check cluster health (expect "Primary")

```sql
SHOW STATUS LIKE 'wsrep_cluster_status';
```

---

## STEP 10: Test Multi-Master Replication

**On Node1:**

```sql
CREATE DATABASE testdb;
USE testdb;
CREATE TABLE test1 (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(50));
INSERT INTO test1 (name) VALUES ('from_node1');
```

**On Node2:**

```sql
SHOW DATABASES;
USE testdb;
SELECT * FROM test1;
INSERT INTO test1 (name) VALUES ('from_node2');
```

**On Node3:**

```sql
USE testdb;
SELECT * FROM test1;
-- You will see rows from both Node1 and Node2
```

---

## Summary of Corrections from Original Guide

| #  | Original (Wrong)                             | Corrected                                                       |
|----|----------------------------------------------|-----------------------------------------------------------------|
| 1  | `wsrep_sst_auth="sstuser:sstpass"`           | **REMOVED** — deprecated in PXC 8.0; SST auth is automatic     |
| 2  | Step 7: Create SST user manually             | **REMOVED** — PXC 8.0 uses internal `mysql.pxc.sst.user`       |
| 3  | Missing: Get temporary root password         | **ADDED** Step 5 — `grep 'temporary password'` + ALTER USER     |
| 4  | Missing: `pxc-encrypt-cluster-traffic`       | **ADDED** — PXC 8.0 enables encryption by default; set OFF for lab or configure certs |
| 5  | Missing: datadir, socket, log-error, pid-file| **ADDED** — essential paths for clean config                    |
| 6  | Missing: `binlog_expire_logs_seconds`        | **ADDED** — prevents disk filling up with old binlogs           |

---

## Key Concepts

| Feature     | Galera (PXC)              |
|-------------|---------------------------|
| Writes      | All nodes (multi-master)  |
| Replication | Synchronous (certification)|
| Conflict    | Certification-based       |
| Failover    | Automatic (quorum-based)  |
| SST         | Full copy (xtrabackup)    |
| IST         | Incremental (from gcache) |

---

## Common Issues

| Problem                    | Fix                                                        |
|----------------------------|------------------------------------------------------------|
| Node not joining           | Check firewall ports 3306, 4567, 4568, 4444                |
| SST failed                 | Check `/var/log/mysqld.log` for xtrabackup errors          |
| Cluster not forming        | Ensure Node1 was bootstrapped first                        |
| `unknown variable` error   | Remove deprecated options like `wsrep_sst_auth`            |
| `mysql.plugin doesn't exist` | Run `mysql_upgrade` or reinitialize data directory        |
| Encryption mismatch        | All nodes must have same `pxc-encrypt-cluster-traffic` setting |
