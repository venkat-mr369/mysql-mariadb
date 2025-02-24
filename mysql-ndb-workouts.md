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



