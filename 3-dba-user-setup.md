```
ams-vm-1 → 10.0.1.2
ams-vm-2 → 10.0.2.2
ams-vm-3 → 10.0.3.2
ams-vm-4 → 10.0.1.3
ams-vm-5 → 10.0.2.3
```

Goal:
✅ Create **dba user**
✅ Give **root (sudo) access**
✅ Enable **passwordless SSH between servers**

---

### STEP 1 — Create DBA user (Run on ALL 5 VMs)

Login to each VM from **GCP SSH console** and run:

```bash
sudo -i
```

Create user:

```bash
useradd -m -s /bin/bash dba
```

Set password:

```bash
echo "dba:dba@123" | chpasswd
```

Give **root privileges**:

```bash
echo "dba ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
```

Switch to dba:

```bash
su - dba
```

Create SSH directory:

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
```

Do this **on all 5 servers**.

---

### STEP 2 — Generate SSH key (ONLY on ams-vm-1)

Login to:

```
ams-vm-1
```

Switch to dba:

```bash
su - dba
```

Generate key:

```bash
ssh-keygen -t rsa -b 2048
```

Press **Enter for everything**.

Check:

```bash
ls ~/.ssh
```

You will see:

```
id_rsa
id_rsa.pub
```

---

### STEP 3 — Copy SSH key to other servers

Run from **ams-vm-1**:

```
ssh-copy-id dba@10.0.2.2
```

Enter password:

```
dba@123
```

Then run:

```
ssh-copy-id dba@10.0.3.2
ssh-copy-id dba@10.0.1.3
ssh-copy-id dba@10.0.2.3
```

---

# STEP 4 — Test passwordless login

Test from **ams-vm-1**:

```
ssh dba@10.0.2.2
```

```
ssh dba@10.0.3.2
```

```
ssh dba@10.0.1.3
```

```
ssh dba@10.0.2.3
```

Now **no password should ask**.

---

# FINAL ARCHITECTURE

```
ams-vm-1 (10.0.1.2)
        │
        ├── SSH → ams-vm-2 (10.0.2.2)
        ├── SSH → ams-vm-3 (10.0.3.2)
        ├── SSH → ams-vm-4 (10.0.1.3)
        └── SSH → ams-vm-5 (10.0.2.3)
```

User:

```
dba
password: dba@123
sudo access: yes
```

---

✅ This above setup is used for below mentioned 

* MySQL Cluster
* Galera Cluster
* PostgreSQL Patroni
* Ansible automation

