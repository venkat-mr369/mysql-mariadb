Good question Chandu 👍 — and this is **very real-world architecture thinking**.

## 🔥 Short answer

👉 **YES, you can install ProxySQL on vm4 (same server as MySQL Router)**
👉 But **production best practice = separate servers** ⚠️

---

# 🧠 Should you install both on same vm4?

## ✅ Allowed (lab / small setup)

* Router + ProxySQL on vm4 ✔
* Useful for learning ✔

## ❌ Not recommended (production)

* Single point of failure
* Resource contention

👉 Better:

```text
vm4 → MySQL Router
vm5 → ProxySQL
```

---

# 🚀 Now let’s SETUP ProxySQL on vm4 (step-by-step)

👉 Login to vm4 as **venkat**

---

# ⚙️ STEP 1: Install ProxySQL

```bash
sudo dnf install -y proxysql
```

👉 If not found:

```bash
sudo dnf install -y epel-release
sudo dnf install -y proxysql
```

---

# ▶️ STEP 2: Start ProxySQL

```bash
sudo systemctl enable proxysql
sudo systemctl start proxysql
```

---

# 🔍 STEP 3: Login to ProxySQL Admin

```bash
mysql -uadmin -p -h 127.0.0.1 -P6032
```

👉 Default password:

```text
admin
```

---

# 🧠 ProxySQL Ports

| Port | Purpose      |
| ---- | ------------ |
| 6032 | Admin        |
| 6033 | MySQL client |

---

# ⚙️ STEP 4: Add MySQL servers (your cluster nodes)

```sql
INSERT INTO mysql_servers (hostgroup_id, hostname, port) VALUES (10,'10.10.100.101',3306);
INSERT INTO mysql_servers (hostgroup_id, hostname, port) VALUES (10,'10.10.100.102',3306);
INSERT INTO mysql_servers (hostgroup_id, hostname, port) VALUES (10,'10.10.100.103',3306);
```

---

# ⚙️ STEP 5: Define users

```sql
INSERT INTO mysql_users (username, password, default_hostgroup) 
VALUES ('clusteradmin','Cluster@123',10);
```

---

# ⚙️ STEP 6: Load config

```sql
LOAD MYSQL SERVERS TO RUNTIME;
SAVE MYSQL SERVERS TO DISK;

LOAD MYSQL USERS TO RUNTIME;
SAVE MYSQL USERS TO DISK;
```

---

# 🔥 STEP 7: Configure Read/Write Split

👉 Create hostgroups:

```sql
INSERT INTO mysql_replication_hostgroups 
(writer_hostgroup, reader_hostgroup, check_type) 
VALUES (10, 20, 'read_only');
```

---

👉 Move servers:

```sql
UPDATE mysql_servers SET hostgroup_id=10 WHERE hostname='10.10.100.101';
UPDATE mysql_servers SET hostgroup_id=20 WHERE hostname IN ('10.10.100.102','10.10.100.103');
```

---

# 🔁 Reload again

```sql
LOAD MYSQL SERVERS TO RUNTIME;
SAVE MYSQL SERVERS TO DISK;
```

---

# 🔥 STEP 8: Connect via ProxySQL

```bash
mysql -uclusteradmin -p -h 10.10.100.104 -P6033
```

---

# 🔍 Test

```sql
SELECT @@hostname;
```

---

# 🧠 How ProxySQL works

👉 It:

* Detects PRIMARY (read_only=0)
* Routes writes → PRIMARY
* Routes reads → SECONDARY

---

# 🔥 ProxySQL vs MySQL Router

| Feature        | Router  | ProxySQL |
| -------------- | ------- | -------- |
| Setup          | Simple  | Complex  |
| Routing        | Basic   | Advanced |
| Query routing  | ❌       | ✅        |
| Load balancing | Limited | Advanced |
| Monitoring     | Basic   | Strong   |

---

# 💡 Real-world usage

👉 Many companies use:

```text
ProxySQL (instead of Router)
```

👉 Because:

* Query rules
* Better control
* Advanced routing

---

# ⚠️ Important

👉 If both installed:

* Use **different ports**
* Don’t confuse:

```text
Router → 6446
ProxySQL → 6033
```

---

# 🧠 Interview killer answer

> “ProxySQL can be deployed alongside MySQL Router, but in production it is recommended to separate them. ProxySQL provides advanced query routing and load balancing compared to MySQL Router.”

---

# 🚀 Next level (very important)

If you want I’ll show:

👉 Auto failover detection in ProxySQL
👉 Query routing rules (SELECT vs INSERT)
👉 Monitoring tables inside ProxySQL
👉 Real production architecture

---

Say:
👉 **“ProxySQL advanced setup”**
I’ll take you deeper 🔥
=============================================
--------------------------------------------------------------
Good point Chandu 👍 — this confusion is very common.

👉 In ProxySQL:

* You are **NOT working inside MySQL database**
* You are working inside **ProxySQL internal admin database**

👉 When you login:

```bash
mysql -uadmin -p -h 127.0.0.1 -P6032
```

👉 You are inside:

