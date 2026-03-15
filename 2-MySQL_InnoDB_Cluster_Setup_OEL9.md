## MySQL InnoDB Cluster 8 — Complete Setup Guide on Oracle Linux 9

### Environment Overview

| Role | Hostname | IP Address |
|------|----------|------------|
| Primary / Node 1 | oel9-vm1 | 10.10.100.101 |
| Secondary / Node 2 | oel9-vm2 | 10.10.100.102 |
| Secondary / Node 3 | oel9-vm3 | 10.10.100.103 |

**OS:** Oracle Linux 9  
**Database:** MySQL 8.x (InnoDB Cluster with Group Replication)  
**Admin User:** `venkat` (DBA / root-level user)  
**Service Account:** `mysql` (nologin, accessed via sudo or dzdo)

---

### ⚠️ CRITICAL: `sudo -u mysql -i` vs `sudo -u mysql bash`

**The Problem:**

```
[venkat@oel9-vm1 ~]$ sudo -u mysql -i
This account is currently not available.
```

**Why this happens:**  
The `-i` flag tells sudo to simulate a login shell. It reads the target user's shell from `/etc/passwd`. Since `mysql` has `/sbin/nologin` as its shell, the login is immediately rejected.

**The Fix — ALWAYS use this instead:**

```bash
sudo -u mysql bash --login
```

This explicitly tells sudo to run `/bin/bash` (not `/sbin/nologin`), and `--login` loads the mysql user's environment variables.

**Quick comparison:**

| Command | Works? | Why |
|---------|--------|-----|
| `sudo -u mysql -i` | ❌ NO | `-i` invokes `/sbin/nologin` → rejected |
| `sudo -u mysql bash` | ✅ YES | Runs `/bin/bash` directly, ignores nologin |
| `sudo -u mysql bash --login` | ✅ YES (best) | Runs `/bin/bash` + loads environment |
| `sudo -u mysql -s /bin/bash` | ✅ YES | Forces bash shell via `-s` flag |
| `dzdo -u mysql -i` | ❌ NO | Same problem if dzdo is installed |
| `dzdo -u mysql bash --login` | ✅ YES | Same fix for dzdo |

**Throughout this guide, every time you need to switch to the `mysql` user, use:**

```
┌──────────────────────────────────────────────────────────────┐
│  Option A (sudo — standard Linux):                           │
│  sudo -u mysql bash --login                                  │
│                                                              │
│  Option B (dzdo — Centrify environments only):               │
│  dzdo -u mysql bash --login                                  │
└──────────────────────────────────────────────────────────────┘
```

---

### Architecture Flow

```
                        ┌──────────────────────────────┐
                        │      MySQL Router (App)       │
                        │   R/W → Primary (auto-routed) │
                        │   R/O → Secondaries           │
                        └──────────┬───────────────────┘
                                   │
              ┌────────────────────┼────────────────────┐
              │                    │                     │
     ┌────────▼────────┐ ┌────────▼────────┐ ┌─────────▼───────┐
     │   oel9-vm1      │ │   oel9-vm2      │ │   oel9-vm3      │
     │  10.10.100.101  │ │  10.10.100.102  │ │  10.10.100.103  │
     │  PRIMARY (R/W)  │ │  SECONDARY (R/O)│ │  SECONDARY (R/O)│
     │                 │ │                 │ │                 │
     │  MySQL 8.x      │ │  MySQL 8.x      │ │  MySQL 8.x      │
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
2. `venkat` switches to the `mysql` service account using `sudo -u mysql bash --login`.
3. The `mysql` user has SSH keys distributed across all 3 nodes for passwordless failover/failback operations.
4. MySQL Shell (`mysqlsh`) is used to create, manage, and recover the InnoDB Cluster.
5. MySQL Router sits in front of the cluster, directing R/W traffic to the primary and R/O to secondaries.

---

### Part 1: Create the `mysql` System User (nologin + sudo)

> **Perform on ALL 3 nodes** (`oel9-vm1`, `oel9-vm2`, `oel9-vm3`).  
> **Run all commands as:** `venkat` (who has sudo/root access).

### 1.1 Why nologin?

The `mysql` user is a **service account** — it should never log in directly via SSH or console. It runs the MySQL daemon and is accessed only by authorized DBAs like `venkat` who switch to it using `sudo` or `dzdo`.

### 1.2 Create the `mysql` User

If the MySQL RPM has not already created the `mysql` user, create it manually.

**Execute on Linux:**

```bash
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

