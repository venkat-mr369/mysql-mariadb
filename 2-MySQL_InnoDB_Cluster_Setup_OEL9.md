# MySQL InnoDB Cluster 8 — Complete Setup Guide on Oracle Linux 9

## Environment Overview

| Role | Hostname | IP Address |
|------|----------|------------|
| Primary / Node 1 | oel9-vm1 | 10.10.100.101 |
| Secondary / Node 2 | oel9-vm2 | 10.10.100.102 |
| Secondary / Node 3 | oel9-vm3 | 10.10.100.103 |

**OS:** Oracle Linux 9  
**Database:** MySQL 8.x (InnoDB Cluster with Group Replication)  
**Admin User:** `venkat` (DBA / root-level user)  
**Service Account:** `mysql` (nologin, sudo-enabled, used via `dzdo -u mysql`)

---

## Architecture Flow

```
                        ┌──────────────────────────────┐
                        │      MySQL Router (App)      │
                        │   R/W → Primary (auto-routed)│
                        │   R/O → Secondaries          │
                        └──────────┬───────────────────┘
                                   │
              ┌────────────────────┼────────────────────┐
              │                    │                     │
     ┌────────▼────────┐ ┌────────▼────────┐ ┌─────────▼───────┐
     │   oel9-vm1      │ │   oel9-vm2      │ │   oel9-vm3      │
     │  10.10.100.101  │ │  10.10.100.102  │ │  10.10.100.103  │
     │  PRIMARY (R/W)  │ │  SECONDARY (R/O)│ │  SECONDARY (R/O)│
     │                 │ │                  │ │                 │
     │  MySQL 8.x      │ │  MySQL 8.x       │ │  MySQL 8.x      │
     │  Group Repl.    │ │  Group Repl.     │ │  Group Repl.    │
     └─────────────────┘ └──────────────────┘ └─────────────────┘
              │                    │                     │
              └────────────────────┼─────────────────────┘
                                   │
                        Group Replication Channel
                       (Single-Primary Mode - Default)
```

**Flow Summary:**

1. `venkat` (DBA) logs in via SSH to any node.
2. `venkat` switches to the `mysql` service account using `dzdo -u mysql -i`.
3. The `mysql` user has SSH keys distributed across all 3 nodes for passwordless failover/failback operations.
4. MySQL Shell (`mysqlsh`) is used to create, manage, and recover the InnoDB Cluster.
5. MySQL Router sits in front of the cluster, directing R/W traffic to the primary and R/O to secondaries.

---

## Part 1: Create the `mysql` System User (nologin + sudo)

> **Perform on ALL 3 nodes** (`oel9-vm1`, `oel9-vm2`, `oel9-vm3`).

### 1.1 Why nologin?

The `mysql` user is a **service account** — it should never log in directly via SSH or console. It runs the MySQL daemon and is accessed only through `dzdo` (Centrify/sudo) by authorized DBAs like `venkat`.

### 1.2 Create the `mysql` User

If the MySQL RPM has not already created the `mysql` user, create it manually:

```bash
# Run as root or venkat with sudo
sudo groupadd -r mysql
sudo useradd -r -g mysql -s /sbin/nologin -d /var/lib/mysql -c "MySQL Server" mysql
```

**Flags explained:**

| Flag | Meaning |
|------|---------|
| `-r` | System account (UID below 1000) |
| `-g mysql` | Primary group is `mysql` |
| `-s /sbin/nologin` | Cannot log in directly — this is the "nologin" part |
| `-d /var/lib/mysql` | Home directory (MySQL data dir) |
| `-c "MySQL Server"` | Comment/description |

### 1.3 Verify the User

```bash
id mysql
# Expected: uid=27(mysql) gid=27(mysql) groups=27(mysql)

grep mysql /etc/passwd
# Expected: mysql:x:27:27:MySQL Server:/var/lib/mysql:/sbin/nologin
```

### 1.4 Create Required Directories

```bash
sudo mkdir -p /var/lib/mysql
sudo mkdir -p /var/log/mysql
sudo mkdir -p /var/run/mysqld
sudo mkdir -p /etc/mysql

sudo chown -R mysql:mysql /var/lib/mysql
sudo chown -R mysql:mysql /var/log/mysql
sudo chown -R mysql:mysql /var/run/mysqld
```

---

## Part 2: Configure Sudo / dzdo Permissions for `venkat`

> **Perform on ALL 3 nodes.**

