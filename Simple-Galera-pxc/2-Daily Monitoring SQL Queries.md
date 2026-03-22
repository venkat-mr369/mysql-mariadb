### PXC 8.0 — Daily Monitoring SQL Queries

---

## 1. FULL CLUSTER HEALTH (Run First Every Day)

```sql
SELECT
  CASE Variable_name
    WHEN 'wsrep_cluster_size'           THEN '01. Cluster Size'
    WHEN 'wsrep_cluster_status'         THEN '02. Cluster Status'
    WHEN 'wsrep_local_state_comment'    THEN '03. Node State'
    WHEN 'wsrep_ready'                  THEN '04. Ready for Queries'
    WHEN 'wsrep_connected'              THEN '05. Connected'
    WHEN 'wsrep_incoming_addresses'     THEN '06. All Node IPs'
    WHEN 'wsrep_flow_control_paused'    THEN '07. Flow Control Paused'
    WHEN 'wsrep_local_recv_queue_avg'   THEN '08. Recv Queue Avg'
    WHEN 'wsrep_local_send_queue_avg'   THEN '09. Send Queue Avg'
    WHEN 'wsrep_local_cert_failures'    THEN '10. Cert Failures'
    WHEN 'wsrep_local_bf_aborts'        THEN '11. BF Aborts'
    WHEN 'wsrep_last_committed'         THEN '12. Last Committed Seq'
    WHEN 'wsrep_replicated'             THEN '13. Write-Sets Sent'
    WHEN 'wsrep_received'               THEN '14. Write-Sets Received'
    WHEN 'wsrep_desync_count'           THEN '15. Desync Count'
    ELSE Variable_name
  END AS 'Check',
  Variable_value AS 'Value',
  CASE Variable_name
    WHEN 'wsrep_cluster_size'           THEN IF(Variable_value='3', 'OK', 'NODE DOWN!')
    WHEN 'wsrep_cluster_status'         THEN IF(Variable_value='Primary', 'OK', 'SPLIT BRAIN!')
    WHEN 'wsrep_local_state_comment'    THEN IF(Variable_value='Synced', 'OK', 'NOT SYNCED!')
    WHEN 'wsrep_ready'                  THEN IF(Variable_value='ON', 'OK', 'NOT READY!')
    WHEN 'wsrep_connected'              THEN IF(Variable_value='ON', 'OK', 'DISCONNECTED!')
    WHEN 'wsrep_flow_control_paused'    THEN IF(Variable_value+0 < 0.1, 'OK', 'SLOW NODE!')
    WHEN 'wsrep_local_recv_queue_avg'   THEN IF(Variable_value+0 < 5.0, 'OK', 'FALLING BEHIND!')
    WHEN 'wsrep_local_send_queue_avg'   THEN IF(Variable_value+0 < 5.0, 'OK', 'NETWORK SLOW!')
    WHEN 'wsrep_local_cert_failures'    THEN IF(Variable_value+0 < 10, 'OK', 'CONFLICTS!')
    WHEN 'wsrep_local_bf_aborts'        THEN IF(Variable_value+0 < 10, 'OK', 'ABORTS HIGH!')
    WHEN 'wsrep_desync_count'           THEN IF(Variable_value='0', 'OK', 'DESYNCED!')
    ELSE 'INFO'
  END AS 'Status'
FROM performance_schema.global_status
WHERE Variable_name IN (
  'wsrep_cluster_size','wsrep_cluster_status','wsrep_local_state_comment',
  'wsrep_ready','wsrep_connected','wsrep_incoming_addresses',
  'wsrep_flow_control_paused','wsrep_local_recv_queue_avg',
  'wsrep_local_send_queue_avg','wsrep_local_cert_failures',
  'wsrep_local_bf_aborts','wsrep_last_committed','wsrep_replicated',
  'wsrep_received','wsrep_desync_count'
)
ORDER BY FIELD(Variable_name,
  'wsrep_cluster_size','wsrep_cluster_status','wsrep_local_state_comment',
  'wsrep_ready','wsrep_connected','wsrep_incoming_addresses',
  'wsrep_flow_control_paused','wsrep_local_recv_queue_avg',
  'wsrep_local_send_queue_avg','wsrep_local_cert_failures',
  'wsrep_local_bf_aborts','wsrep_last_committed','wsrep_replicated',
  'wsrep_received','wsrep_desync_count'
);
```