```text
ProxySQL Admin (not MySQL server)
```

---

# 🔥 Now I’ll rework COMPLETE steps (clear + no confusion)

---

# 🏗️ STEP 1: Login to vm4

```bash
ssh venkat@10.10.100.104
```

---

# ⚙️ STEP 2: Install ProxySQL

```bash
sudo dnf install -y proxysql
```

---

# ▶️ STEP 3: Start ProxySQL

```bash
sudo systemctl enable proxysql
sudo systemctl start proxysql
```

---

# 🔐 STEP 4: Login to ProxySQL ADMIN (IMPORTANT)

```bash
mysql -uadmin -p -h 127.0.0.1 -P6032
```

👉 Password:

```
admin
```

---

# 🧠 VERY IMPORTANT

👉 Now run:

```sql
SHOW DATABASES;
```

👉 Output:

```
main
monitor
stats
```

👉 You will work inside:

```text
main database (ProxySQL internal config)
```

---

# 🔥 STEP 5: Check tables

```sql
SHOW TABLES FROM main;
```

👉 Important tables:

* mysql_servers
* mysql_users
* mysql_replication_hostgroups

---

# 🔥 STEP 6: Add MySQL cluster nodes

👉 Run in ProxySQL (admin console):

```sql
INSERT INTO main.mysql_servers (hostgroup_id, hostname, port) VALUES (10,'10.10.100.101',3306);
INSERT INTO main.mysql_servers (hostgroup_id, hostname, port) VALUES (10,'10.10.100.102',3306);
INSERT INTO main.mysql_servers (hostgroup_id, hostname, port) VALUES (10,'10.10.100.103',3306);
```

---

# 🔥 STEP 7: Add MySQL user

👉 This user must exist in MySQL cluster also

```sql
INSERT INTO main.mysql_users (username, password, default_hostgroup) 
VALUES ('clusteradmin','Cluster@123',10);
```

---

# 🔥 STEP 8: Enable read/write split (IMPORTANT)

```sql
INSERT INTO main.mysql_replication_hostgroups 
(writer_hostgroup, reader_hostgroup, check_type) 
VALUES (10, 20, 'read_only');
```

---

# 🔥 STEP 9: Move nodes into correct groups

👉 PRIMARY → writer (10)
👉 SECONDARY → reader (20)

Example:

```sql
UPDATE main.mysql_servers SET hostgroup_id=10 WHERE hostname='10.10.100.101';
UPDATE main.mysql_servers SET hostgroup_id=20 WHERE hostname IN ('10.10.100.102','10.10.100.103');
```

---

# 🔥 STEP 10: Apply changes (VERY IMPORTANT)

👉 Nothing works until you load:

```sql
LOAD MYSQL SERVERS TO RUNTIME;
SAVE MYSQL SERVERS TO DISK;

LOAD MYSQL USERS TO RUNTIME;
SAVE MYSQL USERS TO DISK;
```

---

# 🔥 STEP 11: Verify config

```sql
SELECT * FROM main.mysql_servers;
```

```sql
SELECT * FROM main.mysql_users;
```

---

# 🚀 STEP 12: Test connection (CLIENT SIDE)

Exit ProxySQL admin and run:

```bash
mysql -uclusteradmin -p -h 10.10.100.104 -P6033
```

---

# 🔍 Test routing

```sql
SELECT @@hostname;
```

👉 Output:

* Write → PRIMARY
* Read → SECONDARY

---

# 🧠 FINAL CLARITY

| Where you run          | Purpose        |
| ---------------------- | -------------- |
| MySQL (3306)           | DB server      |
| ProxySQL Admin (6032)  | Config         |
| ProxySQL Client (6033) | App connection |

---

# 🔥 Common mistakes (you avoided 👍)

❌ Running commands in MySQL instead of ProxySQL
❌ Not using `main.` prefix
❌ Forgetting LOAD/SAVE

---

# 💡 Interview killer line

> “ProxySQL configuration is done via its internal admin interface using tables like mysql_servers and mysql_users in the main schema.”

---

# 🚀 If you want next

👉 Auto failover in ProxySQL
👉 Query routing rules (SELECT → secondary)
👉 Monitoring tables (stats_mysql_connection_pool)

---

Say:
👉 **“ProxySQL advanced”** 🔥

Perfect Chandu 🔥 — now we go **ADVANCED ProxySQL (real production level)**.

I’ll cover:

1. ✅ Auto failover detection
2. ✅ Query routing (SELECT vs INSERT)
3. ✅ Monitoring tables
4. ✅ Health checks
5. ✅ Real production tips

---

# 🧠 1. Auto Failover Detection (MOST IMPORTANT)

👉 ProxySQL automatically detects PRIMARY using:

```text
read_only = 0 → PRIMARY  
read_only = 1 → SECONDARY
```

---

## 🔥 Configure properly

👉 Login to ProxySQL admin:

```bash
mysql -uadmin -p -h 127.0.0.1 -P6032
```

---

## 🔹 Set replication hostgroups