### 2.1 What is `dzdo`?

`dzdo` is the Centrify DirectAuthorize equivalent of `sudo`. It allows `venkat` to run commands as the `mysql` user without `mysql` having a login shell. If your environment uses standard `sudo` instead, the config is similar.

### 2.2 Add dzdo (Centrify) Rules

If using **Centrify DirectAuthorize**, add the following role/right:

```
# In Centrify DirectControl — via adedit or Admin Console
# Grant venkat the right to run commands as mysql

dzdo command: /bin/bash
dzdo runas: mysql
dzdo user: venkat
```

### 2.3 Alternative: Standard sudoers Configuration

If using standard `sudo` instead of dzdo, create a sudoers drop-in file:

```bash
sudo visudo -f /etc/sudoers.d/venkat-mysql
```

Add the following content:

```
## Allow venkat to switch to mysql user for DBA operations
venkat  ALL=(mysql)  NOPASSWD: ALL
```

### 2.4 Test the Switch

```bash
# From venkat's session — switch to mysql user
dzdo -u mysql -i
# OR with standard sudo:
sudo -u mysql -i

# Verify
whoami
# Expected: mysql

# Note: Even though mysql has /sbin/nologin, dzdo/sudo bypasses the shell
# restriction because it directly invokes a shell for the target user.
```

**Important:** The `-i` flag simulates an initial login, loading the mysql user's environment. Even though `/sbin/nologin` blocks direct SSH, `dzdo -u mysql -i` forces a `/bin/bash` shell for the session.

### 2.5 Full Workflow — venkat to mysql

```
venkat@oel9-vm1 $ dzdo -u mysql -i          # Switch to mysql user
mysql@oel9-vm1 $ whoami                       # Confirm: mysql
mysql@oel9-vm1 $ mysqlsh                      # Open MySQL Shell
mysql@oel9-vm1 $ ssh oel9-vm2                 # SSH to node 2 as mysql (via keys)
```

---

## Part 3: SSH Key Distribution for the `mysql` User

> **Purpose:** Allow passwordless SSH between all 3 nodes as the `mysql` user. This is essential for failover/failback scripts, cloning, and cluster recovery.

### 3.1 Generate SSH Keys (on Node 1)

```bash
# Switch to mysql user first
dzdo -u mysql -i

# Generate an ED25519 key pair (recommended over RSA)
ssh-keygen -t ed25519 -C "mysql@innodb-cluster" -f ~/.ssh/id_ed25519 -N ""
```

This creates:
- **Private key:** `/var/lib/mysql/.ssh/id_ed25519`
- **Public key:** `/var/lib/mysql/.ssh/id_ed25519.pub`

### 3.2 Ensure .ssh Directory Exists on All Nodes

Run on **all 3 nodes** as `venkat`:

```bash
dzdo -u mysql bash -c 'mkdir -p ~/.ssh && chmod 700 ~/.ssh'
```

### 3.3 Distribute the Public Key to All Nodes

From **Node 1** as the `mysql` user:

```bash
# Copy the public key to all nodes (including localhost for local operations)
# Since mysql has nologin, we use venkat + dzdo to push the keys

# Method: Use venkat's SSH access + dzdo to append keys
# Run this FROM node 1 as venkat:

PUBKEY=$(dzdo -u mysql cat /var/lib/mysql/.ssh/id_ed25519.pub)

for HOST in oel9-vm1 oel9-vm2 oel9-vm3; do
  ssh venkat@${HOST} "
    sudo -u mysql bash -c 'mkdir -p ~/.ssh && chmod 700 ~/.ssh'
    echo '${PUBKEY}' | sudo -u mysql tee -a /var/lib/mysql/.ssh/authorized_keys
    sudo -u mysql chmod 600 /var/lib/mysql/.ssh/authorized_keys
  "
done
```

### 3.4 Copy the Private Key to All Nodes

The `mysql` user on every node needs the **same** private key so any node can SSH to any other node:

```bash
# From node 1 as venkat
for HOST in oel9-vm2 oel9-vm3; do
  dzdo -u mysql cat /var/lib/mysql/.ssh/id_ed25519 | \
    ssh venkat@${HOST} "sudo -u mysql tee /var/lib/mysql/.ssh/id_ed25519 > /dev/null"
  ssh venkat@${HOST} "sudo -u mysql chmod 600 /var/lib/mysql/.ssh/id_ed25519"
  
  dzdo -u mysql cat /var/lib/mysql/.ssh/id_ed25519.pub | \
    ssh venkat@${HOST} "sudo -u mysql tee /var/lib/mysql/.ssh/id_ed25519.pub > /dev/null"
done
```

