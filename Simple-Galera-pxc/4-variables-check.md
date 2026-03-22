### Verify the Variables using SQL from performance_schema.global_status
```sql
SELECT Variable_name, Variable_value FROM performance_schema.global_status
WHERE Variable_name IN (
  'wsrep_cluster_state_uuid',
  'wsrep_cluster_conf_id',
  'wsrep_cluster_size',
  'wsrep_cluster_status',
  'wsrep_local_state_comment',
  'wsrep_ready',
  'wsrep_connected',
  'wsrep_incoming_addresses',
  'wsrep_last_committed',
  'wsrep_replicated',
  'wsrep_replicated_bytes',
  'wsrep_received',
  'wsrep_received_bytes',
  'wsrep_flow_control_paused',
  'wsrep_flow_control_sent',
  'wsrep_flow_control_recv',
  'wsrep_local_recv_queue_avg',
  'wsrep_local_send_queue_avg',
  'wsrep_local_cert_failures',
  'wsrep_local_bf_aborts',
  'wsrep_local_state',
  'wsrep_desync_count'
)
ORDER BY FIELD(Variable_name,
  'wsrep_cluster_state_uuid',
  'wsrep_cluster_conf_id',
  'wsrep_cluster_size',
  'wsrep_cluster_status',
  'wsrep_local_state_comment',
  'wsrep_ready',
  'wsrep_connected',
  'wsrep_incoming_addresses',
  'wsrep_last_committed',
  'wsrep_replicated',
  'wsrep_replicated_bytes',
  'wsrep_received',
  'wsrep_received_bytes',
  'wsrep_flow_control_paused',
  'wsrep_flow_control_sent',
  'wsrep_flow_control_recv',
  'wsrep_local_recv_queue_avg',
  'wsrep_local_send_queue_avg',
  'wsrep_local_cert_failures',
  'wsrep_local_bf_aborts',
  'wsrep_local_state',
  'wsrep_desync_count'
)\G
```
If Your cluster is **perfectly healthy**. find below details

---

### CLUSTER IDENTITY

| # | Variable | Your Value | Meaning | Status |
|---|----------|-----------|---------|--------|
| 1 | `wsrep_cluster_state_uuid` | `63a5c780-2584-11f1-baaa-66a4eb9348b3` | Unique ID of your cluster. All 3 nodes must show the **same UUID** — if different, a node is in a different cluster | ✅ |
| 2 | `wsrep_cluster_conf_id` | `7` | Configuration change count. Increments every time a node joins/leaves. You've had 7 membership changes (all your restart/rejoin attempts) | ✅ |
| 3 | `wsrep_cluster_size` | `3` | Number of nodes in cluster. You have all 3 nodes up | ✅ Perfect |
| 4 | `wsrep_cluster_status` | `Primary` | This node is part of the primary component (has quorum). **"Non-Primary" = split-brain or lost quorum = DANGER** | ✅ Perfect |

---

### NODE STATUS

| # | Variable | Your Value | Meaning | Status |
|---|----------|-----------|---------|--------|
| 5 | `wsrep_local_state_comment` | `Synced` | This node is fully synced. Other possible states: `Joining` → `Joined` → `Synced` → `Donor/Desynced` | ✅ Perfect |
| 6 | `wsrep_ready` | `ON` | Node is ready to accept SQL queries. **OFF = node refuses all queries** | ✅ |
| 7 | `wsrep_connected` | `ON` | Node is connected to the cluster. **OFF = disconnected, no replication** | ✅ |
| 8 | `wsrep_incoming_addresses` | `10.0.1.2:3306, 10.0.3.2:3306, 10.0.2.2:3306` | All nodes that are part of the cluster with their MySQL ports. All 3 IPs present confirms full cluster | ✅ All 3 nodes |

---

### REPLICATION HEALTH

