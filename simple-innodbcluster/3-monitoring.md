**DBA monitoring**.
 **cluster views + replication views + monitoring queries**.

---

### 🧱 1. MySQL Shell (Cluster level)

👉 Use in `mysqlsh`

#### ✅ Basic status

```js
cluster.status()
```

#### ✅ Clean view

```js
cluster.describe()
```

#### ✅ Only topology

```js
cluster.status().defaultReplicaSet.topology
```

#### ✅ Primary node

```js
cluster.status().defaultReplicaSet.primary
```

---

### 🧠 2. Core Monitoring Tables (VERY IMPORTANT)

👉 Login normal mysql:

```bash
mysql -uroot -p
```

---

### 🔥 3. Group Replication (Cluster status)

#### ✅ Members status (MOST IMPORTANT)

```sql
SELECT 
MEMBER_ID,
MEMBER_HOST,
MEMBER_PORT,
MEMBER_STATE,
MEMBER_ROLE
FROM performance_schema.replication_group_members;
```

---

#### ✅ Who is PRIMARY?

```sql
SELECT MEMBER_HOST 
FROM performance_schema.replication_group_members
WHERE MEMBER_ROLE='PRIMARY';
```

---

#### ✅ Online / offline nodes

```sql
SELECT MEMBER_HOST, MEMBER_STATE 
FROM performance_schema.replication_group_members;
```

---

### 🔄 4. Replication Stats (VERY IMPORTANT)

## ✅ Applier status

```sql
SELECT * 
FROM performance_schema.replication_group_member_stats;
```

👉 Shows:

* transactions applied
* queue size
* lag

---

#### ✅ Check replication lag (approx)

```sql
SELECT 
MEMBER_HOST,
COUNT_TRANSACTIONS_IN_QUEUE
FROM performance_schema.replication_group_member_stats;
```

👉 If > 0 → lag ⚠️

---

### ⚡ 5. Replication Applier Threads

```sql
SELECT * 
FROM performance_schema.replication_applier_status;
```

---

```sql
SELECT * 
FROM performance_schema.replication_applier_status_by_worker;
```

👉 Used for:

* Parallel replication issues
* Worker lag

---

### 📊 6. Binary Log / GTID

#### ✅ GTID executed

```sql
SHOW VARIABLES LIKE 'gtid%';
```

```sql
SHOW MASTER STATUS;
```

---

### 🔍 7. InnoDB Cluster metadata

👉 Cluster info stored here:

```sql
SELECT * FROM mysql_innodb_cluster_metadata.clusters;
```

```sql
SELECT * FROM mysql_innodb_cluster_metadata.instances;
```

---

### 🔥 8. Check read-only mode

```sql
SELECT @@read_only, @@super_read_only;
```

👉 PRIMARY:

```
0,0
```

👉 SECONDARY:

```
1,1
```

---

### 🚨 9. Error / health check

```sql
SHOW ENGINE INNODB STATUS;
```

---

```sql
SHOW PROCESSLIST;
```

---

### 📈 10. Quick health dashboard query

```sql
SELECT 
MEMBER_HOST,
MEMBER_ROLE,
MEMBER_STATE,
COUNT_TRANSACTIONS_IN_QUEUE AS LAG
FROM performance_schema.replication_group_members m
JOIN performance_schema.replication_group_member_stats s
USING (MEMBER_ID);
```

---

### 🧠 11. Router monitoring (bonus)

👉 Check router logs:

```bash
cd /home/venkat/mysqlrouter/log
tail -f mysqlrouter.log
```

---

### 🔥 MOST IMPORTANT (remember these 5)

If interviewer asks:

👉 You must say:

1. `replication_group_members` ✅
2. `replication_group_member_stats` ✅
3. `cluster.status()` ✅
4. `SHOW MASTER STATUS` ✅
5. `read_only check` ✅

---

### 🚀 Interview killer answer

> “I monitor InnoDB Cluster using performance_schema tables like replication_group_members and replication_group_member_stats along with MySQL Shell commands such as cluster.status().”

---

### 💪 Real DBA tip

👉 Daily monitoring:

* Node status
* Primary check
* Lag
* Read-only mode

---
Issue Related
* Alert scripts
* Real production issues (node stuck, lag, split brain)
* L2/L3 interview Q&A

