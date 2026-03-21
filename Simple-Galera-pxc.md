Perfect Chandu 🔥 — now we start **Galera / Percona XtraDB Cluster (PXC)** using your IPs.

---

# 🏗️ Your Setup

| Node  | Hostname | IP       |
| ----- | -------- | -------- |
| Node1 | ams-vm-1 | 10.0.1.2 |
| Node2 | ams-vm-2 | 10.0.2.2 |
| Node3 | ams-vm-3 | 10.0.3.2 |

👉 OS: Oracle Linux 9 (assume same)

---

# 🔥 What we are building

👉 **Percona XtraDB Cluster (Galera-based)**

```text
Multi-master cluster (all nodes writable)
Synchronous replication
```

---

# ⚠️ IMPORTANT DIFFERENCE (remember)

| InnoDB Cluster | Galera               |
| -------------- | -------------------- |
| Single Primary | Multi Primary        |
| Async-like     | Sync (certification) |
| Router needed  | No router needed     |

---

# 🚀 STEP 1: Common setup (ALL NODES)

👉 Login as **venkat**

```bash
sudo hostnamectl set-hostname ams-vm-1   # change per node
```

---

## 🔹 Update hosts file (ALL NODES)

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

# 🔥 STEP 2: Disable SELinux (recommended for lab)

```bash
sudo setenforce 0
sudo sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
```

---

# 🔥 STEP 3: Firewall (IMPORTANT)

```bash
sudo systemctl enable firewalld
sudo systemctl start firewalld
```

Open ports:

```bash
sudo firewall-cmd --permanent --add-port=3306/tcp
sudo firewall-cmd --permanent --add-port=4567/tcp
sudo firewall-cmd --permanent --add-port=4568/tcp
sudo firewall-cmd --permanent --add-port=4444/tcp
sudo firewall-cmd --reload
```

---

# 📦 STEP 4: Install Percona XtraDB Cluster (ALL NODES)

```bash
sudo dnf install -y https://repo.percona.com/yum/percona-release-latest.noarch.rpm

sudo percona-release setup pxc80

sudo dnf install -y percona-xtradb-cluster
```

---

# ▶️ STEP 5: Stop MySQL (ALL NODES)

```bash
sudo systemctl stop mysqld
```

---

# ⚙️ STEP 6: Configure Galera (ALL NODES)

```bash
sudo vi /etc/my.cnf
```

---

## 🔹 Add this config

👉 SAME on all nodes except node name & IP

---

### 🔥 COMMON CONFIG

```ini
[mysqld]
server-id=1   # change per node

binlog_format=ROW
default_storage_engine=InnoDB
innodb_autoinc_lock_mode=2

# Galera
wsrep_on=ON
wsrep_provider=/usr/lib64/galera4/libgalera_smm.so

wsrep_cluster_name="pxc-cluster"

wsrep_cluster_address="gcomm://10.0.1.2,10.0.2.2,10.0.3.2"

wsrep_sst_method=xtrabackup-v2
wsrep_sst_auth="sstuser:sstpass"

pxc_strict_mode=ENFORCING
```

---

### 🔹 Node-specific

#### Node1 (ams-vm-1)

```ini
wsrep_node_name="ams-vm-1"
wsrep_node_address="10.0.1.2"
server-id=1
```

---

#### Node2

```ini
wsrep_node_name="ams-vm-2"
wsrep_node_address="10.0.2.2"
server-id=2
```

---

#### Node3

```ini
wsrep_node_name="ams-vm-3"
wsrep_node_address="10.0.3.2"
server-id=3
```

---

# 🔐 STEP 7: Create SST user (ONLY Node1)

Start only node1 temporarily:

```bash
sudo systemctl start mysqld
```

```bash
mysql -uroot -p
```

```sql
CREATE USER 'sstuser'@'%' IDENTIFIED BY 'sstpass';
GRANT RELOAD, LOCK TABLES, PROCESS, REPLICATION CLIENT ON *.* TO 'sstuser'@'%';
FLUSH PRIVILEGES;
```

---

Stop again:

```bash
sudo systemctl stop mysqld
```

---

# 🚀 STEP 8: Bootstrap cluster (ONLY Node1)

```bash
sudo systemctl start mysql@bootstrap.service
```

👉 OR:

```bash
sudo galera_new_cluster
```

---

# 🔥 STEP 9: Start other nodes

👉 On Node2:

```bash
sudo systemctl start mysqld
```

---

👉 On Node3:

```bash
sudo systemctl start mysqld
```

---

# 🔍 STEP 10: Verify cluster

Login any node:

```bash
mysql -uroot -p
```

---

## 🔹 Check cluster size

```sql
SHOW STATUS LIKE 'wsrep_cluster_size';
```

👉 Output:

```
3 ✅
```

---

## 🔹 Check node status

```sql
SHOW STATUS LIKE 'wsrep_local_state_comment';
```

👉 Output:

```
Synced ✅
```

---

## 🔹 Check cluster health

```sql
SHOW STATUS LIKE 'wsrep_cluster_status';
```

👉 Output:

```
Primary ✅
```

---

# 🔥 STEP 11: Test multi-master

👉 On Node1:

```sql
CREATE DATABASE testdb;
```

---

👉 On Node2:

```sql
SHOW DATABASES;
```

👉 You will see:

```
testdb ✅
```

---

# 🧠 Key Concepts

| Feature     | Galera        |
| ----------- | ------------- |
| Writes      | All nodes     |
| Replication | Sync          |
| Conflict    | Certification |
| Failover    | No need       |

---

# ⚠️ Common Issues

| Problem             | Fix             |
| ------------------- | --------------- |
| Node not joining    | Check ports     |
| SST failed          | Check sstuser   |
| Cluster not forming | Bootstrap issue |

---

# 🚀 Next Level (I’ll teach you)

👉 IST vs SST (VERY IMPORTANT)
👉 Galera split-brain (different from InnoDB 🔥)
👉 Certification conflicts
👉 Real interview questions

---

Say:
👉 **“Explain IST vs SST”**
or
👉 **“Galera split brain deep”**

We’ll go deeper 🚀