---

## 2. DATABASE SIZES

```sql
SELECT
  table_schema AS 'Database',
  COUNT(*) AS 'Tables',
  ROUND(SUM(data_length) / 1024 / 1024, 2) AS 'Data (MB)',
  ROUND(SUM(index_length) / 1024 / 1024, 2) AS 'Index (MB)',
  ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'Total (MB)',
  ROUND(SUM(data_free) / 1024 / 1024, 2) AS 'Fragmented (MB)'
FROM information_schema.tables
WHERE table_schema NOT IN ('mysql','information_schema','performance_schema','sys')
GROUP BY table_schema
ORDER BY SUM(data_length + index_length) DESC;
```

---

## 3. TOP 20 LARGEST TABLES

```sql
SELECT
  table_schema AS 'Database',
  table_name AS 'Table',
  table_rows AS 'Rows (approx)',
  ROUND(data_length / 1024 / 1024, 2) AS 'Data (MB)',
  ROUND(index_length / 1024 / 1024, 2) AS 'Index (MB)',
  ROUND((data_length + index_length) / 1024 / 1024, 2) AS 'Total (MB)',
  ROUND(data_free / 1024 / 1024, 2) AS 'Fragmented (MB)',
  engine AS 'Engine'
FROM information_schema.tables
WHERE table_schema NOT IN ('mysql','information_schema','performance_schema','sys')
  AND table_type = 'BASE TABLE'
ORDER BY (data_length + index_length) DESC
LIMIT 20;
```

---

## 4. TABLES NEEDING OPTIMIZATION (Fragmented)

```sql
SELECT
  table_schema AS 'Database',
  table_name AS 'Table',
  table_rows AS 'Rows',
  ROUND(data_length / 1024 / 1024, 2) AS 'Data (MB)',
  ROUND(data_free / 1024 / 1024, 2) AS 'Fragmented (MB)',
  ROUND((data_free / (data_length + 1)) * 100, 1) AS 'Frag %'
FROM information_schema.tables
WHERE table_schema NOT IN ('mysql','information_schema','performance_schema','sys')
  AND data_free > 10485760
ORDER BY data_free DESC;

-- To fix fragmentation (WARNING: blocks writes in Galera/TOI mode):
-- ALTER TABLE database_name.table_name ENGINE=InnoDB;
```

---

## 5. ACTIVE CONNECTIONS & THREADS

```sql
-- Current connection summary
SELECT
  user AS 'User',
  SUBSTRING_INDEX(host, ':', 1) AS 'Host',
  db AS 'Database',
  command AS 'Command',
  time AS 'Seconds',
  state AS 'State',
  LEFT(info, 80) AS 'Query (first 80 chars)'
FROM information_schema.processlist
WHERE command != 'Sleep'
  AND user NOT IN ('system user', 'event_scheduler')
ORDER BY time DESC;
```

```sql
-- Connection counts by host
SELECT
  SUBSTRING_INDEX(host, ':', 1) AS 'Client IP',
  user AS 'User',
  COUNT(*) AS 'Connections',
  SUM(IF(command = 'Sleep', 1, 0)) AS 'Sleeping',
  SUM(IF(command != 'Sleep', 1, 0)) AS 'Active'
FROM information_schema.processlist
GROUP BY SUBSTRING_INDEX(host, ':', 1), user
ORDER BY COUNT(*) DESC;
```

