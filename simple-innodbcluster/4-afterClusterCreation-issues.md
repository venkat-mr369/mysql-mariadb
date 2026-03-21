👉 Error
👉 Root Cause
👉 Solution
👉 Commands


---

# 📄 **MySQL InnoDB Cluster - Full Outage Recovery **

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
| Metadata exists    | ✅      |
| GR running         | ❌      |
| Cluster accessible | ❌      |

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

## 💡 Interview Explanation

> In case of a full cluster outage where metadata exists but Group Replication is inactive on all nodes, we use `dba.rebootClusterFromCompleteOutage()` to restore the cluster safely using existing metadata.

---

## 🚀 Outcome

* Cluster restored successfully ✅
* New PRIMARY elected automatically ✅
* Nodes rejoined as SECONDARY ✅

```

---

# 🔥 Done

👉 This is **GitHub-ready**  
👉 Clean + professional + interview-level  

---

If you want next:
- I can create **full InnoDB Cluster lab doc (setup → failover → router → recovery)**  
- Or **L2/L3 interview Q&A doc**

Just tell me 👍
```
