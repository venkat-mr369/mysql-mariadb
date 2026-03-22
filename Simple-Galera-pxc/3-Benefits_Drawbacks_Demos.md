# PXC / Galera — Benefits & Drawbacks Deep Dive with Demos

---

## PART 1: BENEFITS (Why Use Galera?)

---

### BENEFIT 1: True Multi-Master — Write on ANY Node

Unlike InnoDB Cluster (single primary), Galera allows writes on ALL nodes simultaneously.

**Demo — Write from different nodes and see instant replication:**

```sql
-- ON NODE1:
CREATE DATABASE demo_galera;
USE demo_galera;

CREATE TABLE employees (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100),
    department VARCHAR(50),
    salary DECIMAL(10,2),
    created_by VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO employees (name, department, salary, created_by)
VALUES ('Ravi Kumar', 'Engineering', 85000.00, 'node1');
```

```sql
-- ON NODE2 (immediately, no delay):
USE demo_galera;
SELECT * FROM employees;
-- You will see Ravi Kumar's row instantly!

INSERT INTO employees (name, department, salary, created_by)
VALUES ('Priya Sharma', 'Marketing', 72000.00, 'node2');
```

```sql
-- ON NODE3:
USE demo_galera;
SELECT * FROM employees;
-- You will see BOTH rows from Node1 and Node2!

INSERT INTO employees (name, department, salary, created_by)
VALUES ('Amit Patel', 'Finance', 90000.00, 'node3');
```

```sql
-- ON ANY NODE — verify all 3 rows:
SELECT * FROM employees ORDER BY id;
-- +----+--------------+-------------+----------+------------+---------------------+
-- | id | name         | department  | salary   | created_by | created_at          |
-- +----+--------------+-------------+----------+------------+---------------------+
-- |  1 | Ravi Kumar   | Engineering | 85000.00 | node1      | 2026-03-22 01:00:00 |
-- |  4 | Priya Sharma | Marketing   | 72000.00 | node2      | 2026-03-22 01:00:05 |
-- |  7 | Amit Patel   | Finance     | 90000.00 | node3      | 2026-03-22 01:00:10 |
-- +----+--------------+-------------+----------+------------+---------------------+
```

**Notice the ID gaps (1, 4, 7)?** That's `innodb_autoinc_lock_mode=2` — each node gets its own auto-increment range to avoid conflicts. This is expected behavior, not a bug.

---

### BENEFIT 2: Synchronous Replication — No Data Loss

In async replication, if master crashes before slave gets the data, data is LOST.
Galera guarantees: if COMMIT succeeds, ALL nodes have the data.

**Demo — Prove synchronous behavior:**

```sql
-- ON NODE1:
USE demo_galera;
INSERT INTO employees (name, department, salary, created_by)
VALUES ('Sync Test', 'QA', 65000.00, 'node1');

-- Check the commit sequence number
SHOW STATUS LIKE 'wsrep_last_committed';
-- Note the number, e.g., 15
```

```sql
-- ON NODE2 (immediately):
SHOW STATUS LIKE 'wsrep_last_committed';
-- Same number (15) — proves synchronous!

SELECT * FROM employees WHERE name = 'Sync Test';
-- Row is already here — no replication lag
```

**Compare with async replication:**

```sql
-- Check replication lag (Galera should always be near 0)
SHOW STATUS LIKE 'wsrep_local_recv_queue_avg';
-- Should be < 0.1 — this is "replication lag" in Galera terms

-- In async replication, Seconds_Behind_Master can be minutes/hours
-- In Galera, this is always near-zero
```

---

### BENEFIT 3: Automatic Failover — No Manual Intervention

If a node crashes, the cluster continues automatically. No need for MHA, Orchestrator, or MySQL Router.

**Demo — Simulate node failure:**

```sql
-- ON NODE1 — check cluster size before:
SHOW STATUS LIKE 'wsrep_cluster_size';
-- Shows: 3
```

```bash
# Kill Node3 suddenly (simulate crash):
# ON NODE3:
sudo systemctl stop mysqld
```

```sql
-- ON NODE1 — within seconds:
SHOW STATUS LIKE 'wsrep_cluster_size';
-- Shows: 2 (automatically detected)

SHOW STATUS LIKE 'wsrep_cluster_status';
-- Shows: Primary (still has quorum with 2/3 nodes)

-- Writes continue working on Node1 and Node2:
INSERT INTO employees (name, department, salary, created_by)
VALUES ('Still Working', 'Ops', 70000.00, 'node1');
-- SUCCESS — no downtime!
```