**Execute on Linux:**

```bash
id mysql
```

Expected output:

```
uid=27(mysql) gid=27(mysql) groups=27(mysql)
```

```bash
grep mysql /etc/passwd
```

Expected output:

```
mysql:x:27:27:MySQL Server:/var/lib/mysql:/sbin/nologin
```

### 1.4 Create Required Directories

**Execute on Linux:**

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

## Part 2: Configure Permissions for `venkat` → Switch to `mysql`

> **Perform on ALL 3 nodes.**  
> **Choose Option A (sudo) OR Option B (dzdo) — NOT both.**

---

### Option A: Standard `sudo` (Recommended — works on all Linux)

`sudo` is built into every Oracle Linux 9 system. No extra software needed.

#### A.1 Create the sudoers rule

**Execute on Linux:**

```bash
sudo visudo -f /etc/sudoers.d/venkat-mysql
```

**Type this content into the editor, then save and exit (`:wq` in vi):**

```
## Allow venkat to run any command as mysql user without password
venkat  ALL=(mysql)  NOPASSWD: ALL
```

#### A.2 Set correct permissions on the file

**Execute on Linux:**

```bash
sudo chmod 440 /etc/sudoers.d/venkat-mysql
```

#### A.3 Test — switch from venkat to mysql

**Execute on Linux:**

```bash
sudo -u mysql bash --login
```

**Verify it worked:**

```bash
whoami
```

Expected output:

```
mysql
```

```bash
echo $HOME
```

Expected output:

```
/var/lib/mysql
```

**To exit back to venkat:**

```bash
exit
```

#### A.4 Full Workflow Example (sudo)

```
[venkat@oel9-vm1 ~]$ sudo -u mysql bash --login
bash-5.1$ whoami
mysql
bash-5.1$ mysqlsh                          # Open MySQL Shell
bash-5.1$ ssh oel9-vm2                     # SSH to node 2 as mysql
bash-5.1$ exit                             # Back to venkat
[venkat@oel9-vm1 ~]$
```

---

### Option B: `dzdo` (Centrify DirectAuthorize — only if installed)

`dzdo` is the Centrify equivalent of `sudo`. It requires the **Centrify DirectAuthorize** package to be installed. If `dzdo: command not found` appears, it means Centrify is NOT installed — use Option A instead.

#### B.1 Check if Centrify/dzdo is installed

**Execute on Linux:**

```bash
which dzdo
```

- If you see a path like `/usr/bin/dzdo` → Centrify IS installed, continue with Option B.
- If you see `command not found` → Centrify is NOT installed, use **Option A** above.

#### B.2 Install Centrify (if needed and licensed)

```bash
# Only if your organization provides Centrify packages
sudo rpm -ivh centrifydc-*.rpm
sudo rpm -ivh centrifyda-*.rpm
sudo adjoin -w your-domain.com    # Join to Active Directory
```

#### B.3 Add dzdo rules via Centrify Admin Console or adedit

Using **adedit** or the **Centrify Admin Console (GUI)**:

```
# Create a new command right:
Command Name: MySQL DBA Access
Command: /bin/bash
Run As User: mysql
Authentication: No password required

# Assign the right to venkat's role:
Role Name: MySQL-DBA-Role
Members: venkat
Rights: MySQL DBA Access
```

Or via **adedit** CLI:

```bash
adedit
> select zone /your-zone
> create right "MySQL-DBA-Bash" --command "/bin/bash" --runas mysql --nopassword
> create role "MySQL-DBA-Role"
> add right "MySQL-DBA-Bash" to role "MySQL-DBA-Role"
> add user "venkat" to role "MySQL-DBA-Role"
> save
> exit
```

#### B.4 Test — switch from venkat to mysql using dzdo

**Execute on Linux:**

```bash
dzdo -u mysql bash --login
```

**⚠️ DO NOT USE:** `dzdo -u mysql -i` — this will fail with "account not available" just like sudo.

**Verify it worked:**

```bash
whoami
```

Expected output:

```
mysql
```

#### B.5 Full Workflow Example (dzdo)

```
[venkat@oel9-vm1 ~]$ dzdo -u mysql bash --login
bash-5.1$ whoami
mysql
bash-5.1$ mysqlsh                          # Open MySQL Shell
bash-5.1$ ssh oel9-vm2                     # SSH to node 2 as mysql
bash-5.1$ exit                             # Back to venkat
[venkat@oel9-vm1 ~]$
```

