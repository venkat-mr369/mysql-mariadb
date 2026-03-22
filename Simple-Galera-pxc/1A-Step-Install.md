# Percona XtraDB Cluster (PXC) 8.0 — Setup Guide (Battle-Tested)

**Updated with all real-world errors encountered and fixed during actual deployment.**

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

Verify:

```bash
sudo firewall-cmd --list-ports
```

Must show: `3306/tcp 4567/tcp 4568/tcp 4444/tcp`

---

## STEP 4: Install Percona XtraDB Cluster + XtraBackup + socat (ALL NODES)

> **CRITICAL: Install xtrabackup and socat on ALL nodes — including Node1 (the donor).**
> Missing xtrabackup on the donor causes SST to silently fail with a 100-second timeout.

```bash
sudo dnf install -y https://repo.percona.com/yum/percona-release-latest.noarch.rpm

sudo percona-release setup pxc80

sudo dnf install -y percona-xtradb-cluster percona-xtrabackup-80 socat
```

Verify on ALL nodes:

```bash
which mysqld         # /usr/sbin/mysqld
which xtrabackup     # /usr/bin/xtrabackup
which socat          # /usr/bin/socat
```

**All three must be present on ALL nodes before proceeding.**

---

## STEP 5: Initialize Data Directory + Set Root Password (ONLY Node1)

PXC 8.0 generates a temporary root password during first start.

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

> **If you see `Table 'mysql.user' doesn't exist`:** Your data directory was never initialized.
> Fix it:
> ```bash
> sudo systemctl stop mysqld
> sudo rm -rf /var/lib/mysql/*
> sudo mysqld --initialize --user=mysql
> sudo grep 'temporary password' /var/log/mysqld.log
> sudo systemctl start mysqld
> # Then ALTER USER as above
> ```

---

## STEP 6: Configure Galera (ALL NODES)

```bash
sudo vi /etc/my.cnf
```

### Full /etc/my.cnf (same on all nodes except 3 node-specific lines)

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
wsrep_cluster_name="amspxc-clu"
wsrep_cluster_address="gcomm://10.0.1.2,10.0.2.2,10.0.3.2"
wsrep_node_name="ams-vm-1"           # Change per node
wsrep_node_address="10.0.1.2"        # Change per node
wsrep_slave_threads=8
wsrep_log_conflicts=ON

# SST
wsrep_sst_method=xtrabackup-v2

# PXC settings
pxc_strict_mode=ENFORCING
pxc-encrypt-cluster-traffic=OFF       # Set to ON in production with proper certs

# ╔══════════════════════════════════════════════════════════════════╗
# ║  DO NOT ADD: wsrep_sst_auth — REMOVED in PXC 8.0               ║
# ║  Adding it causes: "unknown variable" → immediate server abort  ║
# ║  PXC 8.0 handles SST auth automatically via mysql.pxc.sst.user ║
# ╚══════════════════════════════════════════════════════════════════╝
```

### Node-Specific Lines (change these 3 lines per node)

**Node1 (ams-vm-1):**

```ini
server-id=1
wsrep_node_name="ams-vm-1"
wsrep_node_address="10.0.1.2"
```

**Node2 (ams-vm-2):**

```ini
server-id=2
wsrep_node_name="ams-vm-2"
wsrep_node_address="10.0.2.2"
```

**Node3 (ams-vm-3):**

```ini
server-id=3
wsrep_node_name="ams-vm-3"
wsrep_node_address="10.0.3.2"
```

> **CRITICAL: `pxc-encrypt-cluster-traffic` must be identical on ALL nodes.**
> If Node1 has `OFF` and Node2 doesn't have the line (defaults to `ON`), you get:
> - Node1 log: `tlsv1 alert decrypt error`
> - Node2 log: `invalid padding: certificate signature failure`
> Both nodes must match. For lab use `OFF` everywhere. For production configure SSL certs and use `ON`.

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

> **Note:** `systemctl status mysqld` may show "failed" from a previous crash.
> Check the correct service: `systemctl status mysql@bootstrap.service`

---

## STEP 8: Prepare Joiner Nodes (Node2 and Node3)

> **Before starting joiner nodes, the data directory must be EMPTY.**
> Stale data from a previous failed attempt will cause SST to fail.

**On Node2 (then repeat on Node3):**

```bash
sudo systemctl stop mysqld
sudo rm -rf /var/lib/mysql/*
```

---

## STEP 9: Start Other Nodes

**On Node2:**

```bash
sudo systemctl start mysqld
```

Watch the log:

```bash
sudo tail -f /var/log/mysqld.log
```

Wait until you see: `Synchronized with group, ready for connections`

**On Node3:**

```bash
sudo systemctl start mysqld
```

Wait for sync, then verify from any node:

```bash
mysql -uroot -p -e "SHOW STATUS LIKE 'wsrep_cluster_size';"
```

Should show: `3`

---

## STEP 10: Switch Node1 from Bootstrap to Normal (IMPORTANT)

Once all 3 nodes are synced, switch Node1 from bootstrap mode:

```bash
# On Node1
sudo systemctl stop mysql@bootstrap.service
sudo systemctl start mysqld
```

This ensures Node1 will rejoin the existing cluster on future restarts instead of trying to form a new one.

---

## STEP 11: Verify Cluster

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

## STEP 12: Test Multi-Master Replication

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

## All Errors Encountered & Fixes

| # | Error | Root Cause | Fix |
|---|-------|-----------|-----|
| 1 | `unknown variable 'wsrep_sst_auth=sstuser:sstpass'` | Removed in PXC 8.0 | Delete the line from my.cnf |
| 2 | `Table 'mysql.user' doesn't exist` | Data directory not initialized | `mysqld --initialize --user=mysql` |
| 3 | `Table 'mysql.plugin' doesn't exist` | Same as above — empty/corrupt datadir | Reinitialize with `--initialize` |
| 4 | `invalid padding: certificate signature failure` | Encryption mismatch between nodes | Set `pxc-encrypt-cluster-traffic=OFF` on ALL nodes |
| 5 | `tlsv1 alert decrypt error` | Same encryption mismatch (donor side) | Same fix — all nodes must match |
| 6 | `Connection refused` on port 4567 | Other node not started yet | Normal — wait for all nodes to start |
| 7 | SST timeout after 100 seconds | xtrabackup not installed on DONOR (Node1) | `dnf install percona-xtrabackup-80` on ALL nodes |
| 8 | `Possible timeout in receiving first data from donor` | Same — donor can't stream backup | Install xtrabackup + socat on ALL nodes |
| 9 | SST fails with stale datadir | Previous failed SST left partial data | `rm -rf /var/lib/mysql/*` on joiner before retry |
| 10 | `systemctl status mysqld` shows failed | Old crash — cluster running under bootstrap service | Check `systemctl status mysql@bootstrap.service` instead |

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

## Quick Troubleshooting Checklist

If a node won't join, check these in order:

1. Is `pxc-encrypt-cluster-traffic` the same on ALL nodes?
2. Are `xtrabackup` and `socat` installed on ALL nodes (including the donor)?
3. Are firewall ports 3306, 4567, 4568, 4444 open on ALL nodes?
4. Is the joiner's `/var/lib/mysql/` clean? (`rm -rf /var/lib/mysql/*`)
5. Was Node1 bootstrapped with `mysql@bootstrap.service`?
6. Is `wsrep_sst_auth` removed from my.cnf? (fatal in PXC 8.0)
7. Check the log: `sudo tail -100 /var/log/mysqld.log`