```bash
# Bring Node3 back:
# ON NODE3:
sudo systemctl start mysqld
```

```sql
-- ON NODE3 (after rejoin):
SHOW STATUS LIKE 'wsrep_cluster_size';
-- Shows: 3 (automatically rejoined)

SELECT * FROM employees WHERE name = 'Still Working';
-- Row is here — automatically caught up via IST!
```

---

### BENEFIT 4: No Router/Proxy Required

InnoDB Cluster needs MySQL Router to direct traffic. Galera doesn't — connect to ANY node directly.

```sql
-- All 3 connections work for both reads AND writes:
-- mysql -uroot -p -h 10.0.1.2   (Node1 — read/write)
-- mysql -uroot -p -h 10.0.2.2   (Node2 — read/write)
-- mysql -uroot -p -h 10.0.3.2   (Node3 — read/write)

-- No special routing needed
-- Your application can round-robin across all 3 nodes
```

---

### BENEFIT 5: Data Consistency Guaranteed

Every transaction is certified across all nodes before commit. No stale reads.

**Demo — Prove consistency:**

```sql
-- ON NODE1:
USE demo_galera;
UPDATE employees SET salary = 100000.00 WHERE name = 'Ravi Kumar';
```

```sql
-- ON NODE2 (immediately):
SELECT salary FROM employees WHERE name = 'Ravi Kumar';
-- Shows: 100000.00 — NOT the old value
-- In async replication, you might read stale data here
```

```sql
-- Verify with wsrep_sync_wait for guaranteed causal reads:
SET SESSION wsrep_sync_wait = 1;
SELECT * FROM employees WHERE name = 'Ravi Kumar';
-- Guaranteed to return the latest committed value
```

---

### BENEFIT 6: Automatic New Node Provisioning (SST/IST)

New nodes get data automatically — no manual backup/restore.

```sql
-- After adding a new node and starting mysqld:
-- It automatically gets ALL data via SST (xtrabackup)
-- Check SST progress:
SHOW STATUS LIKE 'wsrep_local_state_comment';
-- "Joiner" → "Joined" → "Synced" (fully caught up)
```

---

## PART 2: DRAWBACKS (The Real Problems)

---

### DRAWBACK 1: Certification Conflicts — Writes Can Be REJECTED

This is Galera's BIGGEST drawback. If two nodes update the SAME row simultaneously, ONE transaction gets REJECTED after commit. Your application gets a deadlock error.

**Demo — Force a certification conflict:**

```sql
-- SETUP:
-- ON NODE1:
USE demo_galera;
CREATE TABLE conflict_test (
    id INT PRIMARY KEY,
    counter INT,
    updated_by VARCHAR(20)
);
INSERT INTO conflict_test VALUES (1, 0, 'init');
```

Now run these SIMULTANEOUSLY on Node1 and Node2 (open two terminals):

```sql
-- ON NODE1 (Terminal 1) — run this:
USE demo_galera;
BEGIN;
UPDATE conflict_test SET counter = counter + 1, updated_by = 'node1' WHERE id = 1;
-- Don't commit yet... wait for Node2 to also run their UPDATE
COMMIT;
```

```sql
-- ON NODE2 (Terminal 2) — run at the SAME TIME:
USE demo_galera;
BEGIN;
UPDATE conflict_test SET counter = counter + 1, updated_by = 'node2' WHERE id = 1;
COMMIT;
```

**Result: ONE of them will get this error:**

```
ERROR 1213 (40001): Deadlock found when trying to get lock;
try restarting transaction
```

**This is NOT a real deadlock — it's a certification failure.**
The other node's transaction "won" certification, and yours was rolled back.

**Check certification failures:**

```sql
SHOW STATUS LIKE 'wsrep_local_cert_failures';
-- This number increases with every conflict

SHOW STATUS LIKE 'wsrep_local_bf_aborts';
-- Brute-force aborts — transactions killed by certification
```

**Why this matters:**
Your application MUST handle retry logic for deadlock errors. This is extra code that async replication doesn't need.

---

### DRAWBACK 2: ALL Nodes Are Only As Fast As the SLOWEST Node

Flow control pauses the ENTIRE cluster when any node falls behind.

**Demo — See flow control in action:**