```sql
-- Thread summary
SELECT
  Variable_name AS 'Metric',
  Variable_value AS 'Value'
FROM performance_schema.global_status
WHERE Variable_name IN (
  'Threads_connected',
  'Threads_running',
  'Threads_cached',
  'Threads_created',
  'Max_used_connections',
  'Connections',
  'Aborted_connects',
  'Aborted_clients'
)
ORDER BY FIELD(Variable_name,
  'Threads_connected','Threads_running','Threads_cached',
  'Threads_created','Max_used_connections','Connections',
  'Aborted_connects','Aborted_clients'
);
```

---

## 6. SLOW QUERIES & QUERY PERFORMANCE

```sql
-- Slow query stats
SELECT
  Variable_name AS 'Metric',
  Variable_value AS 'Value'
FROM performance_schema.global_status
WHERE Variable_name IN (
  'Slow_queries',
  'Questions',
  'Queries',
  'Com_select',
  'Com_insert',
  'Com_update',
  'Com_delete',
  'Select_full_join',
  'Select_scan',
  'Sort_merge_passes',
  'Created_tmp_disk_tables'
)
ORDER BY FIELD(Variable_name,
  'Questions','Queries','Com_select','Com_insert','Com_update',
  'Com_delete','Slow_queries','Select_full_join','Select_scan',
  'Sort_merge_passes','Created_tmp_disk_tables'
);
```

```sql
-- Top 10 slowest query types (if performance_schema enabled)
SELECT
  DIGEST_TEXT AS 'Query Pattern',
  COUNT_STAR AS 'Executions',
  ROUND(SUM_TIMER_WAIT / 1000000000000, 3) AS 'Total Time (s)',
  ROUND(AVG_TIMER_WAIT / 1000000000000, 3) AS 'Avg Time (s)',
  ROUND(MAX_TIMER_WAIT / 1000000000000, 3) AS 'Max Time (s)',
  SUM_ROWS_EXAMINED AS 'Rows Examined',
  SUM_ROWS_SENT AS 'Rows Sent'
FROM performance_schema.events_statements_summary_by_digest
WHERE SCHEMA_NAME NOT IN ('mysql','information_schema','performance_schema','sys')
  AND DIGEST_TEXT IS NOT NULL
ORDER BY SUM_TIMER_WAIT DESC
LIMIT 10\G
```

---

## 7. LONG RUNNING QUERIES (Kill Candidates)

```sql
SELECT
  id AS 'Process ID',
  user AS 'User',
  SUBSTRING_INDEX(host, ':', 1) AS 'Host',
  db AS 'Database',
  command AS 'Command',
  time AS 'Running (sec)',
  state AS 'State',
  LEFT(info, 120) AS 'Query'
FROM information_schema.processlist
WHERE command != 'Sleep'
  AND time > 30
  AND user NOT IN ('system user')
ORDER BY time DESC;

-- To kill a long query:
-- KILL <Process ID>;
-- To kill only the query (not connection):
-- KILL QUERY <Process ID>;
```

---

## 8. InnoDB STATUS & BUFFER POOL

```sql
-- Buffer pool usage
SELECT
  Variable_name AS 'Metric',
  CASE
    WHEN Variable_name LIKE '%pages%' THEN CONCAT(Variable_value, ' pages (',
      ROUND(Variable_value * 16 / 1024, 2), ' MB)')
    ELSE Variable_value
  END AS 'Value'
FROM performance_schema.global_status
WHERE Variable_name IN (
  'Innodb_buffer_pool_pages_total',
  'Innodb_buffer_pool_pages_data',
  'Innodb_buffer_pool_pages_dirty',
  'Innodb_buffer_pool_pages_free',
  'Innodb_buffer_pool_read_requests',
  'Innodb_buffer_pool_reads',
  'Innodb_buffer_pool_write_requests',
  'Innodb_rows_read',
  'Innodb_rows_inserted',
  'Innodb_rows_updated',
  'Innodb_rows_deleted'
)
ORDER BY FIELD(Variable_name,
  'Innodb_buffer_pool_pages_total','Innodb_buffer_pool_pages_data',
  'Innodb_buffer_pool_pages_dirty','Innodb_buffer_pool_pages_free',
  'Innodb_buffer_pool_read_requests','Innodb_buffer_pool_reads',
  'Innodb_buffer_pool_write_requests',
  'Innodb_rows_read','Innodb_rows_inserted',
  'Innodb_rows_updated','Innodb_rows_deleted'
);
```

