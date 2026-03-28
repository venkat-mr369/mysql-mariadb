## MariaDB Galera Cluster + MaxScale Setup Guide

## Architecture

* Node1: 192.168.17.101 (Galera)
* Node2: 192.168.17.102 (Galera)
* Node3: 192.168.17.103 (Galera)
* Node4: 192.168.17.104 (MaxScale)

---

## Step 1: Prerequisites (All Nodes)

```bash
sudo dnf update -y
sudo dnf install -y wget vim rsync socat
```

Disable SELinux (for lab):

```bash
setenforce 0
sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
```

Open required ports:

```bash
firewall-cmd --permanent --add-port=3306/tcp
firewall-cmd --permanent --add-port=4567/tcp
firewall-cmd --permanent --add-port=4567/udp
firewall-cmd --permanent --add-port=4568/tcp
firewall-cmd --permanent --add-port=4444/tcp
firewall-cmd --reload
```

---

## Step 2: Install MariaDB 11.8 (All 3 Nodes)

Create repo file:

```bash
cat <<EOF > /etc/yum.repos.d/MariaDB.repo
[mariadb]
name = MariaDB
baseurl = https://mirror.mariadb.org/yum/11.8/rhel9-amd64
gpgkey=https://mirror.mariadb.org/yum/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOF
```

Install:

```bash
dnf install -y MariaDB-server MariaDB-client
```

---

## Step 3: Configure Galera (All Nodes)

Edit config:

```bash
vim /etc/my.cnf.d/galera.cnf
```

Add:

```ini
[mysqld]
bind-address=0.0.0.0

# Galera settings
wsrep_on=ON
wsrep_provider=/usr/lib64/galera/libgalera_smm.so

wsrep_cluster_name="galera_cluster"
wsrep_cluster_address="gcomm://192.168.17.101,192.168.17.102,192.168.17.103"

# Node specific
wsrep_node_address="<NODE_IP>"
wsrep_node_name="nodeX"

wsrep_sst_method=rsync

# InnoDB settings
default_storage_engine=InnoDB
innodb_autoinc_lock_mode=2

# Authentication
binlog_format=ROW
```

Replace `<NODE_IP>` and `nodeX` per server.

---

## Step 4: Initialize Cluster

### On Node1 (Bootstrap)

```bash
galera_new_cluster
```

Check:

```bash
mysql -e "SHOW STATUS LIKE 'wsrep_cluster_size';"
```

### On Node2 & Node3

```bash
systemctl start mariadb
```

Verify:

```bash
mysql -e "SHOW STATUS LIKE 'wsrep_cluster_size';"
```

(Expected output: 3)

---

## Step 5: Secure Installation

```bash
mysql_secure_installation
```

---

## Step 6: Create MaxScale User

Run on any node:

```sql
CREATE USER 'maxscale'@'192.168.17.104' IDENTIFIED BY 'MaxScale@123';
GRANT ALL PRIVILEGES ON *.* TO 'maxscale'@'192.168.17.104';
FLUSH PRIVILEGES;
```

---

## Step 7: Install MaxScale (Node4)

```bash
cat <<EOF > /etc/yum.repos.d/maxscale.repo
[maxscale]
name=MaxScale
baseurl=https://downloads.mariadb.com/MaxScale/6.4/rhel/9/x86_64
gpgcheck=0
EOF
```

Install:

```bash
dnf install -y maxscale
```

---

## Step 8: Configure MaxScale

Edit:

```bash
vim /etc/maxscale.cnf
```

Example config:

```ini
[maxscale]
threads=auto

[server1]
type=server
address=192.168.17.101
port=3306
protocol=MariaDBBackend

[server2]
type=server
address=192.168.17.102
port=3306
protocol=MariaDBBackend

[server3]
type=server
address=192.168.17.103
port=3306
protocol=MariaDBBackend

[Galera-Monitor]
type=monitor
module=galeramon
servers=server1,server2,server3
user=maxscale
password=MaxScale@123
monitor_interval=2000

[Read-Write-Service]
type=service
router=readwritesplit
servers=server1,server2,server3
user=maxscale
password=MaxScale@123

[Read-Write-Listener]
type=listener
service=Read-Write-Service
protocol=MariaDBClient
port=4006
```

---

## Step 9: Start MaxScale

```bash
systemctl enable maxscale
systemctl start maxscale
```

Check:

```bash
maxctrl list servers
```

---

## Step 10: Testing

Connect via MaxScale:

```bash
mysql -h 192.168.17.104 -P4006 -u maxscale -p
```

Test replication:

```sql
CREATE DATABASE testdb;
```

Check on other nodes.

---

## Notes

* Always bootstrap only one node
* Ensure time sync (chrony)
* Use rsync for small setups, xtrabackup for production
* Monitor cluster size regularly

---

## Outcome

* 3-node synchronous Galera cluster
* MaxScale providing load balancing and failover

I’ve prepared a complete step-by-step setup in the canvas for you, covering:

3-node MariaDB Galera Cluster (101, 102, 103)
MaxScale setup on 104
Firewall, repo, configuration, bootstrap, and testing
Ready-to-use configs (you just replace IPs where needed)

If you want, I can enhance this further with:

🔹 Production hardening (SSL, SST xtrabackup)
🔹 Failover testing scenarios
🔹 Interview questions based on this setup
🔹 Word document with diagram (like your previous requirement)
