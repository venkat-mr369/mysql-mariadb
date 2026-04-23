### MySQL Clusters Setup Documentation

This repository contains setup and configuration details for three types of MySQL clusters:

* InnoDB Cluster
* Galera Cluster
* NDB Cluster

The document includes node details, ports, users, and essential commands.

---

### InnoDB Cluster

### Overview

MySQL InnoDB Cluster provides high availability using Group Replication.

### Cluster Name

prodCluster

### Nodes

| Node | Hostname | IP Address    | MySQL Port | GR Port |
| ---- | -------- | ------------- | ---------- | ------- |
| 1    | oel9-vm1 | 10.10.100.101 | 3306       | 33061   |
| 2    | oel9-vm2 | 10.10.100.102 | 3306       | 33061   |
| 3    | oel9-vm3 | 10.10.100.103 | 3306       | 33061   |

### Users

| Role           | Username                   | Password         |
| -------------- | -------------------------- | ---------------- |
| Cluster Admin  | clusteradmin               | Cluster@123      |
| Internal Users | mysql_innodb_cluster_1,2,3 | Managed by MySQL |
| Router User    | mysql_router1              | Managed by MySQL |

---

### Galera Cluster

### Overview

Galera Cluster provides synchronous multi-master replication.

### Cluster Name

galera_cluster

### Nodes

| Node | Hostname | IP Address    |
| ---- | -------- | ------------- |
| 1    | oel9-vm1 | 10.10.100.101 |
| 2    | oel9-vm2 | 10.10.100.102 |
| 3    | oel9-vm3 | 10.10.100.103 |

### Ports

| Service            | Port |
| ------------------ | ---- |
| MySQL              | 3306 |
| Galera Replication | 4567 |
| IST                | 4568 |
| SST                | 4444 |

### Users

| Role             | Username | Password |
| ---------------- | -------- | -------- |
| Root User        | root     | Root@123 |
| Replication User | repl     | Repl@123 |

---

### NDB Cluster

### Overview

MySQL NDB Cluster is a distributed database with separate data and management nodes.

### Cluster Name

ndb_cluster

### Components

| Component       | Hostname | IP Address    |
| --------------- | -------- | ------------- |
| Management Node | oel9-vm1 | 10.10.100.101 |
| Data Node 1     | oel9-vm2 | 10.10.100.102 |
| Data Node 2     | oel9-vm3 | 10.10.100.103 |
| SQL Node        | oel9-vm1 | 10.10.100.101 |

### Ports

| Service           | Port |
| ----------------- | ---- |
| Management Server | 1186 |
| Data Node         | 2202 |
| MySQL Server      | 3306 |

### Users

| Role       | Username | Password |
| ---------- | -------- | -------- |
| Admin User | root     | Root@123 |

---

## Environment Details

| Parameter     | Value          |
| ------------- | -------------- |
| OS            | Oracle Linux 9 |
| MySQL Version | 8.0.45         |

---

## Useful Commands

### InnoDB Cluster

Check cluster nodes:

```
SELECT * FROM performance_schema.replication_group_members;
```

Start Group Replication:

```
START GROUP_REPLICATION;
```

---

### Galera Cluster

Check cluster size:

```
SHOW STATUS LIKE 'wsrep_cluster_size';
```

---

### NDB Cluster

Check cluster status:

```
ndb_mgm
```

---

#### Notes

* InnoDB Cluster uses Group Replication internally
* Port 33061 is required for Group Replication
* Ensure all required ports are open
* Verify cluster status after setup

---