```sql
-- Check flow control status:
SHOW STATUS LIKE 'wsrep_flow_control_paused';
-- 0.0 = good, 0.5 = cluster paused 50% of time, 1.0 = fully paused

SHOW STATUS LIKE 'wsrep_flow_control_sent';
-- Number of times THIS node triggered flow control (asked others to slow down)

SHOW STATUS LIKE 'wsrep_flow_control_recv';
-- Number of times THIS node received flow control (was told to slow down)

-- Check receive queue (how far behind this node is):
SHOW STATUS LIKE 'wsrep_local_recv_queue_avg';
SHOW STATUS LIKE 'wsrep_local_recv_queue_max';
```

**Demo — Create a slow node scenario:**

```sql
-- ON NODE1 — Create a large table:
USE demo_galera;
CREATE TABLE large_test (
    id INT AUTO_INCREMENT PRIMARY KEY,
    data VARCHAR(255),
    padding CHAR(200) DEFAULT 'x'
);

-- Insert lots of data quickly:
DELIMITER //
CREATE PROCEDURE insert_bulk(IN num_rows INT)
BEGIN
    DECLARE i INT DEFAULT 0;
    WHILE i < num_rows DO
        INSERT INTO large_test (data) VALUES (CONCAT('Row ', i));
        SET i = i + 1;
    END WHILE;
END //
DELIMITER ;

CALL insert_bulk(10000);
```

```sql
-- ON NODE2 — While Node1 is inserting, check flow control:
SHOW STATUS LIKE 'wsrep_flow_control_paused';
-- If this goes above 0, it means Node2 is slowing down the cluster

SHOW STATUS LIKE 'wsrep_local_recv_queue_avg';
-- If > 1.0, Node2 is falling behind
```

---

### DRAWBACK 3: AUTO_INCREMENT Gaps

With `innodb_autoinc_lock_mode=2`, each node reserves ID ranges to avoid conflicts. This creates gaps.

**Demo — See the gaps:**

```sql
-- ON NODE1:
USE demo_galera;
CREATE TABLE id_gap_test (
    id INT AUTO_INCREMENT PRIMARY KEY,
    source VARCHAR(20)
);

INSERT INTO id_gap_test (source) VALUES ('node1');  -- id = 1
INSERT INTO id_gap_test (source) VALUES ('node1');  -- id = 4
INSERT INTO id_gap_test (source) VALUES ('node1');  -- id = 7
```

```sql
-- ON NODE2:
INSERT INTO id_gap_test (source) VALUES ('node2');  -- id = 2
INSERT INTO id_gap_test (source) VALUES ('node2');  -- id = 5
```

```sql
-- ON ANY NODE:
SELECT * FROM id_gap_test ORDER BY id;
-- +----+--------+
-- | id | source |
-- +----+--------+
-- |  1 | node1  |
-- |  2 | node2  |
-- |  4 | node1  |
-- |  5 | node2  |
-- |  7 | node1  |
-- +----+--------+
-- Gaps: 3, 6 are missing — this is NORMAL in Galera
```

**Check auto-increment settings:**

```sql
SHOW VARIABLES LIKE 'auto_increment_increment';
-- Shows: 3 (number of nodes)

SHOW VARIABLES LIKE 'auto_increment_offset';
-- Shows: 1, 2, or 3 (different per node)

-- Node1: generates 1, 4, 7, 10, 13...
-- Node2: generates 2, 5, 8, 11, 14...
-- Node3: generates 3, 6, 9, 12, 15...
```

**Impact:** If your application assumes sequential IDs (id 1, 2, 3, 4...), it will break. Use UUIDs or don't rely on sequential auto-increment.

---

### DRAWBACK 4: DDL (ALTER TABLE) Blocks ENTIRE Cluster

Schema changes in Galera use Total Order Isolation (TOI) — the ALTER runs on ALL nodes simultaneously and blocks ALL writes during execution.

**Demo — See DDL blocking:**

```sql
-- ON NODE1:
USE demo_galera;

-- Check current DDL method:
SHOW VARIABLES LIKE 'wsrep_OSU_method';
-- Shows: TOI (Total Order Isolation) — default

-- This ALTER will block ALL nodes until it completes on ALL nodes:
ALTER TABLE large_test ADD COLUMN new_col VARCHAR(50) DEFAULT NULL;
```

```sql
-- ON NODE2 (while ALTER is running on Node1):
-- Try to insert — it will WAIT until ALTER finishes on ALL nodes:
INSERT INTO large_test (data) VALUES ('during alter');
-- This hangs until the ALTER completes!
```

**Check DDL progress:**

```sql
SHOW STATUS LIKE 'wsrep_local_state_comment';
-- During DDL: might show "Donor/Desynced" or similar
```

**Workaround — use RSU (Rolling Schema Upgrade) for non-blocking DDL:**