```sql
-- Buffer pool hit ratio (should be > 99%)
SELECT
  ROUND(
    (1 - (
      (SELECT Variable_value FROM performance_schema.global_status
       WHERE Variable_name = 'Innodb_buffer_pool_reads') /
      (SELECT Variable_value FROM performance_schema.global_status
       WHERE Variable_name = 'Innodb_buffer_pool_read_requests')
    )) * 100, 2
  ) AS 'Buffer Pool Hit Ratio (%)';
```

---

## 9. BINARY LOG USAGE (Disk Space)

```sql
-- List all binary logs and sizes
SHOW BINARY LOGS;

-- Total binary log size
SELECT
  COUNT(*) AS 'Number of Binlogs',
  ROUND(SUM(File_size) / 1024 / 1024, 2) AS 'Total Size (MB)'
FROM information_schema.FILES
WHERE FILE_TYPE = 'BINARY LOG';
```

```sql
-- Binlog expiry setting
SHOW VARIABLES LIKE 'binlog_expire_logs_seconds';
-- Your setting: 604800 (7 days)
```

---

## 10. USER ACCOUNTS & PRIVILEGES

```sql
-- List all users
SELECT
  user AS 'User',
  host AS 'Host',
  account_locked AS 'Locked',
  password_expired AS 'Password Expired',
  password_last_changed AS 'Password Changed',
  password_lifetime AS 'Password Lifetime (days)'
FROM mysql.user
ORDER BY user, host;
```

```sql
-- Users with dangerous privileges
SELECT
  GRANTEE AS 'User',
  PRIVILEGE_TYPE AS 'Privilege'
FROM information_schema.user_privileges
WHERE PRIVILEGE_TYPE IN ('SUPER','ALL PRIVILEGES','GRANT OPTION','SHUTDOWN','FILE')
ORDER BY GRANTEE, PRIVILEGE_TYPE;
```

```sql
-- Check PXC SST internal user
SELECT user, host FROM mysql.user WHERE user LIKE '%sst%' OR user LIKE '%pxc%';
```

---

## 11. GALERA REPLICATION DETAILED STATS

```sql
-- Write-set replication throughput
SELECT
  CASE Variable_name
    WHEN 'wsrep_replicated'       THEN '01. Write-Sets Sent (from this node)'
    WHEN 'wsrep_replicated_bytes' THEN '02. Bytes Sent'
    WHEN 'wsrep_received'         THEN '03. Write-Sets Received (from others)'
    WHEN 'wsrep_received_bytes'   THEN '04. Bytes Received'
    WHEN 'wsrep_last_committed'   THEN '05. Last Committed Seq No'
    WHEN 'wsrep_local_commits'    THEN '06. Local Commits'
    WHEN 'wsrep_local_cert_failures' THEN '07. Certification Failures'
    WHEN 'wsrep_local_bf_aborts'     THEN '08. BF Aborts'
    WHEN 'wsrep_apply_oooe'       THEN '09. Apply Out-of-Order'
    WHEN 'wsrep_apply_oool'       THEN '10. Apply Out-of-Order Local'
    WHEN 'wsrep_commit_oooe'      THEN '11. Commit Out-of-Order'
    WHEN 'wsrep_commit_oool'      THEN '12. Commit Out-of-Order Local'
    ELSE Variable_name
  END AS 'Metric',
  Variable_value AS 'Value'
FROM performance_schema.global_status
WHERE Variable_name IN (
  'wsrep_replicated','wsrep_replicated_bytes',
  'wsrep_received','wsrep_received_bytes',
  'wsrep_last_committed','wsrep_local_commits',
  'wsrep_local_cert_failures','wsrep_local_bf_aborts',
  'wsrep_apply_oooe','wsrep_apply_oool',
  'wsrep_commit_oooe','wsrep_commit_oool'
)
ORDER BY FIELD(Variable_name,
  'wsrep_replicated','wsrep_replicated_bytes',
  'wsrep_received','wsrep_received_bytes',
  'wsrep_last_committed','wsrep_local_commits',
  'wsrep_local_cert_failures','wsrep_local_bf_aborts',
  'wsrep_apply_oooe','wsrep_apply_oool',
  'wsrep_commit_oooe','wsrep_commit_oool'
);
```