### 3.5 Configure SSH Known Hosts (Avoid Prompts)

As `venkat` on each node:

```bash
for HOST in oel9-vm1 oel9-vm2 oel9-vm3 10.10.100.101 10.10.100.102 10.10.100.103; do
  ssh-keyscan -H ${HOST} 2>/dev/null | \
    dzdo -u mysql tee -a /var/lib/mysql/.ssh/known_hosts > /dev/null
done

dzdo -u mysql chmod 644 /var/lib/mysql/.ssh/known_hosts
```

### 3.6 Test Passwordless SSH

```bash
# As venkat, switch to mysql, then test SSH
dzdo -u mysql -i

ssh mysql@oel9-vm2 hostname
# Expected: oel9-vm2

ssh mysql@oel9-vm3 hostname
# Expected: oel9-vm3
```

### 3.7 SSH Permissions Checklist

```
/var/lib/mysql/.ssh/              → 700  (drwx------)
/var/lib/mysql/.ssh/id_ed25519    → 600  (-rw-------)
/var/lib/mysql/.ssh/id_ed25519.pub→ 644  (-rw-r--r--)
/var/lib/mysql/.ssh/authorized_keys→ 600  (-rw-------)
/var/lib/mysql/.ssh/known_hosts   → 644  (-rw-r--r--)
```

---

## Part 4: Install MySQL 8 on Oracle Linux 9

> **Perform on ALL 3 nodes.**

### 4.1 Add the MySQL 8.0 Repository

```bash
sudo dnf install -y https://dev.mysql.com/get/mysql80-community-release-el9-1.noarch.rpm
```

### 4.2 Verify and Enable the MySQL 8.0 Repo

```bash
sudo dnf repolist enabled | grep mysql

# If MySQL 8.4 (Innovation) is enabled by default, switch to 8.0:
sudo dnf config-manager --disable mysql-8.4-lts-community
sudo dnf config-manager --enable mysql80-community
```

### 4.3 Install MySQL Server + Shell + Router

```bash
sudo dnf install -y mysql-community-server \
                     mysql-community-client \
                     mysql-shell \
                     mysql-router-community
```

### 4.4 Verify Installation

```bash
mysqld --version
# Expected: mysqld  Ver 8.0.xx for Linux on x86_64

mysqlsh --version
# Expected: mysqlsh  Ver 8.0.xx

mysqlrouter --version
```

---

## Part 5: Configure MySQL for InnoDB Cluster

> **Perform on ALL 3 nodes** with node-specific values where noted.

### 5.1 Edit `/etc/my.cnf`

```ini
[mysqld]
# ============================================
# General Settings
# ============================================
server-id                       = 1          # UNIQUE per node: 1, 2, 3
datadir                         = /var/lib/mysql
socket                          = /var/lib/mysql/mysql.sock
log-error                       = /var/log/mysql/mysqld.log
pid-file                        = /var/run/mysqld/mysqld.pid

# ============================================
# Networking
# ============================================
bind-address                    = 0.0.0.0
port                            = 3306
mysqlx-port                     = 33060
admin-address                   = 127.0.0.1
admin-port                      = 33062
report-host                     = oel9-vm1    # CHANGE per node: oel9-vm1, oel9-vm2, oel9-vm3

# ============================================
# InnoDB Cluster / Group Replication Prerequisites
# ============================================
disabled_storage_engines        = "MyISAM,BLACKHOLE,FEDERATED,ARCHIVE,MEMORY"
gtid_mode                       = ON
enforce_gtid_consistency        = ON
binlog_checksum                 = NONE
log_bin                         = /var/lib/mysql/binlog
log_slave_updates               = ON
binlog_format                   = ROW
master_info_repository          = TABLE
relay_log_info_repository       = TABLE
transaction_write_set_extraction= XXHASH64

# ============================================
# Group Replication (configured by MySQL Shell, but set basics)
# ============================================
plugin_load_add                 = group_replication.so
group_replication_start_on_boot = OFF
loose-group_replication_recovery_use_ssl = ON

# ============================================
# InnoDB Tuning
# ============================================
innodb_buffer_pool_size         = 1G          # Set to 50-70% of available RAM
innodb_log_file_size            = 256M
innodb_flush_log_at_trx_commit  = 1
sync_binlog                     = 1

# ============================================
# Connection & Timeout
# ============================================
max_connections                 = 500
wait_timeout                    = 28800
interactive_timeout             = 28800
```