```sql
-- ON EACH NODE (one at a time):
SET wsrep_OSU_method = RSU;
ALTER TABLE large_test ADD COLUMN another_col INT;
SET wsrep_OSU_method = TOI;
-- Then repeat on next node
-- WARNING: RSU only works for backward-compatible changes!
```

---

### DRAWBACK 5: InnoDB ONLY — No Other Storage Engines

Galera ONLY supports InnoDB. MyISAM, MEMORY, and other engines don't replicate.

**Demo — MyISAM doesn't replicate:**

```sql
-- ON NODE1:
USE demo_galera;

-- This will FAIL with pxc_strict_mode=ENFORCING:
CREATE TABLE myisam_test (id INT) ENGINE=MyISAM;
-- ERROR 3098: The table does not comply with the requirements by PXC
```

```sql
-- Check strict mode:
SHOW VARIABLES LIKE 'pxc_strict_mode';
-- ENFORCING = blocks non-InnoDB tables

-- Even if you set it to PERMISSIVE:
-- SET GLOBAL pxc_strict_mode = PERMISSIVE;
-- CREATE TABLE myisam_test (id INT) ENGINE=MyISAM;
-- The table would be created but NOT replicated to other nodes!
```

---

### DRAWBACK 6: Large Transactions Are Expensive

Every write-set must be sent to ALL nodes for certification. Large transactions = large write-sets = slow.

**Demo — Large transaction performance:**

```sql
-- ON NODE1:
USE demo_galera;
CREATE TABLE large_txn_test (
    id INT AUTO_INCREMENT PRIMARY KEY,
    data VARCHAR(255)
);

-- Small transaction (fast):
SET @start = NOW(6);
INSERT INTO large_txn_test (data) VALUES ('small');
SELECT TIMESTAMPDIFF(MICROSECOND, @start, NOW(6)) AS microseconds;
-- Very fast

-- Large transaction (slow — must certify entire write-set):
SET @start = NOW(6);
BEGIN;
INSERT INTO large_txn_test (data)
SELECT CONCAT('bulk_', seq) FROM (
    SELECT @rownum := @rownum + 1 AS seq
    FROM information_schema.columns a,
         information_schema.columns b,
         (SELECT @rownum := 0) r
    LIMIT 50000
) t;
COMMIT;
SELECT TIMESTAMPDIFF(MICROSECOND, @start, NOW(6)) AS microseconds;
-- Much slower — entire 50K rows sent as one write-set to all nodes
```

```sql
-- Check write-set size:
SHOW STATUS LIKE 'wsrep_replicated_bytes';
-- Total bytes replicated — large after big transactions

-- Max allowed write-set:
SHOW VARIABLES LIKE 'wsrep_max_ws_size';
-- Default: 2GB — transactions bigger than this will be rejected
```

---

### DRAWBACK 7: Network Dependency — Cluster Needs Low Latency

Galera sends every write to all nodes. High latency = slow commits.

**Demo — Check network impact:**

```sql
-- Check replication latency:
SHOW STATUS LIKE 'wsrep_commit_oooe';     -- Out-of-order events (commit)
SHOW STATUS LIKE 'wsrep_commit_oool';     -- Out-of-order events (local)
SHOW STATUS LIKE 'wsrep_apply_oooe';      -- Out-of-order apply events

-- Check if network is causing issues:
SHOW STATUS LIKE 'wsrep_local_send_queue_avg';
-- > 1.0 means network can't keep up with writes
```

**Real-world impact:**

| Network Latency | Effect |
|----------------|--------|
| < 1ms (same datacenter) | Excellent — barely noticeable |
| 1-5ms (same region) | Good — slight commit overhead |
| 10-50ms (cross-region) | Bad — every COMMIT takes 10-50ms extra |
| 100ms+ (cross-continent) | Terrible — unusable for write-heavy workloads |

---

### DRAWBACK 8: LOCK TABLES and FTWRL Don't Work as Expected

```sql
-- These are restricted in Galera:
-- LOCK TABLES — only works locally, other nodes ignore it
-- FLUSH TABLES WITH READ LOCK — restricted in strict mode

-- Demo:
USE demo_galera;

-- ON NODE1:
LOCK TABLES employees WRITE;
-- This only locks on Node1!

-- ON NODE2:
INSERT INTO employees (name, department, salary, created_by)
VALUES ('Lock Test', 'Test', 50000, 'node2');
-- This SUCCEEDS — LOCK TABLES doesn't replicate!
```

