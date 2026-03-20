 **Production-style MySQL Router setup on vm4 (10.10.100.104)** step-by-step.

👉 You will do as **venkat (DBA user with sudo)**


---

### 🏗️ STEP 1: Login to vm4

```bash
ssh venkat@10.10.100.104
```

---

### ⚙️ STEP 2: Install MySQL Router

```bash
sudo dnf install -y mysql-router
```

---

### 🔥 STEP 3: Open Firewall (IMPORTANT)

```bash
sudo systemctl enable firewalld
sudo systemctl start firewalld
```

👉 Open Router ports:

```bash
sudo firewall-cmd --permanent --add-port=6446/tcp
sudo firewall-cmd --permanent --add-port=6447/tcp
sudo firewall-cmd --reload
```

---

### 🚀 STEP 4: Bootstrap Router (MAIN SETUP)

👉 Run from vm4:

```bash
mysqlrouter --bootstrap clusteradmin@10.10.100.101:3306 \
--directory /home/venkat/mysqlrouter \
--user=venkat
```

👉 Enter password:

```text
Cluster@123
```

---

### 🧠 What this does

* Connects to your cluster (vm1/vm2/vm3)
* Auto-detects topology
* Creates routing config

---

### 📁 STEP 5: Check OS files

```bash
cd /home/venkat/mysqlrouter
ls
```

You will see:

```
mysqlrouter.conf
start.sh
stop.sh
log/
run/
```

---

### ▶️ STEP 6: Start Router

```bash
./start.sh
```

---

### 🔍 STEP 7: Verify ports

```bash
ss -tulnp | grep 644
```

👉 Expected:

```
6446 → RW (PRIMARY)
6447 → RO (SECONDARY)
```

---

### 🔥 STEP 8: TEST CONNECTION

#### 👉 Write (PRIMARY)

```bash
mysql -uclusteradmin -p -h 10.10.100.104 -P 6446
```

Run:

```sql
select @@hostname;
```

👉 Output:

```
oel9-vm3   (current PRIMARY)
```

---

### 👉 Read (SECONDARY)

```bash
mysql -uclusteradmin -p -h 10.10.100.104 -P 6447
```

```sql
select @@hostname;
```

👉 Output:

```
oel9-vm1 or vm2
```

---

### 🔥 STEP 9: FAILOVER TEST (REALTIME TEST)

👉 Stop PRIMARY (vm3)

```bash
sudo systemctl stop mysqld
```

---

👉 Now again connect via Router:

```bash
mysql -uclusteradmin -p -h 10.10.100.104 -P 6446
```

```sql
select @@hostname;
```

👉 Output:

```
oel9-vm1 or vm2 (NEW PRIMARY) 🔥
```

---

#### 🧠 What happened?

👉 Router automatically:

* Detected new PRIMARY
* Redirected connection

👉 App didn’t change anything ✅

---

#### ⚠️ Important production notes

👉 Router is:

* Stateless
* Lightweight

👉 You can run multiple routers

👉 No data stored → safe

---

# 🔥 Interview killer explanation

> “I deployed MySQL Router on a separate node and bootstrapped it against the InnoDB Cluster. It automatically routes write traffic to the primary and read traffic to secondary nodes, ensuring seamless failover.”

---

#### 🚀 You have now built FULL STACK HA

now you completed:

✅ InnoDB Cluster
✅ Failover testing
✅ Router setup
✅ Application routing

This is **Complete production architecture** 💯

---

# 🚀 Next level 

👉 Multiple Router HA setup
👉 Load balancer (VIP)
👉 Read/write split testing
👉 Real interview Q&A from this setup

---