**Node-specific values to change:**

| Node | server-id | report-host |
|------|-----------|-------------|
| oel9-vm1 | 1 | oel9-vm1 |
| oel9-vm2 | 2 | oel9-vm2 |
| oel9-vm3 | 3 | oel9-vm3 |

### 5.2 Configure /etc/hosts on All Nodes

```bash
sudo tee -a /etc/hosts << 'EOF'
10.10.100.101   oel9-vm1
10.10.100.102   oel9-vm2
10.10.100.103   oel9-vm3
EOF
```

### 5.3 Open Firewall Ports

```bash
sudo firewall-cmd --permanent --add-port=3306/tcp     # MySQL classic
sudo firewall-cmd --permanent --add-port=33060/tcp    # MySQL X Protocol
sudo firewall-cmd --permanent --add-port=33061/tcp    # Group Replication
sudo firewall-cmd --permanent --add-port=6446/tcp     # Router R/W
sudo firewall-cmd --permanent --add-port=6447/tcp     # Router R/O
sudo firewall-cmd --permanent --add-port=6448/tcp     # Router R/W (X)
sudo firewall-cmd --permanent --add-port=6449/tcp     # Router R/O (X)
sudo firewall-cmd --reload
```

### 5.4 Disable SELinux for MySQL (or configure policies)

```bash
# Quick method — set to permissive
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config

# Production method — create proper SELinux policies for MySQL
# sudo setsebool -P mysql_connect_any 1
```

---

## Part 6: Initialize and Start MySQL

> **Perform on ALL 3 nodes.**

### 6.1 Initialize the Data Directory

```bash
sudo mysqld --initialize-insecure --user=mysql --datadir=/var/lib/mysql
```

`--initialize-insecure` creates the root account with an **empty password** (you will set one immediately after first login).

### 6.2 Start MySQL

```bash
sudo systemctl start mysqld
sudo systemctl enable mysqld
sudo systemctl status mysqld
```

### 6.3 Set the Root Password

```bash
mysql -u root --skip-password -e "
  ALTER USER 'root'@'localhost' IDENTIFIED BY 'YourStrongRootPassword!';
  FLUSH PRIVILEGES;
"
```

### 6.4 Create the InnoDB Cluster Admin User

Run on **all 3 nodes**:

```bash
mysql -u root -p'YourStrongRootPassword!' -e "
  CREATE USER 'clusteradmin'@'%' IDENTIFIED BY 'ClusterAdminPass!';
  GRANT ALL PRIVILEGES ON *.* TO 'clusteradmin'@'%' WITH GRANT OPTION;
  FLUSH PRIVILEGES;
"
```

---

## Part 7: Prepare Instances with MySQL Shell

> **Perform from `oel9-vm1` as `venkat` → `dzdo -u mysql -i`.**

### 7.1 Run `dba.configureInstance()` on Each Node

This checks and fixes the MySQL configuration for Group Replication compatibility.

```bash
mysqlsh -- dba configure-instance root@oel9-vm1:3306 \
  --clusterAdmin=clusteradmin \
  --clusterAdminPassword='ClusterAdminPass!' \
  --password='YourStrongRootPassword!' \
  --interactive=false \
  --restart=true
```

Repeat for **oel9-vm2** and **oel9-vm3**:

```bash
mysqlsh -- dba configure-instance root@oel9-vm2:3306 \
  --clusterAdmin=clusteradmin \
  --clusterAdminPassword='ClusterAdminPass!' \
  --password='YourStrongRootPassword!' \
  --interactive=false \
  --restart=true

mysqlsh -- dba configure-instance root@oel9-vm3:3306 \
  --clusterAdmin=clusteradmin \
  --clusterAdminPassword='ClusterAdminPass!' \
  --password='YourStrongRootPassword!' \
  --interactive=false \
  --restart=true
```

### 7.2 Verify Each Instance Is Ready

```bash
mysqlsh --uri clusteradmin@oel9-vm1:3306 -p'ClusterAdminPass!' \
  -e "dba.checkInstanceConfiguration()"
```

Expected output: `"status": "ok"` — The instance is ready for InnoDB Cluster.

---