---

### Quick Reference: How to Switch to mysql User

| Your Environment | Command to Execute | Notes |
|------------------|--------------------|-------|
| Standard Linux (sudo) | `sudo -u mysql bash --login` | Works everywhere |
| Centrify (dzdo) | `dzdo -u mysql bash --login` | Only if Centrify installed |
| ❌ WRONG | `sudo -u mysql -i` | Fails — nologin shell |
| ❌ WRONG | `dzdo -u mysql -i` | Fails — nologin shell |
| ❌ WRONG | `su - mysql` | Fails — nologin shell |

**For the rest of this guide, we will use `sudo -u mysql bash --login` since it works on standard Oracle Linux 9. If you have Centrify, replace `sudo` with `dzdo` in every command.**

---

### Part 3: SSH Key Distribution for the `mysql` User

> **Purpose:** Allow passwordless SSH between all 3 nodes as the `mysql` user. This is essential for failover/failback scripts, cloning, and cluster recovery.  
> **Run all commands as:** `venkat` on `oel9-vm1` unless noted otherwise.

### 3.1 Create .ssh Directory on All Nodes

**Execute on ALL 3 nodes as venkat:**

```bash
sudo -u mysql bash -c 'mkdir -p ~/.ssh && chmod 700 ~/.ssh'
```

### 3.2 Generate SSH Keys (on Node 1 only)

**Execute on oel9-vm1 as venkat:**

```bash
# Switch to mysql user
sudo -u mysql bash --login

# Now you are mysql user — generate key pair
ssh-keygen -t ed25519 -C "mysql@innodb-cluster" -f ~/.ssh/id_ed25519 -N ""

# Verify keys were created
ls -la ~/.ssh/
# You should see: id_ed25519 and id_ed25519.pub

# Exit back to venkat
exit
```

This creates:
- **Private key:** `/var/lib/mysql/.ssh/id_ed25519`
- **Public key:** `/var/lib/mysql/.ssh/id_ed25519.pub`

### 3.3 Distribute the Public Key to All Nodes

**Execute on oel9-vm1 as venkat:**

```bash
# Read the public key into a variable
PUBKEY=$(sudo -u mysql cat /var/lib/mysql/.ssh/id_ed25519.pub)

# Copy to ALL 3 nodes (including node 1 itself)
for HOST in oel9-vm1 oel9-vm2 oel9-vm3; do
  echo "--- Copying key to ${HOST} ---"
  ssh venkat@${HOST} "
    sudo -u mysql bash -c 'mkdir -p ~/.ssh && chmod 700 ~/.ssh'
    echo '${PUBKEY}' | sudo -u mysql tee -a /var/lib/mysql/.ssh/authorized_keys
    sudo -u mysql chmod 600 /var/lib/mysql/.ssh/authorized_keys
  "
done
```

### 3.4 Copy the Private Key to Node 2 and Node 3

The `mysql` user on every node needs the **same** private key so any node can SSH to any other:

**Execute on oel9-vm1 as venkat:**

```bash
for HOST in oel9-vm2 oel9-vm3; do
  echo "--- Copying private key to ${HOST} ---"

  # Copy private key
  sudo -u mysql cat /var/lib/mysql/.ssh/id_ed25519 | \
    ssh venkat@${HOST} "sudo -u mysql tee /var/lib/mysql/.ssh/id_ed25519 > /dev/null"
  ssh venkat@${HOST} "sudo -u mysql chmod 600 /var/lib/mysql/.ssh/id_ed25519"

  # Copy public key
  sudo -u mysql cat /var/lib/mysql/.ssh/id_ed25519.pub | \
    ssh venkat@${HOST} "sudo -u mysql tee /var/lib/mysql/.ssh/id_ed25519.pub > /dev/null"
done
```

### 3.5 Configure SSH Known Hosts (Avoid Fingerprint Prompts)

**Execute on ALL 3 nodes as venkat:**

```bash
for HOST in oel9-vm1 oel9-vm2 oel9-vm3 10.10.100.101 10.10.100.102 10.10.100.103; do
  ssh-keyscan -H ${HOST} 2>/dev/null | \
    sudo -u mysql tee -a /var/lib/mysql/.ssh/known_hosts > /dev/null
done

sudo -u mysql chmod 644 /var/lib/mysql/.ssh/known_hosts
```

### 3.6 Test Passwordless SSH

