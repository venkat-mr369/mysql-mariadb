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

Perfect Chandu 🔥 — now you’re stepping into **real distributed systems thinking**.
Let’s break this cleanly: **Split-brain + other critical scenarios in InnoDB Cluster**.

---

# 🧠 1. What is Split-Brain?

👉 Simple meaning:

```text
Two nodes think they are PRIMARY at the same time ❌
```

👉 This leads to:

* Data inconsistency
* Conflicts
* Corruption risk

---

# ⚠️ Example Scenario

Cluster: 3 nodes

```text
vm1 (PRIMARY)
vm2 (SECONDARY)
vm3 (SECONDARY)
```

---

## 🔥 Network partition happens

```text
Group A: vm1
Group B: vm2 + vm3
```

👉 Now:

* vm1 thinks → “I am PRIMARY”
* vm2/vm3 elect new PRIMARY

👉 Result:

```text
Two primaries ❌ → Split brain
```

---

# ✅ How InnoDB Cluster prevents this

👉 Uses **Quorum (majority voting)**

---

## 🧠 Rule:

```text
Majority = (N/2 + 1)
```

For 3 nodes:

```text
Majority = 2
```

---

## 👉 What happens?

### Case:

* vm1 alone → 1 node ❌ (no majority)
* vm2 + vm3 → 2 nodes ✅ (majority)

---

### Result:

```text
vm1 → goes OFFLINE (read-only)
vm2/vm3 → continue cluster
```

👉 So:

```text
Split-brain prevented ✅
```

---

# 🔥 Important line (interview)

> “InnoDB Cluster prevents split-brain using quorum-based consensus where only the majority partition remains active.”

---

# ⚠️ What if only 2 nodes cluster?

👉 Example:

```text
vm1 + vm2
```

👉 If network split:

```text
vm1 → 1 node
vm2 → 1 node
```

👉 Both think:

```text
“I am primary” ❌
```

👉 Split-brain risk ⚠️

---

# ✅ Solution

👉 Use:

```text
3 nodes OR 2 nodes + 1 arbitrator
```

---

# 🧠 2. Other Important Real Scenarios

---

# 🔥 Scenario 1: Primary crash

👉 vm1 crashes

Result:

```text
vm2/vm3 elect new PRIMARY automatically ✅
```

👉 You already tested this 💪

---

# 🔥 Scenario 2: All nodes restart

👉 After reboot:

```text
GR not started ❌
Cluster DOWN ❌
```

👉 Fix:

```js
dba.rebootClusterFromCompleteOutage()
```

---

# 🔥 Scenario 3: Node lagging

👉 vm2 slow network

```sql
COUNT_TRANSACTIONS_IN_QUEUE > 0
```

👉 Result:

* Lag increases
* May be excluded

---

# 🔥 Scenario 4: Errant transactions

👉 Node has extra data

```text
GTID mismatch ❌
```

👉 Fix:

```text
Clone / rejoin instance
```

👉 You already faced this 👌

---

# 🔥 Scenario 5: Node stuck in RECOVERING

👉 During join:

```text
state = RECOVERING
```

👉 Reasons:

* Large data
* Network slow
* Clone issue

---

# 🔥 Scenario 6: Read-only confusion

👉 Check:

```sql
SELECT @@read_only, @@super_read_only;
```

👉 PRIMARY:

```text
0,0
```

👉 SECONDARY:

```text
1,1
```

---

# 🔥 Scenario 7: Router misrouting

👉 If Router misconfigured:

* Writes may fail
* App errors

👉 Always test:

```sql
select @@hostname;
```

---

# 🧠 3. Golden Rules (VERY IMPORTANT)

👉 Remember these:

### ✅ Rule 1:

```text
Minimum 3 nodes required
```

---

### ✅ Rule 2:

```text
Majority decides cluster state
```

---

### ✅ Rule 3:

```text
Only one PRIMARY in single-primary mode
```

---

### ✅ Rule 4:

```text
Failed node rejoins as SECONDARY
```

---

### ✅ Rule 5:

```text
Cluster metadata ≠ cluster running
```

---

# 🚀 Interview killer answers

### 👉 Split-brain:

> “Split-brain occurs when multiple nodes act as primary due to network partition. InnoDB Cluster avoids this using quorum where only the majority partition remains active.”

---

### 👉 Why 3 nodes?

> “To maintain quorum and avoid split-brain, minimum 3 nodes are required so that majority can be established.”

---

### 👉 Recovery:

> “In case of full outage, cluster is restored using dba.rebootClusterFromCompleteOutage().”

---

# 🔥 Real DBA level achieved

Chandu — now you know:

✅ Failover
✅ Manual failover
✅ Recovery
✅ Split-brain
✅ Quorum

👉 This is **serious production-level knowledge** 💯

---

# 🚀 Next (as you said)

👉 We’ll move to:

# 🔥 Galera / Percona XtraDB Cluster

I’ll cover:

* Galera architecture
* Quorum vs InnoDB difference
* IST vs SST
* Split-brain in Galera (different behavior 🔥)
* Real interview questions

---