## Part 8: Create the InnoDB Cluster

> **Perform from `oel9-vm1` only.**

### 8.1 Connect to MySQL Shell

```bash
dzdo -u mysql -i
mysqlsh --uri clusteradmin@oel9-vm1:3306 -p'ClusterAdminPass!'
```

### 8.2 Create the Cluster

```javascript
// Inside MySQL Shell (JS mode)
var cluster = dba.createCluster('prodCluster', {
    multiPrimary: false,
    memberWeight: 50,
    exitStateAction: 'READ_ONLY',
    autoRejoinTries: 3,
    expelTimeout: 5
});
```

**Options explained:**

| Option | Value | Meaning |
|--------|-------|---------|
| `multiPrimary` | `false` | Single-primary mode (one R/W, others R/O) |
| `memberWeight` | `50` | Failover election weight (higher = more preferred) |
| `exitStateAction` | `READ_ONLY` | If a member is expelled, it goes read-only instead of shutting down |
| `autoRejoinTries` | `3` | Try to rejoin 3 times before giving up |
| `expelTimeout` | `5` | Seconds before an unreachable member is expelled |

### 8.3 Add Node 2 and Node 3

```javascript
// Still inside MySQL Shell on oel9-vm1
cluster.addInstance('clusteradmin@oel9-vm2:3306', {
    password: 'ClusterAdminPass!',
    recoveryMethod: 'clone'
});

cluster.addInstance('clusteradmin@oel9-vm3:3306', {
    password: 'ClusterAdminPass!',
    recoveryMethod: 'clone'
});
```

`recoveryMethod: 'clone'` tells MySQL to use the **Clone Plugin** to fully replicate data from the primary to the joining node (best for initial setup or large data divergence).

### 8.4 Verify the Cluster Status

```javascript
cluster.status();
```

Expected output:

```json
{
    "clusterName": "prodCluster",
    "status": "OK",
    "topology": {
        "oel9-vm1:3306": {
            "address": "oel9-vm1:3306",
            "mode": "R/W",
            "role": "HA",
            "status": "ONLINE"
        },
        "oel9-vm2:3306": {
            "address": "oel9-vm2:3306",
            "mode": "R/O",
            "role": "HA",
            "status": "ONLINE"
        },
        "oel9-vm3:3306": {
            "address": "oel9-vm3:3306",
            "mode": "R/O",
            "role": "HA",
            "status": "ONLINE"
        }
    }
}
```

---

## Part 9: Configure MySQL Router

> **Perform on the application server or on one of the cluster nodes.**

### 9.1 Bootstrap the Router

```bash
mysqlrouter --bootstrap clusteradmin@oel9-vm1:3306 \
  --user=mysql \
  --directory=/var/lib/mysqlrouter \
  --conf-use-sockets \
  --force
```

### 9.2 Start the Router

```bash
cd /var/lib/mysqlrouter
./start.sh
# OR as a systemd service:
sudo systemctl start mysqlrouter
sudo systemctl enable mysqlrouter
```

### 9.3 Router Ports

| Port | Protocol | Mode |
|------|----------|------|
| 6446 | Classic | Read/Write (→ Primary) |
| 6447 | Classic | Read Only (→ Secondaries) |
| 6448 | X Protocol | Read/Write |
| 6449 | X Protocol | Read Only |

### 9.4 Test Through the Router

```bash
# R/W connection (should route to primary)
mysql -u clusteradmin -p'ClusterAdminPass!' -h 127.0.0.1 -P 6446 \
  -e "SELECT @@hostname, @@read_only;"

# R/O connection (should route to a secondary)
mysql -u clusteradmin -p'ClusterAdminPass!' -h 127.0.0.1 -P 6447 \
  -e "SELECT @@hostname, @@read_only;"
```

---

## Part 10: Failover and Failback Operations

> This is where the `mysql` user's SSH keys become critical — allowing seamless cross-node operations.

### 10.1 Automatic Failover (Built-In)

InnoDB Cluster handles **automatic primary failover**. If `oel9-vm1` (primary) goes down:

1. Group Replication detects the failure (within `expelTimeout` seconds).
2. The remaining members elect a new primary (based on `memberWeight` and lowest `server_uuid`).
3. MySQL Router automatically re-routes R/W traffic to the new primary.

**No manual intervention is needed for automatic failover.**

### 10.2 Manual / Forced Failover (Switchover)

