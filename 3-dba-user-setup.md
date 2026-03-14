**DBA User setup**:

1️⃣ Create a **DBA user**
2️⃣ Give **root/admin (sudo) privileges**
3️⃣ Setup **passwordless SSH between servers**

I will show **correct Linux admin method step-by-step**. 🧑‍💻

---

# 1️⃣ Login as root

First login as root on the server.

```bash
sudo -i
```

or

```bash
su -
```

---

# 2️⃣ Create DBA user

Example username: **dba**

```bash
useradd -m -s /bin/bash dba
```

Set password:

```bash
passwd dba
```

---

# 3️⃣ Give sudo (admin) privileges

Edit sudoers safely:

```bash
visudo
```

Add this line:

```bash
dba ALL=(ALL) NOPASSWD:ALL
```

Now **dba user has root privileges**.

Test:

```bash
su - dba
sudo su -
```

You should become root.

---

# 4️⃣ Create SSH directory for dba

Login as **dba**:

```bash
su - dba
```

Create SSH folder:

```bash
mkdir ~/.ssh
chmod 700 ~/.ssh
```

---

# 5️⃣ Generate SSH keys

Run:

```bash
ssh-keygen -t rsa -b 2048
```

Press **Enter** for all prompts.

Files created:

```bash
~/.ssh/id_rsa
~/.ssh/id_rsa.pub
```

---

# 6️⃣ Copy keys to other servers

Run from **source server**:

```bash
ssh-copy-id dba@10.0.1.2
```

```bash
ssh-copy-id dba@10.0.2.2
```

```bash
ssh-copy-id dba@10.0.3.2
```

```bash
ssh-copy-id dba@10.0.1.3
```

```bash
ssh-copy-id dba@10.0.2.3
```

Enter password first time.

---

# 7️⃣ Test passwordless login

Example:

```bash
ssh dba@10.0.1.2
```

It should login **without password**.

---

# 8️⃣ Verify sudo privilege

Inside remote server:

```bash
sudo su -
```

You should become root.

---

# ✅ Final result

Your **DBA environment will look like**:

```bash
User        : dba
Privilege   : sudo/root
SSH access  : passwordless
Servers     : cluster nodes
```

Used for:

* MySQL Cluster
* Galera Cluster
* PostgreSQL HA
* Automation
* Ansible

---

🔥 **Real DBA best practice**

Most companies create:

```bash
useradd dba
useradd mysql
useradd postgres
```

Instead of using **root** directly.

---

If you want, I can also show **professional DBA server hardening steps (10 commands)** used in **real production servers**. 🚀
