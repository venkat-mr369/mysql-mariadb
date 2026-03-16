For  **3 VMs** with SSH in every direction.

---

## Prerequisites

| Item | VM1 (Source) | VM2 (Replica) | VM3 (Replica) |
|------|-------------|---------------|---------------|
| Hostname | oel9-vm1 | oel9-vm2 | oel9-vm3 |
| IP | 10.10.100.101 | 10.10.100.102 | 10.10.100.103 |

---

## Step 1 — Enable bash shell for mysql user (All 3 Servers)

**On VM1:**
```bash
sudo usermod -s /bin/bash mysql
```

**On VM2:**
```bash
sudo usermod -s /bin/bash mysql
```

**On VM3:**
```bash
sudo usermod -s /bin/bash mysql
```

---

## Step 2 — Create .ssh directory (All 3 Servers)

**On VM1:**
```bash
sudo mkdir -p /var/lib/mysql/.ssh
sudo chown mysql:mysql /var/lib/mysql/.ssh
sudo chmod 700 /var/lib/mysql/.ssh
```

**On VM2:**
```bash
sudo mkdir -p /var/lib/mysql/.ssh
sudo chown mysql:mysql /var/lib/mysql/.ssh
sudo chmod 700 /var/lib/mysql/.ssh
```

**On VM3:**
```bash
sudo mkdir -p /var/lib/mysql/.ssh
sudo chown mysql:mysql /var/lib/mysql/.ssh
sudo chmod 700 /var/lib/mysql/.ssh
```

---

## Step 3 — Generate SSH keys (All 3 Servers)

**On VM1:**
```bash
sudo -u mysql ssh-keygen -t ed25519 -N "" -f /var/lib/mysql/.ssh/id_ed25519
```

**On VM2:**
```bash
sudo -u mysql ssh-keygen -t ed25519 -N "" -f /var/lib/mysql/.ssh/id_ed25519
```

**On VM3:**
```bash
sudo -u mysql ssh-keygen -t ed25519 -N "" -f /var/lib/mysql/.ssh/id_ed25519
```

---

## Step 4 — Collect all public keys

Display the public key on each server and note it down:

**On VM1:**
```bash
sudo cat /var/lib/mysql/.ssh/id_ed25519.pub
```

**On VM2:**
```bash
sudo cat /var/lib/mysql/.ssh/id_ed25519.pub
```

**On VM3:**
```bash
sudo cat /var/lib/mysql/.ssh/id_ed25519.pub
```

You should now have 3 keys. Label them as VM1_KEY, VM2_KEY, and VM3_KEY.

---

## Step 5 — Distribute public keys to authorized_keys

Each server needs the keys of the **other two** servers.

**On VM1** (needs VM2 + VM3 keys):
```bash
sudo bash -c 'echo "PASTE_VM2_KEY_HERE" > /var/lib/mysql/.ssh/authorized_keys'
sudo bash -c 'echo "PASTE_VM3_KEY_HERE" >> /var/lib/mysql/.ssh/authorized_keys'
sudo chmod 600 /var/lib/mysql/.ssh/authorized_keys
sudo chown mysql:mysql /var/lib/mysql/.ssh/authorized_keys
```

**On VM2** (needs VM1 + VM3 keys):
```bash
sudo bash -c 'echo "PASTE_VM1_KEY_HERE" > /var/lib/mysql/.ssh/authorized_keys'
sudo bash -c 'echo "PASTE_VM3_KEY_HERE" >> /var/lib/mysql/.ssh/authorized_keys'
sudo chmod 600 /var/lib/mysql/.ssh/authorized_keys
sudo chown mysql:mysql /var/lib/mysql/.ssh/authorized_keys
```

**On VM3** (needs VM1 + VM2 keys):
```bash
sudo bash -c 'echo "PASTE_VM1_KEY_HERE" > /var/lib/mysql/.ssh/authorized_keys'
sudo bash -c 'echo "PASTE_VM2_KEY_HERE" >> /var/lib/mysql/.ssh/authorized_keys'
sudo chmod 600 /var/lib/mysql/.ssh/authorized_keys
sudo chown mysql:mysql /var/lib/mysql/.ssh/authorized_keys
```

