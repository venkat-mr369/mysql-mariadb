
***from SQL Node (server4)*** we have to run this comands
```bash
[venkat@server4 ~]$ mysql -u root -pMysql@123
mysql: [Warning] Using a password on the command line interface can be insecure.
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 11
Server version: 8.0.41-cluster MySQL Cluster Community Server - GPL

Copyright (c) 2000, 2025, Oracle and/or its affiliates.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.
```
```bash
mysql> show databases;
+--------------------+
| Database           |
+--------------------+
| demo               |
| information_schema |
| mysql              |
| ndbinfo            |
| performance_schema |
| sys                |
+--------------------+
6 rows in set (0.12 sec)
```
```bash
mysql> show engines;
+--------------------+---------+----------------------------------------------------------------+--------------+------+------------+
| Engine             | Support | Comment                                                        | Transactions | XA   | Savepoints |
+--------------------+---------+----------------------------------------------------------------+--------------+------+------------+
| ndbcluster         | YES     | Clustered, fault-tolerant tables                               | YES          | NO   | NO         |
| MEMORY             | YES     | Hash based, stored in memory, useful for temporary tables      | NO           | NO   | NO         |
| InnoDB             | DEFAULT | Supports transactions, row-level locking, and foreign keys     | YES          | YES  | YES        |
| PERFORMANCE_SCHEMA | YES     | Performance Schema                                             | NO           | NO   | NO         |
| MyISAM             | YES     | MyISAM storage engine                                          | NO           | NO   | NO         |
| FEDERATED          | NO      | Federated MySQL storage engine                                 | NULL         | NULL | NULL       |
| ndbinfo            | YES     | MySQL Cluster system information storage engine                | NO           | NO   | NO         |
| MRG_MYISAM         | YES     | Collection of identical MyISAM tables                          | NO           | NO   | NO         |
| BLACKHOLE          | YES     | /dev/null storage engine (anything you write to it disappears) | NO           | NO   | NO         |
| CSV                | YES     | CSV storage engine                                             | NO           | NO   | NO         |
| ARCHIVE            | YES     | Archive storage engine                                         | NO           | NO   | NO         |
+--------------------+---------+----------------------------------------------------------------+--------------+------+------------+
11 rows in set (0.01 sec)
```
```bash
mysql> create database myapp;
Query OK, 1 row affected (0.21 sec)

mysql> use myapp;
Database changed
mysql> create table emp(id int primary key,name varchar(30),city varchar(30)) engine=ndbcluster;
Query OK, 0 rows affected (0.31 sec)

mysql> insert into emp values (1,'venkat','Bangalore');
Query OK, 1 row affected (0.03 sec)

mysql> insert into emp values (2,'vijaya','Hyderabad');
Query OK, 1 row affected (0.00 sec)

mysql> insert into emp values (3,'kishore','Hyderabad');
Query OK, 1 row affected (0.01 sec)

mysql> insert into emp values (4,'hari','Bangalore');
Query OK, 1 row affected (0.00 sec)

mysql> insert into emp values (5,'pratima','Tirupati');
Query OK, 1 row affected (0.01 sec)
```
```bash
mysql> select * from emp;
+----+---------+-----------+
| id | name    | city      |
+----+---------+-----------+
|  3 | kishore | Hyderabad |
|  1 | venkat  | Bangalore |
|  2 | vijaya  | Hyderabad |
|  4 | hari    | Bangalore |
|  5 | pratima | Tirupati  |
+----+---------+-----------+
5 rows in set (0.02 sec)
```
**In Server 4(SQLNode)** No files created 
```bash
[root@server4 ~]# ls -l /var/lib/mysql/myapp
total 0
[root@server4 ~]# cd /var/lib/mysql/myapp
[root@server4 myapp]# ls -l
total 0
[root@server4 myapp]#
```
Now looking into **DATANODE1 (server2)**, here it will create 
```bash
[root@server2 data]# pwd
/var/lib/mysql-cluster/data
[root@server2 data]# ls -lh
total 1.1M
-rw-r--r--  1 root root 1.1K Feb 15 23:44 ndb_2_error.log
drwxr-x--- 11 root root   99 Feb 15 22:39 ndb_2_fs
-rw-r--r--  1 root root 168K Feb 24 22:44 ndb_2_out.log
-rw-r--r--  1 root root    3 Feb 23 09:45 ndb_2.pid
-rw-r--r--  1 root root 938K Feb 15 23:44 ndb_2_trace.log.1
-rw-r--r--  1 root root    1 Feb 15 23:44 ndb_2_trace.log.next
```
```bash
[root@server2 data]# cd ndb_2_fs/
[root@server2 ndb_2_fs]# ls -lh
total 0
drwxr-x--- 5 root root 48 Feb 15 22:39 D1
drwxr-x--- 3 root root 19 Feb 15 22:39 D10
drwxr-x--- 3 root root 19 Feb 15 22:39 D11
drwxr-x--- 5 root root 48 Feb 15 22:39 D2
drwxr-x--- 3 root root 19 Feb 15 22:39 D8
drwxr-x--- 3 root root 19 Feb 15 22:39 D9
drwxr-x--- 8 root root 60 Feb 23 20:34 LCP
drwxr-x--- 2 root root  6 Feb 15 22:37 LG
drwxr-x--- 2 root root  6 Feb 15 22:37 TS
```
Now looking into **DATANODE2 (server3)**, here it will create 
```bash
[venkat@server3 ~]$ sudo -i
[root@server3 ~]# cd /var/lib/mysql-cluster/
[root@server3 mysql-cluster]# pwd
/var/lib/mysql-cluster
[root@server3 mysql-cluster]# cd data
[root@server3 data]# pwd
/var/lib/mysql-cluster/data
[root@server3 data]# ls -lh
total 180K
drwxr-x--- 11 root root   99 Feb 15 22:39 ndb_3_fs
-rw-r--r--  1 root root 174K Feb 24 22:44 ndb_3_out.log
-rw-r--r--  1 root root    3 Feb 23 09:45 ndb_3.pid
[root@server3 data]#
```
```bash
[root@server3 data]# cd ndb_3_fs/
[root@server3 ndb_3_fs]# ls -lrt
total 0
drwxr-x--- 2 root root  6 Feb 15 22:39 TS
drwxr-x--- 2 root root  6 Feb 15 22:39 LG
drwxr-x--- 3 root root 19 Feb 15 22:39 D8
drwxr-x--- 3 root root 19 Feb 15 22:39 D9
drwxr-x--- 3 root root 19 Feb 15 22:39 D11
drwxr-x--- 3 root root 19 Feb 15 22:39 D10
drwxr-x--- 5 root root 48 Feb 15 22:39 D2
drwxr-x--- 5 root root 48 Feb 15 22:39 D1
drwxr-x--- 9 root root 69 Feb 23 20:34 LCP
````
Those directories (D1, D2, D8, D9, D10, D11) you're seeing within your NDB data directory are related to the storage and organization of data within the NDB cluster.  Think of them like folders where NDB keeps different parts of your database.  Here's a simplified explanation:

*   **Data Storage:** NDB distributes data across multiple data nodes for redundancy and performance.  Each of those `D` numbered directories likely represents a *fragment* or *partition* of your overall database.  The numbers probably correspond to different partitions or divisions of the data.  NDB breaks down your tables and indexes and spreads them across these directories.

*   **Fragmentation/Partitioning:**  Large tables are often split into smaller pieces (fragments or partitions) to make them easier to manage and query.  This is a common database technique.  Each `D` directory likely holds a different part of your tables.  So, some data from one table might be in D1, while other data from the same table might be in D2, and so on.

*   **Node Affinity (Potentially):**  While not always the case, the `D` directories might have some relationship to the specific data nodes in your cluster. For example, D1 and D2 might primarily be associated with data node 1, while D8, D9, D10, and D11 might be related to data node 2.  However, NDB can move data around for load balancing, so this isn't a strict 1-to-1 mapping.

*   **Internal NDB Structure:** These directories are part of NDB's *internal* organization.  You, as a user, don't usually need to directly interact with them.  NDB manages the data distribution and retrieval behind the scenes.  You work with the database tables as a whole, and NDB takes care of figuring out which `D` directory the data is in.

*   **LCP (Likely Log/Checkpoint Files):**  The `LCP` directory probably contains log files or checkpoint files. These are important for recovery. Logs record changes to the database, and checkpoints are snapshots of the data at a specific point in time.  If a data node fails, NDB uses the logs and checkpoints to restore the data.

*   **LG and TS (Likely Log Groups and Transaction System Data):**  `LG` probably refers to Log Groups (related to transaction logs), and `TS` likely refers to Transaction System data.  These contain metadata and information about transactions, which are essential for ensuring data consistency and integrity.

**In Simple Terms:**

Imagine you have a large library (your database).  NDB splits the books (data) into different sections (the `D` directories) and puts them in different rooms (data nodes) for better organization and to make it faster to find the book you need.  The `LCP`, `LG`, and `TS` directories are like the library's catalog, records of changes, and other important administrative files.

**Important:** You generally should *not* manually move, delete, or modify anything within these directories unless you absolutely know what you're doing.  Doing so can corrupt your database.  NDB manages these directories automatically.