**Execute on oel9-vm1 as venkat:**

```bash
# Step 1: Switch to mysql user
sudo -u mysql bash --login

# Step 2: Test SSH to each node
ssh mysql@oel9-vm2 hostname
# Expected output: oel9-vm2

ssh mysql@oel9-vm3 hostname
# Expected output: oel9-vm3

# Step 3: Exit back to venkat
exit
```

If you see `Permission denied` — check the permissions below.

### 3.7 SSH Permissions Checklist

Verify on **all 3 nodes**:

**Execute on Linux:**

```bash
sudo ls -la /var/lib/mysql/.ssh/
```

Expected:

```
drwx------  2 mysql mysql  ...  .             (700)
-rw-------  1 mysql mysql  ...  authorized_keys  (600)
-rw-------  1 mysql mysql  ...  id_ed25519       (600)
-rw-r--r--  1 mysql mysql  ...  id_ed25519.pub   (644)
-rw-r--r--  1 mysql mysql  ...  known_hosts      (644)
```

**If permissions are wrong, fix them:**

```bash
sudo -u mysql chmod 700 /var/lib/mysql/.ssh
sudo -u mysql chmod 600 /var/lib/mysql/.ssh/id_ed25519
sudo -u mysql chmod 600 /var/lib/mysql/.ssh/authorized_keys
sudo -u mysql chmod 644 /var/lib/mysql/.ssh/id_ed25519.pub
sudo -u mysql chmod 644 /var/lib/mysql/.ssh/known_hosts
```

---

### Part 4: Install MySQL 8 on Oracle Linux 9

> **Perform on ALL 3 nodes.**  
> **Run all commands as:** `venkat` with sudo.

### 4.1 Add the MySQL 8.0 Repository

**Execute on Linux:**

```bash
sudo dnf install -y https://dev.mysql.com/get/mysql80-community-release-el9-1.noarch.rpm
```

### 4.2 Verify and Enable the MySQL 8.0 Repo

**Execute on Linux:**

```bash
sudo dnf repolist enabled | grep mysql
```

If MySQL 8.4 (Innovation/LTS) is enabled by default, switch to 8.0:

```bash
sudo dnf config-manager --disable mysql-8.4-lts-community
sudo dnf config-manager --enable mysql80-community
```

### 4.3 Install MySQL Server + Shell + Router

**Execute on Linux:**

```bash
sudo dnf install -y mysql-community-server \
                     mysql-community-client \
                     mysql-shell \
                     mysql-router-community
```

### 4.4 Verify Installation

**Execute on Linux:**

```bash
mysqld --version
# Expected: mysqld  Ver 8.0.xx for Linux on x86_64

mysqlsh --version
# Expected: mysqlsh  Ver 8.0.xx

mysqlrouter --version
```

---

### Part 5: Configure MySQL for InnoDB Cluster

> **Perform on ALL 3 nodes** with node-specific values where noted.  
> **Run all commands as:** `venkat` with sudo.

### 5.1 Edit `/etc/my.cnf`

**Execute on Linux:**

```bash
sudo vi /etc/my.cnf
```

**Paste this configuration (change `server-id` and `report-host` per node):**

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

**Node-specific values — CHANGE THESE:**

| Node | server-id | report-host |
|------|-----------|-------------|
| oel9-vm1 | 1 | oel9-vm1 |
| oel9-vm2 | 2 | oel9-vm2 |
| oel9-vm3 | 3 | oel9-vm3 |

### 5.2 Configure /etc/hosts on All Nodes

**Execute on ALL 3 nodes:**

```bash
sudo tee -a /etc/hosts << 'EOF'
10.10.100.101   oel9-vm1
10.10.100.102   oel9-vm2
10.10.100.103   oel9-vm3
EOF
```

**Verify:**

```bash
cat /etc/hosts
ping -c 1 oel9-vm2
```

### 5.3 Open Firewall Ports

**Execute on ALL 3 nodes:**

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

**Verify:**

```bash
sudo firewall-cmd --list-ports
```

### 5.4 Disable SELinux for MySQL (or set permissive)

**Execute on ALL 3 nodes:**

```bash
# Set to permissive (quick method)
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config

# Verify
getenforce
# Expected: Permissive
```

---

## Part 6: Initialize and Start MySQL

> **Perform on ALL 3 nodes.**  
> **Run all commands as:** `venkat` with sudo.

### 6.1 Initialize the Data Directory

