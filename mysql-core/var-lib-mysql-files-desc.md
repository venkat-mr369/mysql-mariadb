Venkata, for interviews, don't just memorize the files. Understand the **MySQL 8 startup and transaction flow** and where these files participate.

## MySQL 8 Datadir Flow

```text id="s4xg7x"
mysqld Starts
      |
      +--> auto.cnf
      |      |
      |      +--> Server UUID
      |
      +--> mysql.ibd
      |      |
      |      +--> Data Dictionary
      |      +--> User Metadata
      |      +--> Schema Metadata
      |
      +--> #innodb_redo
      |      |
      |      +--> Redo Logs
      |
      +--> undo_001 / undo_002
      |      |
      |      +--> MVCC / Rollback
      |
      +--> ibdata1
      |      |
      |      +--> System Tablespace
      |
      +--> mysql.sock
             |
             +--> Local Connections
```

---

# When a Transaction Happens

Example:

```sql
UPDATE emp
SET sal=50000
WHERE emp_id=1001;
```

Flow:

```text id="93tjlwm"
Client
   |
MySQL Server
   |
Buffer Pool
   |
Redo Log (#innodb_redo)
   |
Undo Log (undo_001/002)
   |
Data Page
   |
.ibd File
```

---

## 1. auto.cnf

```text
auto.cnf
```

Purpose:

```text
Server UUID
```

Used by:

* Replication
* Group Replication
* InnoDB Cluster

Check:

```bash
cat auto.cnf
```

---

## 2. mysql.ibd

```text
mysql.ibd
```

Most important MySQL 8 file.

Contains:

```text
Data Dictionary
Users
Privileges
Metadata
```

Interview Point:

```text
.frm files removed in MySQL 8
Metadata moved into mysql.ibd
```

---

## 3. ibdata1

```text
ibdata1
```

System Tablespace.

Contains:

```text
InnoDB internal metadata
Change Buffer
System information
```

---

## 4. undo_001 / undo_002

```text
undo_001
undo_002
```

Used for:

```text
Rollback
MVCC
Consistent Reads
```

Example:

```sql
START TRANSACTION;
UPDATE emp SET sal=60000;
```

Old value stored in Undo.

---

## 5. #innodb_redo

```text
#innodb_redo
```

Contains:

```text
Redo Logs
```

Purpose:

```text
Crash Recovery
Durability
```

Flow:

```text
Transaction
    |
Redo Log
    |
Data File
```

---

## 6. #ib_16384_0.dblwr

```text
#ib_16384_0.dblwr
#ib_16384_1.dblwr
```

Doublewrite Buffer.

Purpose:

```text
Protect against partial page writes
```

Flow:

```text
Page
  |
Doublewrite Buffer
  |
Actual Data File
```

---

## 7. ibtmp1

```text
ibtmp1
```

Temporary Tablespace.

Used for:

```text
Temporary Tables
Sorting
Hash Joins
GROUP BY
ORDER BY
```

---

## 8. binlog.000001

```text
binlog.000001
binlog.000002
binlog.000003
```

Binary Logs.

Contain:

```text
INSERT
UPDATE
DELETE
DDL
```

Used for:

```text
Replication
PITR
CDC
```

---

## 9. binlog.index

```text
binlog.index
```

Tracks:

```text
All Binlog Files
```

Example:

```text
binlog.000001
binlog.000002
binlog.000003
```

---

## 10. mysql.sock

```text
mysql.sock
```

Unix Socket.

Used by:

```bash
mysql -uroot -p
```

Local connections.

---

## 11. public_key.pem

```text
public_key.pem
```

Used by:

```text
caching_sha2_password
```

This is related to the DBeaver issue you solved.

---

## 12. private_key.pem

```text
private_key.pem
```

RSA private key.

Works with:

```text
public_key.pem
```

for secure authentication.

---

## 13. server-cert.pem / server-key.pem

Used for:

```text
SSL/TLS Connections
```

Example:

```text
Client
   |
SSL
   |
MySQL Server
```

---

## 14. performance_schema

```text
performance_schema/
```

Contains performance monitoring data.

Used for:

```sql
SHOW PROCESSLIST;
Performance Analysis
Wait Events
Memory Usage
```

---

## Interview Question

### What happened to .frm files in MySQL 8?

Answer:

> In MySQL 5.7, table definitions were stored in .frm files. In MySQL 8, Oracle introduced a transactional data dictionary, and metadata is stored in InnoDB dictionary tables inside mysql.ibd. Therefore .frm files no longer exist.

### Easy Memory Diagram

```text
Transaction
     |
Redo Log (#innodb_redo)
     |
Undo Log (undo_001/002)
     |
Doublewrite Buffer
     |
.ibd Data File
     |
Binlog
     |
Commit
```

This flow is one of the most useful MySQL 8 DBA interview topics. ✅
