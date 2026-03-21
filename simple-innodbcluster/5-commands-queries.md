**clear commands + queries** for each scenario so you can **actually verify in your lab** (this is real DBA level).

No theory — only **“how to check” commands** 👇

---

# 🧠 1. Check Cluster Overall Status

## 👉 MySQL Shell

```js
var cluster = dba.getCluster()
cluster.status()
```

## 👉 Clean view

```js
cluster.describe()
```

---

# 🔥 2. Check PRIMARY / SECONDARY

```sql
SELECT 
MEMBER_HOST,
MEMBER_ROLE,
MEMBER_STATE
FROM performance_schema.replication_group_members;
```

---

# 🔥 3. Check if node is writable (VERY IMPORTANT)

```sql
SELECT @@hostname, @@read_only, @@super_read_only;
```

👉 Output:

* PRIMARY → `0,0`
* SECONDARY → `1,1`

---

# 🔥 4. Check Group Replication Running or NOT

```sql
SHOW STATUS LIKE 'group_replication%';
```

👉 Important:

```text
group_replication_running = ON / OFF
```

---

# 🔥 5. Check Split-Brain / Quorum Status

```sql
SELECT 
MEMBER_HOST,
MEMBER_STATE,
MEMBER_ROLE
FROM performance_schema.replication_group_members;
```

👉 If node shows:

```text
UNREACHABLE / OFFLINE
```

👉 Means:

* Lost quorum
* Possible network issue

---

# 🔥 6. Check Replication Lag (VERY IMPORTANT)

```sql
SELECT 
MEMBER_HOST,
COUNT_TRANSACTIONS_IN_QUEUE,
COUNT_TRANSACTIONS_REMOTE_IN_APPLIER_QUEUE
FROM performance_schema.replication_group_member_stats;
```

👉 If value > 0:

```text
Replication lag present ⚠️
```

---

# 🔥 7. Check Node Join / Recovery Status

```sql
SELECT 
MEMBER_HOST,
MEMBER_STATE
FROM performance_schema.replication_group_members;
```

👉 Possible states:

* ONLINE ✅
* RECOVERING ⏳
* OFFLINE ❌

---

# 🔥 8. Check GTID (Data consistency)

```sql
SHOW MASTER STATUS;
```

```sql
SHOW VARIABLES LIKE 'gtid%';
```

👉 Compare across nodes

---

# 🔥 9. Check Cluster Metadata

```sql
SELECT * FROM mysql_innodb_cluster_metadata.clusters;
```

```sql
SELECT * FROM mysql_innodb_cluster_metadata.instances;
```

---

# 🔥 10. Check Errors (VERY IMPORTANT)

```bash
sudo tail -50 /var/log/mysqld.log
```

👉 Look for:

* GR errors
* Connection issues
* Recovery failures

---

# 🔥 11. Check Network Connectivity (split-brain debug)

From one node:

```bash
ping 10.10.100.102
ping 10.10.100.103
```

```bash
telnet 10.10.100.102 33061
```

👉 Port 33061 = Group Replication port

---

# 🔥 12. Check Ports (must be open)

```bash
ss -tulnp | grep 33061
```

---

# 🔥 13. Check Router routing

```bash
mysql -uclusteradmin -p -h 10.10.100.104 -P 6446
```

```sql
SELECT @@hostname;
```

---

# 🔥 14. Manual Failover Command

```js
var cluster = dba.getCluster()
cluster.setPrimaryInstance('oel9-vm2:3306')
```

---

# 🔥 15. Rejoin Node

```js
cluster.rejoinInstance('clusteradmin@10.10.100.103:3306')
```

---

# 🔥 16. Full Outage Recovery

```js
dba.rebootClusterFromCompleteOutage()
```

---

# 🔥 17. Check if node stuck (advanced)

```sql
SELECT * FROM performance_schema.replication_applier_status_by_worker;
```

---

# 🔥 18. Process check

```sql
SHOW PROCESSLIST;
```

---

# 🧠 REAL DBA QUICK CHECK (use this daily)

```sql
SELECT 
m.MEMBER_HOST,
m.MEMBER_ROLE,
m.MEMBER_STATE,
s.COUNT_TRANSACTIONS_IN_QUEUE AS LAG
FROM performance_schema.replication_group_members m
JOIN performance_schema.replication_group_member_stats s
USING (MEMBER_ID);
```

---

# 🚀 Scenario Mapping (IMPORTANT)

| Scenario         | Command                   |
| ---------------- | ------------------------- |
| Cluster health   | cluster.status()          |
| Primary node     | replication_group_members |
| Read/write check | @@read_only               |
| Lag              | member_stats              |
| GR running       | SHOW STATUS               |
| Full outage      | rebootCluster             |
| Node join        | rejoinInstance            |
| Failover         | setPrimaryInstance        |

---

# 🔥 Interview killer line

> “I use performance_schema tables like replication_group_members and replication_group_member_stats along with MySQL Shell commands to monitor cluster health, role, and replication lag.”

---