**Execute on Linux:**

```bash
sudo mysqld --initialize-insecure --user=mysql --datadir=/var/lib/mysql
```

`--initialize-insecure` creates the root account with an **empty password** (you will set one in step 6.3).

### 6.2 Start MySQL

**Execute on Linux:**

```bash
sudo systemctl start mysqld
sudo systemctl enable mysqld
sudo systemctl status mysqld
```

Confirm you see `active (running)` in the status output.

### 6.3 Set the Root Password

**Execute on Linux:**

```bash
mysql -u root --skip-password -e "
  ALTER USER 'root'@'localhost' IDENTIFIED BY 'YourStrongRootPassword!';
  FLUSH PRIVILEGES;
"
```

### 6.4 Create the InnoDB Cluster Admin User

**Execute on ALL 3 nodes:**

```bash
mysql -u root -p'YourStrongRootPassword!' -e "
  CREATE USER 'clusteradmin'@'%' IDENTIFIED BY 'ClusterAdminPass!';
  GRANT ALL PRIVILEGES ON *.* TO 'clusteradmin'@'%' WITH GRANT OPTION;
  FLUSH PRIVILEGES;
"
```

---

### Part 7: Prepare Instances with MySQL Shell

> **Perform from `oel9-vm1`.**  
> **Run as:** `venkat` — switch to mysql first: `sudo -u mysql bash --login`

### 7.1 Switch to mysql user

**Execute on oel9-vm1:**

```bash
sudo -u mysql bash --login
```

### 7.2 Run `dba.configureInstance()` on Each Node

This checks and fixes the MySQL configuration for Group Replication compatibility.

**Execute as mysql user on oel9-vm1:**

```bash
# Configure Node 1
mysqlsh -- dba configure-instance root@oel9-vm1:3306 \
  --clusterAdmin=clusteradmin \
  --clusterAdminPassword='ClusterAdminPass!' \
  --password='YourStrongRootPassword!' \
  --interactive=false \
  --restart=true

# Configure Node 2
mysqlsh -- dba configure-instance root@oel9-vm2:3306 \
  --clusterAdmin=clusteradmin \
  --clusterAdminPassword='ClusterAdminPass!' \
  --password='YourStrongRootPassword!' \
  --interactive=false \
  --restart=true

# Configure Node 3
mysqlsh -- dba configure-instance root@oel9-vm3:3306 \
  --clusterAdmin=clusteradmin \
  --clusterAdminPassword='ClusterAdminPass!' \
  --password='YourStrongRootPassword!' \
  --interactive=false \
  --restart=true
```

### 7.3 Verify Each Instance Is Ready

**Execute as mysql user:**

```bash
mysqlsh --uri clusteradmin@oel9-vm1:3306 -p'ClusterAdminPass!' \
  -e "dba.checkInstanceConfiguration()"
```

Expected output: `"status": "ok"` — The instance is ready for InnoDB Cluster.

Repeat for `oel9-vm2` and `oel9-vm3`.

---

## Part 8: Create the InnoDB Cluster

> **Perform from `oel9-vm1` only.**  
> **Run as:** `mysql` user (switch first: `sudo -u mysql bash --login`)

### 8.1 Switch to mysql user and open MySQL Shell

**Execute on oel9-vm1:**

```bash
sudo -u mysql bash --login
mysqlsh --uri clusteradmin@oel9-vm1:3306 -p'ClusterAdminPass!'
```

### 8.2 Create the Cluster

**Execute inside MySQL Shell (JS mode):**

```javascript
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

**Execute inside MySQL Shell (continue from 8.2):**

```javascript
cluster.addInstance('clusteradmin@oel9-vm2:3306', {
    password: 'ClusterAdminPass!',
    recoveryMethod: 'clone'
});

cluster.addInstance('clusteradmin@oel9-vm3:3306', {
    password: 'ClusterAdminPass!',
    recoveryMethod: 'clone'
});
```

`recoveryMethod: 'clone'` tells MySQL to use the **Clone Plugin** to fully replicate data from the primary to the joining node.

### 8.4 Verify the Cluster Status

**Execute inside MySQL Shell:**

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

**Exit MySQL Shell:**

```javascript
\quit
```

---

### Part 9: Configure MySQL Router

> **Perform on the application server or on one of the cluster nodes.**  
> **Run as:** `venkat` with sudo.

### 9.1 Bootstrap the Router

**Execute on Linux:**

```bash
sudo mysqlrouter --bootstrap clusteradmin@oel9-vm1:3306 \
  --user=mysql \
  --directory=/var/lib/mysqlrouter \
  --conf-use-sockets \
  --force
