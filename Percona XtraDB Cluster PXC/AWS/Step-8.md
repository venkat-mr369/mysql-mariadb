Based on everything we've completed so far:

✅ Terraform infrastructure built
✅ Subnets fixed (PXC nodes distributed across AZs)
✅ 25GB EBS attached and mounted at `/data/mysql`
✅ Ansible control node configured on ProxySQL1 (`10.10.10.206`)
✅ Inventory updated with Python 3.9
✅ Ansible connectivity verified
✅ `/data/mysql` verified on all nodes

The next step should be **installation of Percona XtraDB Cluster 8.4 packages only**, not cluster bootstrap yet.

---

### Step-8 : Install Percona XtraDB Cluster 8.4 on All Nodes

### Step-8.1 Verify Target Nodes

```bash
ansible pxc -m ping
```

Expected:

```text
10.10.1.72 | SUCCESS
10.10.2.45 | SUCCESS
10.10.3.93 | SUCCESS
```

---

### Step-8.2 Verify Amazon Linux Version

```bash
ansible pxc -m shell -a "cat /etc/os-release"
```

Expected:

```text
NAME="Amazon Linux"
VERSION="2023"
```

---

### Step-8.3 Create PXC Install Role

```bash
cd ~/ansible-pxc

mkdir -p roles/pxc_install/tasks
vi roles/pxc_install/tasks/main.yml
```

---

### Step-8.4 Create PXC Installation Playbook

File:

```bash
vi roles/pxc_install/tasks/main.yml
```

Content:

```yaml
---
- name: Update packages
  dnf:
    name: "*"
    state: latest

- name: Install Percona repository
  dnf:
    name: https://repo.percona.com/yum/percona-release-latest.noarch.rpm
    state: present
    disable_gpg_check: true

- name: Enable Percona PXC 8.4 repository
  shell: |
    percona-release setup pxc-84
  args:
    creates: /etc/yum.repos.d/percona-pxc-84-release.repo

- name: Install Percona XtraDB Cluster Server
  dnf:
    name:
      - percona-xtradb-cluster
      - percona-xtradb-cluster-client
      - percona-xtrabackup-84
      - socat
    state: present

- name: Stop mysql service
  systemd:
    name: mysql
    state: stopped
    enabled: true
```

---

### Step-8.5 Create Installation Playbook

```bash
vi install-pxc.yml
```

Content:

```yaml
---
- hosts: pxc
  become: yes

  roles:
    - pxc_install
```

---

### Step-8.6 Execute Installation

```bash
ansible-playbook install-pxc.yml
```

Expected:

```text
PLAY RECAP

10.10.1.72 : ok=
10.10.2.45 : ok=
10.10.3.93 : ok=

failed=0
```

---

### Step-8.7 Verify Installed Version

```bash
ansible pxc -m shell -a "mysqld --version"
```

Expected:

```text
/usr/sbin/mysqld  Ver 8.4.x
Percona XtraDB Cluster
```

---

### Step-8.8 Verify Service Status

```bash
ansible pxc -m shell -a "systemctl status mysql --no-pager"
```

Expected:

```text
Loaded: loaded
Active: inactive (dead)
```

This is expected because cluster configuration has not yet been done.

---

### Step-8.9 Verify Data Directory

```bash
ansible pxc -m shell -a "ls -ld /var/lib/mysql"
```

Expected:

```text
drwx------
mysql mysql
```

At this stage MySQL is still using the default datadir.

---

### Step-8.10 Step-8 Validation

```text
PXC Version
-----------
Percona XtraDB Cluster 8.4

Nodes
-----
10.10.1.72
10.10.2.45
10.10.3.93

Status
------
Packages Installed
MySQL Service Installed
XtraBackup Installed
Repository Enabled
Ready For Cluster Configuration

Next Step
---------
Step-9 : Configure PXC 8.4 Cluster
(wsrep.cnf, datadir=/data/mysql, SST user, bootstrap node)
```

**Important:** Before proceeding to Step-9, run the installation and share the output of:

```bash
ansible-playbook install-pxc.yml
ansible pxc -m shell -a "mysqld --version"
```

Because Percona PXC 8.4 repositories occasionally change package names, I want to verify the exact package names returned in your environment before creating Step-9.
