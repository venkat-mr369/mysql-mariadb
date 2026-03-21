👉 MySQL Router Installation on vm4 for App Connecting

```bash
[venkat@oel9-vm1 ~]
```

❌ You should not on vm1
👉 We must do everything on **vm4 (10.10.100.104)**

---

### 🔥 COMPLETE CLEAN SETUP (vm4 only)

---

### 🏗️ STEP 1: Login to vm4

```bash
ssh venkat@10.10.100.104
```

👉 Confirm:

```bash
hostname
```

✔ Should show:

```
oel9-vm4
```

---

### ⚙️ STEP 2: Install MySQL Repo (MANDATORY)

👉 vm4 lo MySQL repo ledu, so install cheyyali:

```bash
sudo dnf install -y https://dev.mysql.com/get/mysql80-community-release-el9-1.noarch.rpm
```

---

### 🔍 STEP 3: Enable repo

```bash
sudo dnf config-manager --enable mysql80-community
```

---

### 🔑 STEP 4: Fix GPG key (same issue to avoid)

```bash
sudo rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2023
```

---

### 🧹 STEP 5: Clean cache

```bash
sudo dnf clean all
sudo dnf makecache
```

---

### 🔍 STEP 6: Verify repo

```bash
sudo dnf repolist | grep mysql
```

👉 You should see:

```
mysql80-community
```

---

### 📦 STEP 7: Install MySQL Router

👉 Try this:

```bash
sudo dnf install -y mysql-router
```

---

#### ❗ If not found (very common)

👉 Use:

```bash
sudo dnf install -y mysql-community-router
```

---

### 🔥 STEP 8: Open Firewall

```bash
sudo systemctl enable firewalld
sudo systemctl start firewalld
```

```bash
sudo firewall-cmd --permanent --add-port=6446/tcp
sudo firewall-cmd --permanent --add-port=6447/tcp
sudo firewall-cmd --reload
```

---

### 🚀 STEP 9: Bootstrap Router

```bash
mysqlrouter --bootstrap clusteradmin@10.10.100.101:3306 \
--directory /home/venkat/mysqlrouter \
--user=venkat
```

👉 Password:

```
Cluster@123
```

---

#### 📁 STEP 10: Check files

```bash
cd /home/venkat/mysqlrouter
ls
```

---

### ▶️ STEP 11: Start Router

```bash
./start.sh
```

Or

```bash 
nohup ./start.sh > router.log 2>&1 &
```

Or

```bash
# Use built-in background mode
./start.sh &
```
---

---

### 🔥 Production standard ✅

👉 Run as **systemd service**

---

#### 🔹 Create service file

```bash
sudo vi /etc/systemd/system/mysqlrouter.service
```

Paste:

```ini
[Unit]
Description=MySQL Router
After=network.target

[Service]
User=venkat
ExecStart=/home/venkat/mysqlrouter/start.sh
Restart=always
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
```

---

#### 🔹 Reload systemd

```bash
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
```

---

#### 🔹 Start service

```bash
sudo systemctl start mysqlrouter
```

---

#### 🔹 Enable auto-start

```bash
sudo systemctl enable mysqlrouter
```

---

### 🔍 STEP 12: Verify ports

```bash
ss -tulnp | grep 644
```

---

### 🔥 STEP 13: TEST

```bash
mysql -uclusteradmin -p -h 10.10.100.104 -P 6446
```

```sql
select @@hostname;
```

---

### 🧠 MOST IMPORTANT FIX SUMMARY

| Issue                  | Fix                |
| ---------------------- | ------------------ |
| mysql-router not found | Install MySQL repo |
| GPG error              | Import 2023 key    |
| Wrong node             | Use vm4 only       |

---

### 🚀 If still issue comes

Run this on vm4 and paste:

```bash
sudo dnf search mysql | grep router
```

---

#### 💡 Interview Tip

> “MySQL Router installation requires MySQL community repository; it is not available in default OS repositories.”

---

----
**About Protocols**
---


---

### 🔍 Classic Protocol vs X Protocol in MySQL

#### ✅ 1. Classic Protocol (Traditional MySQL)

This is the **original MySQL protocol** that has existed for decades.

### 🔹 Key Features

* Uses **SQL queries**
* Works with:

  * `mysql` CLI
  * JDBC / ODBC
  * PHP, Python, Java apps
* Default port:

  * **3306 (server)**
  * **6446 / 6447 (via Router)**

---

### 🔹 Example

```sql
SELECT * FROM users;
INSERT INTO orders VALUES (...);
```

👉 Everything is **table-based (rows & columns)**

---

### 🔹 When you use it

* Traditional applications
* OLTP systems
* Existing MySQL-based apps

---

#### ✅ 2. X Protocol (Modern / Document-Based)

Introduced in **MySQL 5.7+**, part of MySQL’s move toward **NoSQL + modern APIs**.

It works with the **MySQL Document Store**.

---

### 🔹 Key Features

* Uses **X DevAPI (not just SQL)**
* Supports:

  * JSON documents
  * CRUD operations like MongoDB
* Default ports:

  * **33060 (server)**
  * **6448 / 6449 (via Router)**

---

### 🔹 Example (JavaScript style)

```javascript
db.users.add({ name: "Ravi", age: 30 })
db.users.find("age > 25")
```

👉 Works like **document database (NoSQL style)**

---

### 🔹 Also supports SQL!

You can still run:

```sql
SELECT * FROM users;
```

---

#### 🧠 Key Differences

| Feature       | Classic Protocol       | X Protocol                    |
| ------------- | ---------------------- | ----------------------------- |
| Query Type    | SQL only               | SQL + NoSQL (JSON)            |
| Data Model    | Tables (rows/columns)  | Documents (JSON)              |
| API           | Traditional connectors | X DevAPI                      |
| Port (Router) | 6446 / 6447            | 6448 / 6449                   |
| Use Case      | Legacy / standard apps | Modern apps / microservices   |
| Protocol Type | Text-based             | Message-based (protobuf-like) |

---

#### 🔥 Simple Analogy

* **Classic Protocol** = 📊 Excel tables (structured rows)
* **X Protocol** = 📦 JSON documents (flexible structure)

---

#### 🚀 When Should You Use What?

### ✔ Use Classic Protocol (MOST COMMON)

* Existing apps
* OLTP workloads
* JDBC / ORM frameworks (Hibernate, etc.)

👉 90% of production systems use this

---

### ✔ Use X Protocol (Modern Use Cases)

* Microservices
* JSON-heavy data
* Flexible schema apps
* Hybrid SQL + NoSQL needs

---

#### ⚠️ Important Reality

Even though X Protocol is powerful:
👉 Most enterprises still use **Classic Protocol**

X Protocol is growing but not yet dominant.

---

#### 🔎 In Your Case (MySQL Router Setup)

From your ports:

* **6446 / 6447 → Classic → Your main app should use this**
* **6448 / 6449 → X Protocol → optional / advanced usage**

---

#### 💡 Quick Test

### Classic:- VM4

```bash
mysql -h 10.10.100.104 -P 6446 -u root -p
```

### X Protocol (MySQL Shell): VM4 
#### mysqlsh from vm1 

```bash
mysqlsh --uri clusteradmin@10.10.100.104:6448
```

---