```

### 9.2 Start the Router

**Execute on Linux:**

```bash
sudo systemctl start mysqlrouter
sudo systemctl enable mysqlrouter
sudo systemctl status mysqlrouter
```

### 9.3 Router Ports

| Port | Protocol | Mode |
|------|----------|------|
| 6446 | Classic | Read/Write (→ Primary) |
| 6447 | Classic | Read Only (→ Secondaries) |
| 6448 | X Protocol | Read/Write |
| 6449 | X Protocol | Read Only |

### 9.4 Test Through the Router

**Execute on Linux:**

```bash
# R/W connection — should route to primary
mysql -u clusteradmin -p'ClusterAdminPass!' -h 127.0.0.1 -P 6446 \
  -e "SELECT @@hostname, @@read_only;"

# R/O connection — should route to a secondary
mysql -u clusteradmin -p'ClusterAdminPass!' -h 127.0.0.1 -P 6447 \
  -e "SELECT @@hostname, @@read_only;"
```

---

### Part 10: Failover and Failback Operations

> This is where the `mysql` user's SSH keys become critical — allowing seamless cross-node operations.

### 10.1 Automatic Failover (Built-In — No Action Needed)

InnoDB Cluster handles **automatic primary failover**. If `oel9-vm1` (primary) goes down:

1. Group Replication detects the failure (within `expelTimeout` seconds).
2. The remaining members elect a new primary (based on `memberWeight` and lowest `server_uuid`).
3. MySQL Router automatically re-routes R/W traffic to the new primary.

**No manual intervention is needed for automatic failover.**

### 10.2 Manual Switchover (Planned Failover)

Use this when you want to **intentionally** move the primary role (e.g., for maintenance).

**Execute on oel9-vm1 as venkat:**

```bash
# Step 1: Switch to mysql user
sudo -u mysql bash --login

# Step 2: Connect to MySQL Shell
mysqlsh --uri clusteradmin@oel9-vm1:3306 -p'ClusterAdminPass!'
```

**Execute inside MySQL Shell:**

```javascript
// Get the cluster object
var cluster = dba.getCluster();

// Switchover: make oel9-vm2 the new primary
cluster.setPrimaryInstance('clusteradmin@oel9-vm2:3306');

// Verify the new topology
cluster.status();
// oel9-vm2 should now show mode: "R/W"
// oel9-vm1 should now show mode: "R/O"

\quit
```

### 10.3 Failback — Restore Original Primary

After maintenance on `oel9-vm1` is complete, switch the primary back.

**Execute on any node as venkat:**

```bash
# Step 1: Switch to mysql user
sudo -u mysql bash --login

# Step 2: Connect to current primary (oel9-vm2)
mysqlsh --uri clusteradmin@oel9-vm2:3306 -p'ClusterAdminPass!'
```

**Execute inside MySQL Shell:**

```javascript
var cluster = dba.getCluster();
cluster.setPrimaryInstance('clusteradmin@oel9-vm1:3306');

// Verify
cluster.status();
// oel9-vm1 should now show mode: "R/W" again

\quit
```

### 10.4 Recover a Crashed Node

If a node went down and comes back:

**Step 1 — Restart MySQL on the failed node:**

```bash
sudo systemctl start mysqld
```

**Step 2 — Rejoin from MySQL Shell (connect to any ONLINE member):**

```bash
sudo -u mysql bash --login
mysqlsh --uri clusteradmin@oel9-vm2:3306 -p'ClusterAdminPass!'
```

**Execute inside MySQL Shell:**

```javascript
var cluster = dba.getCluster();

// Check status — the recovered node may show (MISSING) or RECOVERING
cluster.status();

// If the node is stuck, rejoin it manually
cluster.rejoinInstance('clusteradmin@oel9-vm1:3306');

\quit
```

### 10.5 Full Cluster Outage Recovery

If **all 3 nodes** went down (e.g., data center power failure):

**Step 1 — Start MySQL on ALL nodes:**

```bash
# Execute on EACH node
sudo systemctl start mysqld
```

**Step 2 — Connect to the most up-to-date node and reboot the cluster:**

```bash
sudo -u mysql bash --login
mysqlsh --uri clusteradmin@oel9-vm1:3306 -p'ClusterAdminPass!'
```

**Execute inside MySQL Shell:**

```javascript
// This automatically detects which node has the latest data
var cluster = dba.rebootClusterFromCompleteOutage();

