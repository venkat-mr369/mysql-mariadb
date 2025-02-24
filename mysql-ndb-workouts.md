***from SQL Node*** we have to run this comands
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
Now looking into **DATANODE1**, here it will create 
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
Now looking into **DATANODE2**, here it will create 
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


