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
0r
```bash
# Use built-in background mode
./start.sh &
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