| # | Variable | Your Value | Meaning | Status |
|---|----------|-----------|---------|--------|
| 9 | `wsrep_last_committed` | `13` | Sequence number of last committed transaction. All nodes should show the same number when idle | ✅ |
| 10 | `wsrep_replicated` | `1` | Write-sets sent FROM this node to others. Low because you've only done 1 write from this node | ✅ Normal |
| 11 | `wsrep_replicated_bytes` | `328` | Bytes sent from this node (328 bytes for 1 write-set) | ✅ |
| 12 | `wsrep_received` | `23` | Write-sets RECEIVED from other nodes. This node received 23 write-sets (includes SST and cluster config changes) | ✅ |
| 13 | `wsrep_received_bytes` | `2680` | Bytes received from other nodes (2.6 KB total) | ✅ |

**What replicated vs received tells you:**

```
replicated = 1   → This node SENT 1 transaction to the cluster
received   = 23  → This node RECEIVED 23 transactions from other nodes

If replicated >> received → This node is doing most of the writes
If received >> replicated → Other nodes are doing most of the writes
```

---

### PERFORMANCE (Most Important for Production)

| # | Variable | Your Value | Meaning | Status |
|---|----------|-----------|---------|--------|
| 14 | `wsrep_flow_control_paused` | `0` | Fraction of time cluster was PAUSED due to a slow node. **0 = never paused.** Range: 0.0 to 1.0. **Above 0.1 = performance problem** | ✅ Perfect |
| 15 | `wsrep_flow_control_sent` | `0` | Times THIS node asked others to slow down (because it was falling behind). **0 = this node is keeping up** | ✅ Perfect |
| 16 | `wsrep_flow_control_recv` | `0` | Times THIS node was told to slow down by another node. **0 = no other node is slow** | ✅ Perfect |
| 17 | `wsrep_local_recv_queue_avg` | `0.130435` | Average receive queue length. How many write-sets are waiting to be applied. **< 1.0 = healthy. > 5.0 = node falling behind** | ✅ Healthy |
| 18 | `wsrep_local_send_queue_avg` | `0` | Average send queue length. Write-sets waiting to be sent to other nodes. **0 = network is keeping up perfectly** | ✅ Perfect |

**Performance summary:**

```
Flow control paused:  0%     → Cluster never had to pause
Recv queue avg:       0.13   → Nearly instant applying
Send queue avg:       0      → Network has zero backlog
Verdict: EXCELLENT performance
```

---

### CONFLICTS

| # | Variable | Your Value | Meaning | Status |
|---|----------|-----------|---------|--------|
| 19 | `wsrep_local_cert_failures` | `0` | Transactions REJECTED due to certification conflicts (two nodes writing same row). **0 = no conflicts at all** | ✅ Perfect |
| 20 | `wsrep_local_bf_aborts` | `0` | Transactions killed (brute-force aborted) by a replicated write-set from another node. **0 = no conflicts** | ✅ Perfect |

**If these start growing in production:**

```
cert_failures increasing → Different nodes updating same rows simultaneously
                        → Fix: route same-row writes to same node
                        → Or: add retry logic in application

bf_aborts increasing    → Long-running transactions being killed by replication
                       → Fix: keep transactions short
```

---

### IST/SST STATUS

| # | Variable | Your Value | Meaning | Status |
|---|----------|-----------|---------|--------|
| 21 | `wsrep_local_state` | `4` | Numeric state of this node. **4 = Synced (best).** States: 1=Joining, 2=Donor/Desynced, 3=Joined, 4=Synced | ✅ Perfect |
| 22 | `wsrep_desync_count` | `0` | Number of desync operations in progress. **0 = normal.** Non-zero during SST donation or when `wsrep_desync=ON` for maintenance | ✅ |

**State number reference:**

```
1 = Joining     → Node is joining cluster, receiving SST/IST
2 = Donor       → Node is sending SST to another node
3 = Joined      → SST/IST complete, catching up with recent write-sets
4 = Synced      → Fully caught up, ready for traffic ← YOU ARE HERE ✅
```

---

### OVERALL VERDICT

```
Cluster Size:     3/3 nodes    ✅
Cluster Status:   Primary      ✅
Node State:       Synced (4)   ✅
Ready:            ON           ✅
Connected:        ON           ✅
Flow Control:     0%           ✅
Cert Failures:    0            ✅
Recv Queue:       0.13         ✅
Send Queue:       0            ✅

RESULT: PERFECTLY HEALTHY CLUSTER 🟢
```