```sql
-- ON NODE1:
UNLOCK TABLES;

-- Check what's restricted:
SHOW VARIABLES LIKE 'pxc_strict_mode';
-- ENFORCING blocks many unsafe operations
```

---

### DRAWBACK 9: Minimum 3 Nodes Required

2-node clusters have no quorum protection. If 1 node dies, the other can't tell if it's a split-brain or real failure.

```sql
-- Check quorum math:
SHOW STATUS LIKE 'wsrep_cluster_size';
SHOW STATUS LIKE 'wsrep_cluster_weight';

-- 3 nodes: need 2 for quorum (can lose 1)
-- 5 nodes: need 3 for quorum (can lose 2)
-- 2 nodes: need 2 for quorum (can lose 0!) — DANGEROUS
```

---

### DRAWBACK 10: XA Transactions Not Supported

```sql
-- These will FAIL:
XA START 'test1';
-- ERROR: XA transactions are not supported in Galera
```

---

## PART 3: BENEFITS vs DRAWBACKS SUMMARY

| # | Benefit | Drawback |
|---|---------|----------|
| 1 | Write on ANY node | Certification conflicts — writes can be REJECTED |
| 2 | Synchronous — zero data loss | Slowest node slows ENTIRE cluster (flow control) |
| 3 | Automatic failover | AUTO_INCREMENT gaps |
| 4 | No router/proxy needed | DDL (ALTER TABLE) blocks entire cluster |
| 5 | Strong consistency | InnoDB only — no other engines |
| 6 | Auto provisioning (SST/IST) | Large transactions are expensive |
| 7 | Simple setup | Network latency directly affects performance |
| 8 | Multi-datacenter capable | LOCK TABLES doesn't work across nodes |
| 9 | No single point of failure | Minimum 3 nodes required |
| 10 | Battle-tested (Percona) | XA transactions not supported |

---

## PART 4: FULL DIAGNOSTIC QUERY — Run Anytime

```sql
-- Copy-paste this entire block for a complete cluster health snapshot:

SELECT '=== CLUSTER IDENTITY ===' AS section;
SHOW STATUS LIKE 'wsrep_cluster_state_uuid';
SHOW STATUS LIKE 'wsrep_cluster_conf_id';
SHOW STATUS LIKE 'wsrep_cluster_size';
SHOW STATUS LIKE 'wsrep_cluster_status';

SELECT '=== NODE STATUS ===' AS section;
SHOW STATUS LIKE 'wsrep_local_state_comment';
SHOW STATUS LIKE 'wsrep_ready';
SHOW STATUS LIKE 'wsrep_connected';
SHOW STATUS LIKE 'wsrep_incoming_addresses';

SELECT '=== REPLICATION HEALTH ===' AS section;
SHOW STATUS LIKE 'wsrep_last_committed';
SHOW STATUS LIKE 'wsrep_replicated';
SHOW STATUS LIKE 'wsrep_replicated_bytes';
SHOW STATUS LIKE 'wsrep_received';
SHOW STATUS LIKE 'wsrep_received_bytes';

SELECT '=== PERFORMANCE ===' AS section;
SHOW STATUS LIKE 'wsrep_flow_control_paused';
SHOW STATUS LIKE 'wsrep_flow_control_sent';
SHOW STATUS LIKE 'wsrep_flow_control_recv';
SHOW STATUS LIKE 'wsrep_local_recv_queue_avg';
SHOW STATUS LIKE 'wsrep_local_send_queue_avg';

SELECT '=== CONFLICTS ===' AS section;
SHOW STATUS LIKE 'wsrep_local_cert_failures';
SHOW STATUS LIKE 'wsrep_local_bf_aborts';

SELECT '=== IST/SST ===' AS section;
SHOW STATUS LIKE 'wsrep_local_state';
SHOW STATUS LIKE 'wsrep_desync_count';
```

---

## PART 5: WHEN TO USE GALERA vs WHEN NOT TO

### USE Galera When:

- You need high availability with automatic failover
- You need zero data loss (RPO = 0)
- All nodes are in the SAME datacenter or low-latency network
- Your workload is mostly reads with moderate writes
- You want simple setup without external tools (no Router, Orchestrator)
- You can handle retry logic in your application for certification conflicts

### DON'T USE Galera When:

- High write throughput on the SAME rows from multiple nodes
- Cross-continent/high-latency deployments with heavy writes
- You rely on MyISAM, MEMORY, or other non-InnoDB engines
- You need XA transactions
- Your application can't handle deadlock retries
- You do frequent large DDL operations on big tables
- You use LOCK TABLES extensively in your application