Use this when you want to **intentionally** move the primary role (e.g., for maintenance).

```bash
# Connect to MySQL Shell
dzdo -u mysql -i
mysqlsh --uri clusteradmin@oel9-vm1:3306 -p'ClusterAdminPass!'
```

```javascript
// Inside MySQL Shell
var cluster = dba.getCluster();

// Switchover: make oel9-vm2 the new primary
cluster.setPrimaryInstance('clusteradmin@oel9-vm2:3306');
```

Verify:

```javascript
cluster.status();
// oel9-vm2 should now show mode: "R/W"
// oel9-vm1 should now show mode: "R/O"
```

### 10.3 Failback — Restore Original Primary

After maintenance on `oel9-vm1` is complete, switch back:

```javascript
// Connect to current primary (oel9-vm2)
mysqlsh --uri clusteradmin@oel9-vm2:3306 -p'ClusterAdminPass!'

var cluster = dba.getCluster();
cluster.setPrimaryInstance('clusteradmin@oel9-vm1:3306');
```

### 10.4 Recover a Crashed Node

If a node went down and comes back:

```bash
# Restart MySQL on the failed node
sudo systemctl start mysqld
```

```javascript
// From MySQL Shell connected to any ONLINE member
var cluster = dba.getCluster();

// Check status — the recovered node may show (MISSING) or RECOVERING
cluster.status();

// If the node is stuck, rejoin it
cluster.rejoinInstance('clusteradmin@oel9-vm1:3306');
```

### 10.5 Full Cluster Outage Recovery

If **all nodes** went down (e.g., data center power failure):

```bash
# Start MySQL on ALL nodes first
# Then connect to the node that has the most recent transactions
dzdo -u mysql -i
mysqlsh --uri clusteradmin@oel9-vm1:3306 -p'ClusterAdminPass!'
```

```javascript
// Reboot the cluster from the most up-to-date member
var cluster = dba.rebootClusterFromCompleteOutage();

// This will:
// 1. Detect which node has the latest GTID set
// 2. Restore the cluster metadata
// 3. Rejoin all reachable nodes
```

### 10.6 Failover/Failback Using SSH Keys (Scripted)

The `mysql` user's SSH keys enable remote operations. Example failover script:

```bash
#!/bin/bash
# failover.sh — Run as mysql user via dzdo
# Usage: dzdo -u mysql bash /opt/mysql/scripts/failover.sh <new_primary>

NEW_PRIMARY=$1
CLUSTER_ADMIN="clusteradmin"
CLUSTER_PASS="ClusterAdminPass!"
NODES=("oel9-vm1" "oel9-vm2" "oel9-vm3")

echo "=== Initiating failover to ${NEW_PRIMARY} ==="

# Step 1: Verify all nodes are reachable via SSH
for NODE in "${NODES[@]}"; do
    echo "Checking ${NODE}..."
    ssh -o ConnectTimeout=5 mysql@${NODE} "systemctl is-active mysqld" || {
        echo "WARNING: ${NODE} MySQL not running. Attempting start..."
        ssh mysql@${NODE} "sudo systemctl start mysqld"
    }
done

# Step 2: Perform the switchover
mysqlsh --uri ${CLUSTER_ADMIN}@${NEW_PRIMARY}:3306 \
    -p"${CLUSTER_PASS}" \
    -e "var c = dba.getCluster(); c.setPrimaryInstance('${CLUSTER_ADMIN}@${NEW_PRIMARY}:3306');"

# Step 3: Verify new topology
mysqlsh --uri ${CLUSTER_ADMIN}@${NEW_PRIMARY}:3306 \
    -p"${CLUSTER_PASS}" \
    -e "var c = dba.getCluster(); print(c.status());"

echo "=== Failover to ${NEW_PRIMARY} complete ==="
```

**Usage:**

```bash
dzdo -u mysql bash /opt/mysql/scripts/failover.sh oel9-vm2   # Failover
dzdo -u mysql bash /opt/mysql/scripts/failover.sh oel9-vm1   # Failback
```

---

## Part 11: Day-to-Day Monitoring Commands

### 11.1 Quick Cluster Health Check

```bash
dzdo -u mysql -i
mysqlsh --uri clusteradmin@oel9-vm1:3306 -p'ClusterAdminPass!' \
  -e "var c = dba.getCluster(); print(c.status({extended: 1}));"
```

### 11.2 Check Group Replication Status (SQL)

