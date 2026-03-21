👉 Error

👉 Root Cause

👉 Solution

👉 Commands


---

### 📄 **MySQL InnoDB Cluster - Full Outage Recovery **

````markdown
# 🚨 MySQL InnoDB Cluster - Full Outage Scenario & Recovery

## ❗ Problem Statement

While connecting to MySQL Shell and trying to access cluster:

```js
\connect clusteradmin@10.10.100.102:3306
var cluster = dba.getCluster()
````

### ❌ Error:

```
Dba.getCluster: This function is not available through a session to a standalone instance 
(metadata exists, instance belongs to that metadata, but GR is not active) (MYSQLSH 51314)
```

```js
cluster.status()
```

### ❌ Error:

```
Cannot read property 'status' of undefined (TypeError)
```

---

## 🧠 Root Cause

* MySQL InnoDB Cluster metadata exists ✅
* But **Group Replication (GR) is NOT running** ❌
* All nodes are behaving as **standalone instances**

### 📌 Reason:

* MySQL service restarted
* `group_replication_start_on_boot=OFF`
* GR did not auto-start

---

## 🔥 Situation Type

| Scenario           | Status |
| ------------------ | ------ |
| Metadata exists    | ✅     |
| GR running         | ❌     |
| Cluster accessible | ❌     |

👉 **This is a FULL CLUSTER OUTAGE**

---

## ✅ Solution: Reboot Cluster from Complete Outage

### 👉 Step 1: Connect to any one node

```js
\connect clusteradmin@10.10.100.101:3306
```

---

### 👉 Step 2: Reboot cluster

```js
var cluster = dba.rebootClusterFromCompleteOutage()
```

---

### 👉 Step 3: Verify cluster status

```js
cluster.status()
```

---

## 🔄 If nodes do not auto join

```js
cluster.rejoinInstance('clusteradmin@10.10.100.102:3306')
cluster.rejoinInstance('clusteradmin@10.10.100.103:3306')
```

---

## ⚙️ Permanent Fix (VERY IMPORTANT)

### Enable auto-start of Group Replication

On **ALL nodes**:

```bash
sudo vi /etc/my.cnf
```

Update:

```ini
loose-group_replication_start_on_boot=ON
```

---

### Restart MySQL

```bash
sudo systemctl restart mysqld
```

---

## 🧠 Key Learnings

* `dba.getCluster()` works only when GR is active
* Metadata alone is NOT enough
* GR must be running for cluster operations

---

## 📌 Command Usage Summary

| Scenario             | Command                                 |
| -------------------- | --------------------------------------- |
| First time setup     | `dba.createCluster()`                   |
| Normal operation     | `dba.getCluster()`                      |
| Node rejoin          | `cluster.rejoinInstance()`              |
| Full outage recovery | `dba.rebootClusterFromCompleteOutage()` |

---

### 💡 Interview Explanation

> In case of a full cluster outage where metadata exists but Group Replication is inactive on all nodes, we use `dba.rebootClusterFromCompleteOutage()` to restore the cluster safely using existing metadata.

---

### 🚀 Outcome

* Cluster restored successfully ✅
* New PRIMARY elected automatically ✅
* Nodes rejoined as SECONDARY ✅

---

### 💡 Manual Failover

**manual failover (controlled switchover)** in InnoDB Cluster.

👉 Here YOU decide which node becomes PRIMARY

---

### 🎯 Scenario

👉 Current:

```text
PRIMARY   : vm1
SECONDARY : vm2, vm3
```

👉 Goal:

```text
PRIMARY   : vm2 ✅
SECONDARY : vm1, vm3
```

---

### 🔥 Method 1: Clean Manual Failover (Recommended)

#### 👉 Step 1: Connect to any ONLINE node (vm1)

```js
\connect clusteradmin@10.10.100.101:3306
```

OR

```js
\connect clusteradmin@10.10.100.102:3306
```

---

#### 👉 Step 2: Get cluster

```js
var cluster = dba.getCluster()
```

---

#### 👉 Step 3: Switch PRIMARY to vm2

```js
cluster.setPrimaryInstance('oel9-vm2:3306')
```

---

### ✅ Result

👉 Now:

```text
PRIMARY   : vm2 🔥
SECONDARY : vm1, vm3
```

---

### 🔍 Verify

```js
cluster.status()
```

OR

```sql
SELECT MEMBER_HOST, MEMBER_ROLE 
FROM performance_schema.replication_group_members;
```

---

### 🧠 What happens internally

* vm2 promoted to PRIMARY
* vm1 becomes SECONDARY
* No downtime (almost zero)
* No data loss

👉 This is **graceful switchover**

---

### ⚠️ Conditions (IMPORTANT)

👉 Before running:

✔ vm2 must be ONLINE
✔ No replication lag
✔ Cluster healthy

---

### ❌ If node not healthy

👉 Command will fail like:

```text
instance not suitable
```

---

### 🔥 Method 2: Force switch (not recommended)

```js
cluster.setPrimaryInstance('oel9-vm2:3306', {force: true})
```

👉 Use only:

* Emergency
* Node unstable

---

### 💡 Difference (Important)

| Type            | Command            | Behavior   |
| --------------- | ------------------ | ---------- |
| Auto failover   | system decides     | on failure |
| Manual failover | setPrimaryInstance | controlled |
| Force failover  | force:true         | risky      |

---

### 🔥 testing

After switching:

```sql
SELECT @@hostname;
```

👉 From Router (6446)
👉 Should connect to vm2

---



