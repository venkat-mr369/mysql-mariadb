# PXC 8.0 — Maintenance Activities & wsrep_provider_options Explained

---

## PART 1: wsrep_provider_options — Full Explanation

The `wsrep_provider_options` is one giant variable containing ALL Galera-level settings. Here's every parameter grouped by category:

---

### 1. BASE SETTINGS — Node Identity

| Parameter | Your Value | Meaning |
|-----------|-----------|---------|
| `base_dir` | `/var/lib/mysql/` | Galera working directory |
| `base_host` | `10.0.1.2` | This node's IP address |
| `base_port` | `4567` | Galera replication port |

---

### 2. EVS (Extended Virtual Synchrony) — Cluster Membership & Heartbeat

Controls how nodes detect each other, handle failures, and maintain group membership.

| Parameter | Your Value | Meaning |
|-----------|-----------|---------|
| `evs.keepalive_period` | `PT1S` | Send heartbeat every 1 second |
| `evs.suspect_timeout` | `PT5S` | After 5s without heartbeat, node is "suspected" down |
| `evs.inactive_timeout` | `PT15S` | After 15s without heartbeat, node is declared dead and evicted |
| `evs.inactive_check_period` | `PT0.5S` | Check for inactive nodes every 0.5 seconds |
| `evs.install_timeout` | `PT7.5S` | Max time to install a new cluster view |
| `evs.join_retrans_period` | `PT1S` | Retry join message every 1 second |
| `evs.causal_keepalive_period` | `PT1S` | Causal ordering keepalive interval |
| `evs.delay_margin` | `PT1S` | Tolerated delay before marking node as delayed |
| `evs.delayed_keep_period` | `PT30S` | Keep delayed node in cluster for 30 seconds before evicting |
| `evs.send_window` | `10` | Max messages in flight (protocol level) |
| `evs.user_send_window` | `4` | Max messages in flight (user/application level) |
| `evs.max_install_timeouts` | `3` | Max view install retries before giving up |
| `evs.auto_evict` | `0` | Auto-evict disabled (0 = off, N = evict after N suspected rounds) |
| `evs.stats_report_period` | `PT1M` | Report EVS stats every 1 minute |
| `evs.use_aggregate` | `true` | Aggregate small messages for efficiency |
| `evs.view_forget_timeout` | `P1D` | Forget old views after 1 day |
| `evs.debug_log_mask` | `0x1` | Debug logging level |
| `evs.info_log_mask` | `0` | Info logging level |
| `evs.version` | `1` | EVS protocol version |

**How failure detection works:**

```
Heartbeat every 1s → No response for 5s → SUSPECTED
→ No response for 15s → DEAD → Node evicted from cluster
```

---

### 3. GCACHE (Galera Cache) — Write-Set Cache for IST

Stores recent write-sets so rejoining nodes can use IST (incremental) instead of full SST.

| Parameter | Your Value | Meaning |
|-----------|-----------|---------|
| `gcache.size` | `128M` | Total cache size (increase for busy clusters to allow longer IST window) |
| `gcache.dir` | `/var/lib/mysql/` | Cache file location |
| `gcache.name` | `galera.cache` | Cache filename |
| `gcache.mem_size` | `0` | In-memory cache (0 = disabled, uses disk only) |
| `gcache.page_size` | `128M` | Page file size for overflow |
| `gcache.keep_pages_count` | `0` | Don't keep old page files |
| `gcache.keep_pages_size` | `0` | Don't keep old page files by size |
| `gcache.recover` | `yes` | Recover cache on restart (enables IST after clean restart) |
| `gcache.freeze_purge_at_seqno` | `-1` | Don't freeze purging (-1 = disabled) |
| `gcache.encryption` | `no` | Cache encryption disabled |

**Why gcache.size matters:**

```
gcache.size = 128M (default)
→ Stores last ~128M of write-sets
→ If a node is down for a short time, it can rejoin via IST (fast)
→ If it's down too long (cache overwritten), it needs full SST (slow)
→ Increase to 1G-2G in production for longer IST windows
```

---

### 4. GCS (Group Communication System) — Flow Control

Controls how fast nodes can send data and prevents slow nodes from falling behind.