```sql
SELECT MEMBER_HOST, MEMBER_PORT, MEMBER_STATE, MEMBER_ROLE
FROM performance_schema.replication_group_members;
```

### 11.3 Check Replication Lag

```sql
SELECT * FROM performance_schema.replication_group_member_stats\G
```

### 11.4 Router Status

```bash
mysqlrouter_passwd  # Check router config
mysql -u clusteradmin -p -h 127.0.0.1 -P 6446 -e "SELECT @@hostname;"
```

---

## Part 12: Complete Workflow Summary

```
┌─────────────────────────────────────────────────────────────────────┐
│  STEP 1: User & Access Setup                                       │
│  ├── Create mysql user (nologin) on all 3 nodes                    │
│  ├── Configure dzdo/sudo for venkat → mysql switch                 │
│  └── Distribute SSH keys for mysql user across all nodes           │
├─────────────────────────────────────────────────────────────────────┤
│  STEP 2: MySQL Installation                                        │
│  ├── Add MySQL 8.0 repo on Oracle Linux 9                          │
│  ├── Install mysql-server, mysql-shell, mysql-router               │
│  └── Configure /etc/my.cnf with GR prerequisites                  │
├─────────────────────────────────────────────────────────────────────┤
│  STEP 3: Instance Preparation                                      │
│  ├── Initialize data directory                                     │
│  ├── Start MySQL, set root password                                │
│  ├── Create clusteradmin user on all nodes                         │
│  └── Run dba.configureInstance() on all nodes                      │
├─────────────────────────────────────────────────────────────────────┤
│  STEP 4: Cluster Creation                                          │
│  ├── dba.createCluster() on node 1 (primary)                      │
│  ├── cluster.addInstance() for node 2 (clone recovery)             │
│  └── cluster.addInstance() for node 3 (clone recovery)             │
├─────────────────────────────────────────────────────────────────────┤
│  STEP 5: Router Setup                                              │
│  ├── Bootstrap MySQL Router against the cluster                    │
│  ├── Start the router service                                      │
│  └── Test R/W (port 6446) and R/O (port 6447) connections         │
├─────────────────────────────────────────────────────────────────────┤
│  STEP 6: Failover / Failback                                      │
│  ├── Automatic: Built into Group Replication                       │
│  ├── Manual switchover: cluster.setPrimaryInstance()               │
│  ├── Node recovery: cluster.rejoinInstance()                       │
│  └── Full outage: dba.rebootClusterFromCompleteOutage()            │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Appendix A: Quick Reference Commands

| Action | Command |
|--------|---------|
| Switch to mysql user | `dzdo -u mysql -i` |
| Open MySQL Shell | `mysqlsh --uri clusteradmin@oel9-vm1:3306` |
| Cluster status | `cluster.status()` |
| Extended status | `cluster.status({extended: 1})` |
| Switchover primary | `cluster.setPrimaryInstance('user@newhost:3306')` |
| Rejoin node | `cluster.rejoinInstance('user@host:3306')` |
| Reboot after full outage | `dba.rebootClusterFromCompleteOutage()` |
| Remove a node | `cluster.removeInstance('user@host:3306')` |
| Force remove (unreachable) | `cluster.removeInstance('user@host:3306', {force: true})` |
| Describe cluster | `cluster.describe()` |
| Check instance | `dba.checkInstanceConfiguration('user@host:3306')` |
| Configure instance | `dba.configureInstance('user@host:3306')` |

---

## Appendix B: Troubleshooting

| Issue | Diagnosis | Fix |
|-------|-----------|-----|
| Node shows `(MISSING)` | Node is down or unreachable | Restart MySQL, then `cluster.rejoinInstance()` |
| Node shows `RECOVERING` | Node is syncing data | Wait; check `replication_group_member_stats` |
| `ERROR 3092: Group Replication not started` | GR plugin not active | `dba.configureInstance()`, restart MySQL |
| Router sends R/W to wrong node | Router metadata stale | Restart router or re-bootstrap |
| SSH permission denied (mysql user) | Key permissions wrong | Check `.ssh/` perms: dir=700, keys=600 |
| `dzdo: command not allowed` | Missing dzdo rule | Add venkat→mysql rule in Centrify |
| `This member has more transactions than the seed` | GTID divergence | Use `clone` recovery or reset the node |

---

*Generated for: MySQL 8.0 InnoDB Cluster on Oracle Linux 9 — 3-node single-primary configuration.*
