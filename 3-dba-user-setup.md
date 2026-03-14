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
ls -l ~/.ssh
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

### In GCP try like this 
**password login is disabled on the target VM (10.0.2.2)**.
`ssh-copy-id` works **only when password authentication is allowed**.

Your error:

```id="3u7o7u"
Permission denied (publickey,gssapi-keyex,gssapi-with-mic)
```

means the server **accepts only SSH keys**, not passwords.

So we must **copy the key manually once**.

---

### Step 1 — Switch to dba user

```bash id="x35gbo"
sudo su - dba
```

---

### Step 2 — Create SSH folder

```bash id="gtmof1"
mkdir -p ~/.ssh
chmod 700 ~/.ssh
```

---

### Step 5 — Add the key

Open file:

```bash id="j3tdax"
vi ~/.ssh/authorized_keys
```

Paste the **public key you copied**.

Save.

---

### Step 6 — Fix permissions

```bash id="hpb0d6"
chmod 600 ~/.ssh/authorized_keys
```

---

### Step 7 — Test from ams-vm-1

Back on **ams-vm-1** run:

```bash id="2my30k"
ssh dba@10.0.2.2
```

Now it should login **without password**.

---

# Repeat same for remaining nodes

Copy key to:

```id="n88f5y"
10.0.3.2
10.0.1.3
10.0.2.3
```

---

# Quick Visual

```id="m8yiz1"
ams-vm-1 (10.0.1.2)
     │
     ├──> 10.0.2.2
     ├──> 10.0.3.2
     ├──> 10.0.1.3
     └──> 10.0.2.3
```

---

💡 **Why this happened in GCP**

GCP VMs use:

```id="3q7vya"
PasswordAuthentication no
```

in **/etc/ssh/sshd_config**.

So `ssh-copy-id` fails.

---