| Parameter | Your Value | Meaning |
|-----------|-----------|---------|
| `gcs.fc_limit` | `100` | Pause replication when receive queue hits 100 write-sets |
| `gcs.fc_factor` | `1.0` | Resume at fc_limit × fc_factor (100 × 1.0 = 100, resume immediately when queue drops) |
| `gcs.fc_master_slave` | `no` | Not in master-slave mode (multi-master) |
| `gcs.fc_single_primary` | `no` | Not single-primary mode |
| `gcs.fc_auto_evict_threshold` | `0.75` | Auto-evict node if it causes flow control >75% of time |
| `gcs.fc_auto_evict_window` | `0` | Auto-evict window disabled |
| `gcs.max_packet_size` | `64500` | Max replication packet size |
| `gcs.max_throttle` | `0.25` | Max throttle — node can slow to 25% of normal speed |
| `gcs.recv_q_hard_limit` | `9223372036854775807` | Max receive queue (effectively unlimited) |
| `gcs.recv_q_soft_limit` | `0.25` | Start throttling at 25% of hard limit |
| `gcs.sync_donor` | `no` | Donor stays available during SST |
| `gcs.check_appl_proto` | `1` | Check applier protocol version |

**Flow control explained:**

```
Node falls behind → Receive queue grows
→ Queue reaches 100 (fc_limit) → ALL nodes PAUSE writes
→ Slow node catches up → Queue drops → Writes resume
→ This is why 1 slow node can affect entire cluster performance
```

---

### 5. GMCAST — Group Communication Transport

| Parameter | Your Value | Meaning |
|-----------|-----------|---------|
| `gmcast.listen_addr` | `tcp://0.0.0.0:4567` | Listen on all interfaces, port 4567 |
| `gmcast.peer_timeout` | `PT3S` | Peer connection timeout (3 seconds) |
| `gmcast.time_wait` | `PT5S` | Wait time before reconnecting |
| `gmcast.segment` | `0` | Network segment (for multi-datacenter: 0, 1, 2...) |
| `gmcast.mcast_addr` | (empty) | Multicast address (not used) |
| `gmcast.mcast_ttl` | `1` | Multicast TTL |
| `gmcast.version` | `0` | Protocol version |

---

### 6. IST (Incremental State Transfer) Settings