```sql
DELETE FROM main.mysql_replication_hostgroups;

INSERT INTO main.mysql_replication_hostgroups 
(writer_hostgroup, reader_hostgroup, check_type) 
VALUES (10, 20, 'read_only');
```

---

## 🔹 Enable monitoring user

👉 Create user in MySQL (ALL NODES):

```sql
CREATE USER 'monitor'@'%' IDENTIFIED BY 'monitor';
GRANT USAGE, REPLICATION CLIENT ON *.* TO 'monitor'@'%';
```

---

👉 Configure in ProxySQL:

```sql
UPDATE main.global_variables 
SET variable_value='monitor' 
WHERE variable_name='mysql-monitor_username';

UPDATE main.global_variables 
SET variable_value='monitor' 
WHERE variable_name='mysql-monitor_password';
```

---

## 🔹 Apply

```sql
LOAD MYSQL VARIABLES TO RUNTIME;
SAVE MYSQL VARIABLES TO DISK;
```

---

👉 Now ProxySQL:

* Continuously checks nodes
* Detects PRIMARY automatically
* Moves nodes between hostgroups 🔥

---

# 🔥 2. Query Routing (READ/WRITE SPLIT)

👉 Default:

* Writes → writer_hostgroup (10)
* Reads → reader_hostgroup (20)

---

## 🔹 Advanced query rule

👉 Example: route SELECT to secondary

```sql
INSERT INTO main.mysql_query_rules 
(rule_id, active, match_pattern, destination_hostgroup, apply)
VALUES 
(1, 1, '^SELECT.*', 20, 1);
```

---

## 🔹 Apply

```sql
LOAD MYSQL QUERY RULES TO RUNTIME;
SAVE MYSQL QUERY RULES TO DISK;
```

---

👉 Now:

```sql
SELECT * FROM table → SECONDARY  
INSERT/UPDATE → PRIMARY
```

---

# 🔥 3. Monitoring Tables (VERY IMPORTANT)

👉 Switch DB:

```sql
USE stats;
```

---

## 🔹 Connection pool

```sql
SELECT * FROM stats_mysql_connection_pool;
```

👉 Shows:

* Which node is used
* Connection count
* Status

---

## 🔹 Query stats

```sql
SELECT * FROM stats_mysql_query_digest;
```

👉 Shows:

* Top queries
* Execution count
* Performance

---

## 🔹 Backend health

```sql
SELECT * FROM stats_mysql_global;
```

---

# 🔥 4. Check node health (runtime view)

```sql
SELECT hostgroup_id, hostname, status 
FROM runtime_mysql_servers;
```

👉 Status:

* ONLINE ✅
* SHUNNED ❌ (node removed due to issue)

---

# 🔥 5. Simulate failover (TEST)

👉 Stop PRIMARY (vm1/vm2/vm3 whichever is primary)

```bash
sudo systemctl stop mysqld
```

---

👉 Check ProxySQL:

```sql
SELECT * FROM runtime_mysql_servers;
```

👉 You’ll see:

* Old primary → OFFLINE
* New primary → in writer group 🔥

---

👉 Test:

```bash
mysql -uclusteradmin -p -h 10.10.100.104 -P6033
```

```sql
SELECT @@hostname;
```

👉 Should connect to new PRIMARY automatically ✅

---

# 🔥 6. Important variables tuning

```sql
SELECT * FROM global_variables 
WHERE variable_name LIKE 'mysql-monitor%';
```

---

👉 Key ones:

| Variable                         | Purpose                |
| -------------------------------- | ---------------------- |
| mysql-monitor_connect_interval   | Health check frequency |
| mysql-monitor_ping_interval      | Ping interval          |
| mysql-monitor_read_only_interval | Detect primary         |

---

---

# 🔥 7. Debug issues (real DBA)

## 👉 Check errors

```sql
SELECT * FROM stats_mysql_errors;
```

---

## 👉 Check slow queries

```sql
SELECT * FROM stats_mysql_query_digest ORDER BY sum_time DESC LIMIT 10;
```

---

---

# 🔥 8. Real Production Architecture

```text
App
 ↓
Load Balancer
 ↓
ProxySQL (2 nodes)
 ↓
MySQL InnoDB Cluster (3 nodes)
```

---

# ⚠️ Common mistakes

❌ Not configuring monitor user
❌ Forgetting LOAD/SAVE
❌ Wrong hostgroup mapping
❌ Query rules not applied

---

# 🧠 Interview killer answers

### 👉 Auto failover:

> “ProxySQL detects primary node using read_only variable and automatically routes traffic without application changes.”

---

### 👉 Query routing:

> “We use mysql_query_rules to route SELECT queries to read replicas and write queries to primary.”

---

### 👉 Monitoring:

> “ProxySQL provides stats tables like stats_mysql_connection_pool and stats_mysql_query_digest for real-time monitoring.”

---

# 🚀 You reached advanced level

Chandu — now you know:

✅ InnoDB Cluster HA
✅ Router
✅ ProxySQL
✅ Failover
✅ Query routing
✅ Monitoring

👉 This is **complete MySQL HA stack** 💯

---