**IMPORTANT:** Notice the first key uses `>` (overwrite) and the second key uses `>>` (append). If you use `>` for both, the first key gets erased.

---

## Step 6 — Add hosts to known_hosts

**On VM1:**
```bash
sudo -u mysql ssh-keyscan -H oel9-vm2 >> /var/lib/mysql/.ssh/known_hosts
sudo -u mysql ssh-keyscan -H 10.10.100.102 >> /var/lib/mysql/.ssh/known_hosts
sudo -u mysql ssh-keyscan -H oel9-vm3 >> /var/lib/mysql/.ssh/known_hosts
sudo -u mysql ssh-keyscan -H 10.10.100.103 >> /var/lib/mysql/.ssh/known_hosts
```

**On VM2:**
```bash
sudo -u mysql ssh-keyscan -H oel9-vm1 >> /var/lib/mysql/.ssh/known_hosts
sudo -u mysql ssh-keyscan -H 10.10.100.101 >> /var/lib/mysql/.ssh/known_hosts
sudo -u mysql ssh-keyscan -H oel9-vm3 >> /var/lib/mysql/.ssh/known_hosts
sudo -u mysql ssh-keyscan -H 10.10.100.103 >> /var/lib/mysql/.ssh/known_hosts
```

**On VM3:**
```bash
sudo -u mysql ssh-keyscan -H oel9-vm1 >> /var/lib/mysql/.ssh/known_hosts
sudo -u mysql ssh-keyscan -H 10.10.100.101 >> /var/lib/mysql/.ssh/known_hosts
sudo -u mysql ssh-keyscan -H oel9-vm2 >> /var/lib/mysql/.ssh/known_hosts
sudo -u mysql ssh-keyscan -H 10.10.100.102 >> /var/lib/mysql/.ssh/known_hosts
```

---

## Step 7 — Verify permissions (All 3 Servers)

Run on **each server**:
```bash
sudo ls -la /var/lib/mysql/.ssh/
```

Expected output:
```
drwx------  mysql mysql  .ssh/
-rw-------  mysql mysql  authorized_keys
-rw-------  mysql mysql  id_ed25519
-rw-r--r--  mysql mysql  id_ed25519.pub
-rw-r--r--  mysql mysql  known_hosts
```

Verify authorized_keys has **2 lines** on each server:
```bash
sudo wc -l /var/lib/mysql/.ssh/authorized_keys
```
Should return `2`.

---

## Step 8 — Test all SSH connections

**From VM1:**
```bash
sudo -u mysql ssh -T mysql@oel9-vm2 "echo 'VM1 → VM2 OK'"
sudo -u mysql ssh -T mysql@oel9-vm3 "echo 'VM1 → VM3 OK'"
```

**From VM2:**
```bash
sudo -u mysql ssh -T mysql@oel9-vm1 "echo 'VM2 → VM1 OK'"
sudo -u mysql ssh -T mysql@oel9-vm3 "echo 'VM2 → VM3 OK'"
```

**From VM3:**
```bash
sudo -u mysql ssh -T mysql@oel9-vm1 "echo 'VM3 → VM1 OK'"
sudo -u mysql ssh -T mysql@oel9-vm2 "echo 'VM3 → VM2 OK'"
```

All 6 should print the message and exit immediately with no password prompt.

---

## Step 9 — Lock down mysql shell (All 3 Servers)

**On VM1:**
```bash
sudo usermod -s /sbin/nologin mysql
```

**On VM2:**
```bash
sudo usermod -s /sbin/nologin mysql
```

**On VM3:**
```bash
sudo usermod -s /sbin/nologin mysql
```

---

**Important note:** After Step 9, SSH between the servers will still work for non-interactive commands (like MySQL replication uses), but `sudo -u mysql -i` interactive login will be blocked again — which is the correct security posture for a production `mysql` user.