| Parameter | Your Value | Meaning |
|-----------|-----------|---------|
| `ist.recv_addr` | `10.0.1.2` | IST receiver address (this node's IP) |

---

### 7. PC (Primary Component) — Quorum & Split-Brain

| Parameter | Your Value | Meaning |
|-----------|-----------|---------|
| `pc.wait_prim` | `true` | Wait for primary component on startup |
| `pc.wait_prim_timeout` | `PT30S` | Wait 30 seconds to find primary before giving up |
| `pc.wait_restored_prim_timeout` | `PT0S` | Don't wait for restored primary |
| `pc.weight` | `1` | Node's voting weight (all equal at 1) |
| `pc.ignore_quorum` | `false` | Respect quorum rules (NEVER set true in production) |
| `pc.ignore_sb` | `false` | Don't ignore split-brain (NEVER set true in production) |
| `pc.recovery` | `true` | Recover primary component automatically after crash |
| `pc.announce_timeout` | `PT3S` | Announce timeout for PC protocol |
| `pc.linger` | `PT20S` | Linger period after losing primary |
| `pc.npvo` | `false` | Non-Primary View Override disabled |
| `pc.checksum` | `false` | PC message checksum disabled |
| `pc.version` | `0` | PC protocol version |

**Quorum math (3-node cluster):**

```
3 nodes → need majority (2) for quorum
1 node down  → 2 alive → quorum OK   → cluster continues
2 nodes down → 1 alive → NO quorum   → cluster stops writes
```

---

### 8. REPL (Replication) — Write-Set Processing

| Parameter | Your Value | Meaning |
|-----------|-----------|---------|
| `repl.commit_order` | `3` | Commit order mode (3 = fully ordered) |
| `repl.causal_read_timeout` | `PT30S` | Wait up to 30s for causal reads |
| `repl.key_format` | `FLAT8` | Key format for certification |
| `repl.max_ws_size` | `2147483647` | Max write-set size (~2GB) |
| `repl.proto_max` | `11` | Max replication protocol version |

---

### 9. CERT (Certification) — Conflict Detection

| Parameter | Your Value | Meaning |
|-----------|-----------|---------|
| `cert.log_conflicts` | `no` | Don't log certification conflicts (set `yes` for debugging) |
| `cert.optimistic_pa` | `no` | Optimistic parallel applying disabled |

---

### 10. SOCKET — Network & Encryption

| Parameter | Your Value | Meaning |
|-----------|-----------|---------|
| `socket.checksum` | `2` | CRC32-C checksums enabled |
| `socket.recv_buf_size` | `auto` | Auto-size receive buffer |
| `socket.send_buf_size` | `auto` | Auto-size send buffer |

**Note:** Since you set `pxc-encrypt-cluster-traffic=OFF`, there are no `socket.ssl_*` parameters. In production with encryption ON, you'd see `socket.ssl_ca`, `socket.ssl_cert`, `socket.ssl_key` here.

---

### 11. ALLOCATOR — Disk Encryption for Galera

| Parameter | Your Value | Meaning |
|-----------|-----------|---------|
| `allocator.disk_pages_encryption` | `no` | Disk page encryption disabled |
| `allocator.encryption_cache_page_size` | `32K` | Encryption cache page size |
| `allocator.encryption_cache_size` | `16777216` | Encryption cache (16MB) |

---

## PART 2: Daily Maintenance Activities

### Daily Health Checks

Run these commands daily from any node:

```sql
-- 1. Cluster size (should be 3)
SHOW STATUS LIKE 'wsrep_cluster_size';

-- 2. All nodes synced?
SHOW STATUS LIKE 'wsrep_local_state_comment';
-- Expected: "Synced"

-- 3. Cluster is primary?
SHOW STATUS LIKE 'wsrep_cluster_status';
-- Expected: "Primary"

-- 4. Check for flow control pauses (should be 0 or near 0)
SHOW STATUS LIKE 'wsrep_flow_control_paused';
-- If > 0.1 (10%), a node is slow

-- 5. Check replication lag
SHOW STATUS LIKE 'wsrep_local_recv_queue_avg';
-- Should be < 1.0 — higher means node is falling behind

-- 6. Check for certification conflicts
SHOW STATUS LIKE 'wsrep_local_cert_failures';
-- Non-zero means write conflicts between nodes

-- 7. Check connected node addresses
SHOW STATUS LIKE 'wsrep_incoming_addresses';
```

### Quick One-Liner Health Check

```bash
mysql -uroot -p -e "
SHOW STATUS WHERE Variable_name IN (
  'wsrep_cluster_size',
  'wsrep_cluster_status',
  'wsrep_local_state_comment',
  'wsrep_flow_control_paused',
  'wsrep_local_recv_queue_avg',
  'wsrep_local_send_queue_avg',
  'wsrep_local_cert_failures',
  'wsrep_incoming_addresses',
  'wsrep_ready',
  'wsrep_connected'
);"
```

---

### Weekly Maintenance

```sql
-- 1. Check total write-sets replicated
SHOW STATUS LIKE 'wsrep_replicated';
SHOW STATUS LIKE 'wsrep_received';

-- 2. Check data/index sizes
SELECT table_schema,
       ROUND(SUM(data_length)/1024/1024, 2) AS data_mb,
       ROUND(SUM(index_length)/1024/1024, 2) AS index_mb
FROM information_schema.tables
GROUP BY table_schema;

-- 3. Check slow queries
SHOW GLOBAL STATUS LIKE 'Slow_queries';

-- 4. Check binary log usage
SHOW BINARY LOGS;
```

---

### Monitoring Flow Control (CRITICAL for Performance)

```sql
-- Current flow control status
SHOW STATUS LIKE 'wsrep_flow_control_paused';     -- Fraction of time paused (0.0 to 1.0)
SHOW STATUS LIKE 'wsrep_flow_control_paused_ns';   -- Total nanoseconds paused
SHOW STATUS LIKE 'wsrep_flow_control_sent';         -- Times this node triggered FC
SHOW STATUS LIKE 'wsrep_flow_control_recv';         -- Times this node received FC

-- If flow_control_paused > 0.1, check which node is slow:
SHOW STATUS LIKE 'wsrep_local_recv_queue_avg';      -- This node's receive queue
SHOW STATUS LIKE 'wsrep_local_send_queue_avg';      -- This node's send queue
```

**Tuning flow control:**

```sql
-- Increase fc_limit if occasional spikes are OK (default: 100)
SET GLOBAL wsrep_provider_options = "gcs.fc_limit=200";

-- Increase applier threads for faster applying
SET GLOBAL wsrep_slave_threads = 16;
```

---

### Node Maintenance — Safe Restart

**Single node restart (cluster stays up):**

```bash
# On the node being restarted
sudo systemctl stop mysqld

# Verify cluster still has quorum (from another node)
mysql -uroot -p -e "SHOW STATUS LIKE 'wsrep_cluster_size';"
# Should show 2

# Restart the node
sudo systemctl start mysqld

# Verify it rejoined
mysql -uroot -p -e "SHOW STATUS LIKE 'wsrep_cluster_size';"
# Should show 3 again
```

**Full cluster restart (all nodes down):**

```bash
# Step 1: Stop all nodes
# On Node3
sudo systemctl stop mysqld
# On Node2
sudo systemctl stop mysqld
# On Node1
sudo systemctl stop mysqld

# Step 2: Find the most advanced node
sudo cat /var/lib/mysql/grastate.dat
# Look for the highest seqno — bootstrap THAT node first

# Step 3: Bootstrap the most advanced node
# If Node1 has highest seqno:
sudo systemctl start mysql@bootstrap.service

# Step 4: Start other nodes
# On Node2
sudo systemctl start mysqld
# On Node3
sudo systemctl start mysqld

# Step 5: Switch bootstrap node to normal
# On Node1
sudo systemctl stop mysql@bootstrap.service
sudo systemctl start mysqld
```

---

### Backup Strategy

```bash
# Online backup using xtrabackup (no downtime)
sudo xtrabackup --backup --target-dir=/backup/full_$(date +%Y%m%d)

# Prepare the backup
sudo xtrabackup --prepare --target-dir=/backup/full_20260322

# Verify backup
sudo xtrabackup --validate --target-dir=/backup/full_20260322
```

**Or use mysqldump (locks tables briefly):**

```bash
mysqldump -uroot -p --all-databases --single-transaction \
  --triggers --routines --events > /backup/full_$(date +%Y%m%d).sql
```

---

### IST vs SST — When Each Happens

| Scenario | Transfer Type | Speed |
|----------|--------------|-------|
| Node down < few minutes, gcache has data | IST (incremental) | Fast — only missing write-sets |
| Node down too long, gcache overwritten | SST (full snapshot) | Slow — full xtrabackup copy |
| New node joining | SST | Slow — no existing data |
| Node with corrupt data | SST | Slow — needs fresh copy |

**Increase IST window (production recommendation):**

```ini
# In my.cnf under [mysqld]
wsrep_provider_options="gcache.size=1G"
```

This stores ~1GB of write-sets, allowing nodes to rejoin via fast IST even after longer downtime.

---

### Key wsrep Status Variables to Monitor

| Variable | Good Value | Bad Sign |
|----------|-----------|----------|
| `wsrep_cluster_size` | 3 | Less than 3 — node is down |
| `wsrep_cluster_status` | Primary | Non-Primary — split brain |
| `wsrep_local_state_comment` | Synced | Joining/Donor — node catching up |
| `wsrep_ready` | ON | OFF — node can't accept queries |
| `wsrep_connected` | ON | OFF — disconnected from cluster |
| `wsrep_flow_control_paused` | < 0.01 | > 0.1 — performance problem |
| `wsrep_local_recv_queue_avg` | < 1.0 | > 5.0 — node falling behind |
| `wsrep_local_cert_failures` | 0 or low | Growing fast — write conflicts |

---

### Common Maintenance Commands Reference

```sql
-- Desync a node for maintenance (takes it out of flow control)
SET GLOBAL wsrep_desync = ON;
-- ... do maintenance (ALTER TABLE, etc.) ...
SET GLOBAL wsrep_desync = OFF;

-- Check who is the donor during SST
SHOW STATUS LIKE 'wsrep_local_state_comment';
-- "Donor/Desynced" means this node is sending SST

-- Force a node to resync
SET GLOBAL wsrep_desync = OFF;

-- Check Galera version
SHOW STATUS LIKE 'wsrep_provider_version';

-- Check cluster UUID
SHOW STATUS LIKE 'wsrep_cluster_state_uuid';

-- Check last committed transaction
SHOW STATUS LIKE 'wsrep_last_committed';
```
