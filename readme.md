# MySQL Cluster Setup Details

This document contains details of all configured clusters including InnoDB Cluster, Galera Cluster, and NDB Cluster. It includes cluster name, nodes, usernames, and passwords for quick reference.

--------------------------------------------------

## 1. InnoDB Cluster

Cluster Name:
prodCluster

Cluster Type:
MySQL InnoDB Cluster (Group Replication based)

Nodes:

Node 1:
Hostname: oel9-vm1
IP Address: 10.10.100.101
MySQL Port: 3306
GR Port: 33061

Node 2:
Hostname: oel9-vm2
IP Address: 10.10.100.102
MySQL Port: 3306
GR Port: 33061

Node 3:
Hostname: oel9-vm3
IP Address: 10.10.100.103
MySQL Port: 3306
GR Port: 33061

Users:

DBA User:
Username: venkat
Privileges: sudo access

Cluster Admin:
Username: clusteradmin
Password: Cluster@123

Internal Cluster Users:
mysql_innodb_cluster_1
mysql_innodb_cluster_2
mysql_innodb_cluster_3

Router User:
mysql_router1

--------------------------------------------------

## 2. Galera Cluster

Cluster Name:
galera_cluster

Cluster Type:
Percona XtraDB Cluster / MariaDB Galera Cluster

Nodes:

Node 1:
Hostname: oel9-vm1
IP Address: 10.10.100.101

Node 2:
Hostname: oel9-vm2
IP Address: 10.10.100.102

Node 3:
Hostname: oel9-vm3
IP Address: 10.10.100.103

Ports Used:
MySQL Port: 3306
Galera Replication Ports: 4567, 4568, 4444

Users:

DB User:
Username: root
Password: Root@123

Replication User:
Username: repl
Password: Repl@123

--------------------------------------------------

## 3. NDB Cluster

Cluster Name:
ndb_cluster

Cluster Type:
MySQL NDB Cluster

Components:

Management Node:
Hostname: oel9-vm1
IP Address: 10.10.100.101

Data Nodes:
oel9-vm2 (10.10.100.102)
oel9-vm3 (10.10.100.103)

SQL Node:
oel9-vm1

Ports Used:
Management Server: 1186
Data Node: 2202
MySQL Server: 3306

Users:

NDB Admin User:
Username: root
Password: Root@123

--------------------------------------------------

## Common Configuration

Operating System:
Oracle Linux 9

MySQL Version:
8.0.45

Networking:
All nodes configured in /etc/hosts

--------------------------------------------------

## Notes

1. InnoDB Cluster uses Group Replication internally
2. Port 33061 is mandatory for Group Replication
3. Galera uses wsrep protocol for replication
4. NDB Cluster uses separate data and management nodes
5. Ensure firewall ports are open on all nodes
6. Always verify cluster status after setup

--------------------------------------------------

## Useful Commands

Check InnoDB Cluster Nodes:
SELECT * FROM performance_schema.replication_group_members;

Start Group Replication:
START GROUP_REPLICATION;

Check Galera Status:
SHOW STATUS LIKE 'wsrep_cluster_size';

Check NDB Status:
ndb_mgm

--------------------------------------------------

End of Document