---

## 12. GALERA FLOW CONTROL DEEP DIVE

```sql
SELECT
  CASE Variable_name
    WHEN 'wsrep_flow_control_paused'    THEN '01. Time Paused (fraction 0-1)'
    WHEN 'wsrep_flow_control_paused_ns' THEN '02. Time Paused (nanoseconds)'
    WHEN 'wsrep_flow_control_sent'      THEN '03. FC Sent (this node asked to slow)'
    WHEN 'wsrep_flow_control_recv'      THEN '04. FC Received (told to slow down)'
    WHEN 'wsrep_flow_control_active'    THEN '05. FC Currently Active'
    WHEN 'wsrep_flow_control_requested' THEN '06. FC Requested'
    WHEN 'wsrep_local_recv_queue_avg'   THEN '07. Recv Queue Avg'
    WHEN 'wsrep_local_recv_queue_max'   THEN '08. Recv Queue Max'
    WHEN 'wsrep_local_recv_queue_min'   THEN '09. Recv Queue Min'
    WHEN 'wsrep_local_send_queue_avg'   THEN '10. Send Queue Avg'
    WHEN 'wsrep_local_send_queue_max'   THEN '11. Send Queue Max'
    WHEN 'wsrep_local_send_queue_min'   THEN '12. Send Queue Min'
    ELSE Variable_name
  END AS 'Metric',
  Variable_value AS 'Value',
  CASE Variable_name
    WHEN 'wsrep_flow_control_paused' THEN
      CASE
        WHEN Variable_value + 0 = 0     THEN 'PERFECT'
        WHEN Variable_value + 0 < 0.01  THEN 'GOOD'
        WHEN Variable_value + 0 < 0.1   THEN 'WARNING'
        ELSE 'CRITICAL - cluster paused!'
      END
    WHEN 'wsrep_local_recv_queue_avg' THEN
      CASE
        WHEN Variable_value + 0 < 1     THEN 'HEALTHY'
        WHEN Variable_value + 0 < 5     THEN 'WARNING'
        ELSE 'CRITICAL - node falling behind!'
      END
    WHEN 'wsrep_local_send_queue_avg' THEN
      CASE
        WHEN Variable_value + 0 < 1     THEN 'HEALTHY'
        WHEN Variable_value + 0 < 5     THEN 'WARNING'
        ELSE 'CRITICAL - network bottleneck!'
      END
    ELSE ''
  END AS 'Status'
FROM performance_schema.global_status
WHERE Variable_name IN (
  'wsrep_flow_control_paused','wsrep_flow_control_paused_ns',
  'wsrep_flow_control_sent','wsrep_flow_control_recv',
  'wsrep_flow_control_active','wsrep_flow_control_requested',
  'wsrep_local_recv_queue_avg','wsrep_local_recv_queue_max',
  'wsrep_local_recv_queue_min','wsrep_local_send_queue_avg',
  'wsrep_local_send_queue_max','wsrep_local_send_queue_min'
)
ORDER BY FIELD(Variable_name,
  'wsrep_flow_control_paused','wsrep_flow_control_paused_ns',
  'wsrep_flow_control_sent','wsrep_flow_control_recv',
  'wsrep_flow_control_active','wsrep_flow_control_requested',
  'wsrep_local_recv_queue_avg','wsrep_local_recv_queue_max',
  'wsrep_local_recv_queue_min','wsrep_local_send_queue_avg',
  'wsrep_local_send_queue_max','wsrep_local_send_queue_min'
);
```

---

## 13. TABLES WITHOUT PRIMARY KEY (Galera Needs PK!)