// It will:
// 1. Detect which node has the latest GTID set
// 2. Restore the cluster metadata
// 3. Rejoin all reachable nodes

cluster.status();

\quit
```

### 10.6 Failover/Failback Script (Using SSH Keys)

The `mysql` user's SSH keys enable remote operations across nodes. Save this script:

**Execute on oel9-vm1 as venkat:**

```bash
sudo mkdir -p /opt/mysql/scripts
sudo vi /opt/mysql/scripts/failover.sh
```

**Paste this content:**

```bash
#!/bin/bash
# failover.sh — Run as mysql user
#
# Usage with sudo:
#   sudo -u mysql bash /opt/mysql/scripts/failover.sh <new_primary>
#
# Usage with dzdo (Centrify):
#   dzdo -u mysql bash /opt/mysql/scripts/failover.sh <new_primary>
#
# Examples:
#   sudo -u mysql bash /opt/mysql/scripts/failover.sh oel9-vm2    # Failover
#   sudo -u mysql bash /opt/mysql/scripts/failover.sh oel9-vm1    # Failback

NEW_PRIMARY=$1
CLUSTER_ADMIN="clusteradmin"
CLUSTER_PASS="ClusterAdminPass!"
NODES=("oel9-vm1" "oel9-vm2" "oel9-vm3")

if [ -z "$NEW_PRIMARY" ]; then
    echo "ERROR: Provide new primary hostname"
    echo "Usage: $0 <oel9-vm1|oel9-vm2|oel9-vm3>"
    exit 1
fi

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
echo "=== Switching primary to ${NEW_PRIMARY} ==="
mysqlsh --uri ${CLUSTER_ADMIN}@${NEW_PRIMARY}:3306 \
    -p"${CLUSTER_PASS}" \
    -e "var c = dba.getCluster(); c.setPrimaryInstance('${CLUSTER_ADMIN}@${NEW_PRIMARY}:3306');"

# Step 3: Verify new topology
echo "=== Verifying cluster status ==="
mysqlsh --uri ${CLUSTER_ADMIN}@${NEW_PRIMARY}:3306 \
    -p"${CLUSTER_PASS}" \
    -e "var c = dba.getCluster(); print(c.status());"

echo "=== Failover to ${NEW_PRIMARY} complete ==="
```

**Set permissions:**

```bash
sudo chown mysql:mysql /opt/mysql/scripts/failover.sh
sudo chmod 750 /opt/mysql/scripts/failover.sh
```

**Usage — Failover (move primary to node 2):**

```bash
# With sudo:
sudo -u mysql bash /opt/mysql/scripts/failover.sh oel9-vm2

# With dzdo (Centrify):
dzdo -u mysql bash /opt/mysql/scripts/failover.sh oel9-vm2
```

**Usage — Failback (move primary back to node 1):**

```bash
# With sudo:
sudo -u mysql bash /opt/mysql/scripts/failover.sh oel9-vm1

# With dzdo (Centrify):
dzdo -u mysql bash /opt/mysql/scripts/failover.sh oel9-vm1
```

---

## Part 11: Day-to-Day Monitoring Commands

### 11.1 Quick Cluster Health Check

**Execute on any node as venkat:**

```bash
sudo -u mysql bash --login

mysqlsh --uri clusteradmin@oel9-vm1:3306 -p'ClusterAdminPass!' \
  -e "var c = dba.getCluster(); print(c.status({extended: 1}));"
```

### 11.2 Check Group Replication Status (SQL)

```bash
mysql -u clusteradmin -p'ClusterAdminPass!' -e "
  SELECT MEMBER_HOST, MEMBER_PORT, MEMBER_STATE, MEMBER_ROLE
  FROM performance_schema.replication_group_members;
"
```

### 11.3 Check Replication Lag

```bash
mysql -u clusteradmin -p'ClusterAdminPass!' -e "
  SELECT * FROM performance_schema.replication_group_member_stats\G
"
```

### 11.4 Test Router Connectivity

```bash
# Which node is the current primary?
mysql -u clusteradmin -p'ClusterAdminPass!' -h 127.0.0.1 -P 6446 \
  -e "SELECT @@hostname;"

# Which node handles read-only?
mysql -u clusteradmin -p'ClusterAdminPass!' -h 127.0.0.1 -P 6447 \
  -e "SELECT @@hostname;"
