Prerequiites Venkat is DBA, Venkat is install MySQL Innodb Cluster on 3 Node

👉 You will login as **venkat (DBA user)**

👉 venkat will use **sudo**

👉 Firewall handled properly ✅

👉 Clear which node / which user

---

### 🏗️ ENV DETAILS

| Node | IP            | Hostname |
| ---- | ------------- | -------- |
| vm1  | 10.10.100.101 | oel9-vm1 |
| vm2  | 10.10.100.102 | oel9-vm2 |
| vm3  | 10.10.100.103 | oel9-vm3 |

---

### 🔐 STEP 0: Create DBA user (ONLY ONCE PER NODE)

👉 Login as **root** on ALL nodes

```bash
useradd venkat
passwd venkat
```

👉 Give sudo access

```bash
echo "venkat ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
```

---

### 🔁 Now login as venkat (ALL NODES)

```bash
su - venkat
```

---

### ⚙️ STEP 1: Host + Basic setup (ALL NODES as venkat)

```bash
sudo hostnamectl set-hostname oel9-vm1   # change per node
```

```bash
sudo vi /etc/hosts
```

Add:

```
10.10.100.101 oel9-vm1
10.10.100.102 oel9-vm2
10.10.100.103 oel9-vm3
```

---

### 🔥 STEP 2: Firewall configuration (ALL NODES)

👉 Instead of disabling, **open required ports**

```bash
sudo systemctl enable firewalld
sudo systemctl start firewalld
```

👉 Open MySQL + Group Replication ports:

```bash
sudo firewall-cmd --permanent --add-port=3306/tcp
sudo firewall-cmd --permanent --add-port=33061/tcp
sudo firewall-cmd --reload
```

👉 Verify:

```bash
sudo firewall-cmd --list-ports
```

---

### 📦 STEP 3: Install MySQL (ALL NODES)

```bash
sudo dnf install -y https://dev.mysql.com/get/mysql80-community-release-el9-1.noarch.rpm

sudo dnf install -y mysql-community-server
```

---

### ▶️ STEP 4: Start MySQL (ALL NODES)

```bash
sudo systemctl enable mysqld
sudo systemctl start mysqld
```

---

### 🔐 STEP 5: Secure MySQL (ALL NODES)

```bash
sudo grep 'temporary password' /var/log/mysqld.log
```

```bash
mysql -uroot -p
```

```sql
ALTER USER 'root'@'localhost' IDENTIFIED BY 'Root@123';
```

---

### ⚙️ STEP 6: MySQL Config (ALL NODES)

```bash
sudo vi /etc/my.cnf
```

👉 Add (change per node 👇)

### vm1:

```
server-id=1
loose-group_replication_local_address="10.10.100.101:33061"
```

### vm2:

```
server-id=2
loose-group_replication_local_address="10.10.100.102:33061"
```

### vm3:

```
server-id=3
loose-group_replication_local_address="10.10.100.103:33061"
```

---

👉 COMMON CONFIG (ALL NODES)

```
log_bin=binlog
gtid_mode=ON
enforce_gtid_consistency=ON
log_slave_updates=ON
binlog_format=ROW

transaction_write_set_extraction=XXHASH64
loose-group_replication_group_name="aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
loose-group_replication_group_seeds="10.10.100.101:33061,10.10.100.102:33061,10.10.100.103:33061"
loose-group_replication_start_on_boot=OFF
loose-group_replication_bootstrap_group=OFF

plugin_load_add='group_replication.so'
```

---

👉 Restart (ALL NODES)

```bash
sudo systemctl restart mysqld
```

---

### 👤 STEP 7: Create cluster admin (On all 3 vms) 

```bash
mysql -uroot -p
```

```sql
CREATE USER 'clusteradmin'@'%' IDENTIFIED BY 'Cluster@123';
GRANT ALL PRIVILEGES ON *.* TO 'clusteradmin'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
```

| Stage          | User creation             |
| -------------- | ------------------------- |
| Before cluster | 🔴 Create on ALL nodes    |
| After cluster  | 🟢 Create on ANY one node |

---

### 🧰 STEP 8: Install MySQL Shell (ONLY vm1)

```bash
sudo dnf install -y mysql-shell
```

---

### 🚀 STEP 9: Configure instances (FROM vm1, as venkat)

```bash
mysqlsh
```

```js
\connect clusteradmin@10.10.100.101:3306
```

```js
dba.configureInstance('clusteradmin@10.10.100.101:3306')
dba.configureInstance('clusteradmin@10.10.100.102:3306')
dba.configureInstance('clusteradmin@10.10.100.103:3306')
```

---

### 🧱 STEP 10: Create Cluster

```js
var cluster = dba.createCluster('ams-kapclu')
```

---

### ➕ STEP 11: Add nodes

```js
cluster.addInstance('clusteradmin@10.10.100.102:3306')
cluster.addInstance('clusteradmin@10.10.100.103:3306')
```

---

### ✅ STEP 12: Verify

```js
cluster.status()
```

---

#### 🔥 KEY POINTS (Real DBA level)

👉 Firewall **disable cheyyakudadhu**
👉 Only required ports open cheyyali

👉 venkat = DBA user
👉 root = only for OS level

👉 MySQL operations → venkat via sudo

---

# 🚀 If you want next

👉 you will do:

* [MySQL Router setup](https://github.com/venkat-mr369/mysql-cluster/blob/main/simple-innodbcluster/2-MySQLRouter-Stepup.md)
* Failover demo (real-time test)
  Stop mysqld in vm1 node and verify from vm2 or vm3
* Troubleshooting errors (very important for interview)