```sql
-- Galera requires PRIMARY KEY on all tables for proper replication
-- Tables without PK can cause performance issues or replication problems

SELECT
  t.table_schema AS 'Database',
  t.table_name AS 'Table',
  t.table_rows AS 'Rows',
  t.engine AS 'Engine',
  'MISSING PRIMARY KEY!' AS 'Problem'
FROM information_schema.tables t
LEFT JOIN information_schema.table_constraints tc
  ON t.table_schema = tc.table_schema
  AND t.table_name = tc.table_name
  AND tc.constraint_type = 'PRIMARY KEY'
WHERE t.table_schema NOT IN ('mysql','information_schema','performance_schema','sys')
  AND t.table_type = 'BASE TABLE'
  AND tc.constraint_name IS NULL
ORDER BY t.table_rows DESC;
```

---

## 14. CHECK GALERA VARIABLES (Configuration)

```sql
SELECT
  Variable_name AS 'Setting',
  Variable_value AS 'Value'
FROM performance_schema.global_variables
WHERE Variable_name LIKE 'wsrep_%'
   OR Variable_name LIKE 'pxc_%'
ORDER BY Variable_name;
```

---

## 15. UPTIME & SERVER INFO

```sql
SELECT
  CASE Variable_name
    WHEN 'Uptime'          THEN 'Uptime (seconds)'
    WHEN 'Uptime_since_flush_status' THEN 'Since Last FLUSH'
    ELSE Variable_name
  END AS 'Metric',
  Variable_value AS 'Raw Value',
  CASE Variable_name
    WHEN 'Uptime' THEN CONCAT(
      FLOOR(Variable_value / 86400), 'd ',
      FLOOR(MOD(Variable_value, 86400) / 3600), 'h ',
      FLOOR(MOD(Variable_value, 3600) / 60), 'm ',
      MOD(Variable_value, 60), 's'
    )
    WHEN 'Uptime_since_flush_status' THEN CONCAT(
      FLOOR(Variable_value / 86400), 'd ',
      FLOOR(MOD(Variable_value, 86400) / 3600), 'h ',
      FLOOR(MOD(Variable_value, 3600) / 60), 'm'
    )
    ELSE Variable_value
  END AS 'Human Readable'
FROM performance_schema.global_status
WHERE Variable_name IN ('Uptime', 'Uptime_since_flush_status');
```

```sql
-- Server version and key settings
SELECT @@version AS 'MySQL Version',
       @@hostname AS 'Hostname',
       @@server_id AS 'Server ID',
       @@datadir AS 'Data Directory',
       @@innodb_buffer_pool_size / 1024 / 1024 AS 'Buffer Pool (MB)',
       @@max_connections AS 'Max Connections',
       @@wsrep_cluster_name AS 'Cluster Name',
       @@wsrep_node_name AS 'Node Name',
       @@wsrep_node_address AS 'Node Address';
```

---

## 16. DISK USAGE CHECK (Run from bash)

```bash
# Check MySQL data directory size
sudo du -sh /var/lib/mysql/

# Check individual database sizes on disk
sudo du -sh /var/lib/mysql/*/

# Check galera cache size
sudo ls -lh /var/lib/mysql/galera.cache

# Check binary log sizes
sudo ls -lh /var/lib/mysql/binlog.*

# Check disk space
df -h /var/lib/mysql/
```

---

## DAILY CHECKLIST (Quick Reference)

Run these every morning:

| # | What | Query Number | Expected |
|---|------|-------------|----------|
| 1 | Cluster health | Query #1 | All "OK" |
| 2 | Database sizes | Query #2 | No unexpected growth |
| 3 | Long queries | Query #7 | None > 300 seconds |
| 4 | Active connections | Query #5 | Normal range |
| 5 | Flow control | Query #12 | Paused = 0 |
| 6 | Tables without PK | Query #13 | Empty result |
| 7 | Buffer pool hit ratio | Query #8 | > 99% |
| 8 | Disk space | Query #16 (bash) | > 20% free |