```

---

### Part 12: Complete Workflow Summary

```
┌─────────────────────────────────────────────────────────────────────┐
│  STEP 1: User & Access Setup                                        │
│  ├── Create mysql user (nologin) on all 3 nodes                     │
│  ├── Configure sudo (or dzdo) for venkat → mysql switch             │
│  ├── Command: sudo -u mysql bash --login                            │
│  └── Distribute SSH keys for mysql user across all nodes            │
├─────────────────────────────────────────────────────────────────────┤
│  STEP 2: MySQL Installation                                         │
│  ├── Add MySQL 8.0 repo on Oracle Linux 9                           │
│  ├── Install mysql-server, mysql-shell, mysql-router                │
│  └── Configure /etc/my.cnf with GR prerequisites                    │
├─────────────────────────────────────────────────────────────────────┤
│  STEP 3: Instance Preparation                                       │
│  ├── Initialize data directory                                      │
│  ├── Start MySQL, set root password                                 │
│  ├── Create clusteradmin user on all nodes                          │
│  └── Run dba.configureInstance() on all nodes                       │
├─────────────────────────────────────────────────────────────────────┤
│  STEP 4: Cluster Creation                                           │
│  ├── dba.createCluster() on node 1 (primary)                        │
│  ├── cluster.addInstance() for node 2 (clone recovery)              │
│  └── cluster.addInstance() for node 3 (clone recovery)              │
├─────────────────────────────────────────────────────────────────────┤
│  STEP 5: Router Setup                                               │
│  ├── Bootstrap MySQL Router against the cluster                     │
│  ├── Start the router service                                       │
│  └── Test R/W (port 6446) and R/O (port 6447) connections           │
├─────────────────────────────────────────────────────────────────────┤
│  STEP 6: Failover / Failback                                        │
│  ├── Automatic: Built into Group Replication                        │
│  ├── Manual switchover: cluster.setPrimaryInstance()                │
│  ├── Node recovery: cluster.rejoinInstance()                        │
│  └── Full outage: dba.rebootClusterFromCompleteOutage()             │
└─────────────────────────────────────────────────────────────────────┘
```

---

### Appendix A: Quick Reference — sudo vs dzdo Commands

| Action | sudo Command | dzdo Command (Centrify only) |
|--------|-------------|------------------------------|
| Switch to mysql user | `sudo -u mysql bash --login` | `dzdo -u mysql bash --login` |
| Run one command as mysql | `sudo -u mysql bash -c 'command'` | `dzdo -u mysql bash -c 'command'` |
| Run failover script | `sudo -u mysql bash /opt/mysql/scripts/failover.sh oel9-vm2` | `dzdo -u mysql bash /opt/mysql/scripts/failover.sh oel9-vm2` |
| ❌ NEVER USE | `sudo -u mysql -i` | `dzdo -u mysql -i` |

### Appendix B: Quick Reference — MySQL Shell Commands

| Action | MySQL Shell Command |
|--------|---------------------|
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

### Appendix C: Troubleshooting

| Issue | Cause | Fix |
|-------|-------|-----|
| `sudo -u mysql -i` → "account not available" | `-i` invokes `/sbin/nologin` | Use `sudo -u mysql bash --login` instead |
| `dzdo: command not found` | Centrify not installed | Use `sudo` instead (Option A) |
| `dzdo -u mysql -i` → "account not available" | Same nologin issue | Use `dzdo -u mysql bash --login` instead |
| Node shows `(MISSING)` | Node is down or unreachable | Restart MySQL, then `cluster.rejoinInstance()` |
| Node shows `RECOVERING` | Node is syncing data | Wait; check `replication_group_member_stats` |
| `ERROR 3092: Group Replication not started` | GR plugin not active | `dba.configureInstance()`, restart MySQL |
| Router sends R/W to wrong node | Router metadata stale | Restart router or re-bootstrap |
| SSH permission denied (mysql user) | Key permissions wrong | Check `.ssh/` perms: dir=700, keys=600 |
| `This member has more transactions than the seed` | GTID divergence | Use `clone` recovery or reset the node |
| `Can't connect to MySQL server on 'oel9-vmX'` | Firewall blocking | Check `firewall-cmd --list-ports` |

---

*Generated for: MySQL 8.0 InnoDB Cluster on Oracle Linux 9 — 3-node single-primary configuration.*
