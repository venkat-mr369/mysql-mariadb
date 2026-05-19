[mysqld]

# =====================================================
# BASIC NETWORK (Production Important Parameters
# =====================================================

bind-address=0.0.0.0

# =====================================================
# GALERA ENABLEMENT
# =====================================================

wsrep_on=ON

wsrep_provider=/usr/lib/galera/libgalera_smm.so

wsrep_cluster_name=galera_cluster

# =====================================================
# CLUSTER ADDRESS
# =====================================================
#
# FIRST BOOTSTRAP NODE:
# wsrep_cluster_address=gcomm://
#
# NORMAL PRODUCTION:
# existing nodes list
#
# =====================================================

wsrep_cluster_address=gcomm://mariadb1,mariadb2,mariadb3

# =====================================================
# NODE DETAILS
# =====================================================

wsrep_node_name=mariadb1
wsrep_node_address=mariadb1

# =====================================================
# SST CONFIGURATION
# =====================================================

wsrep_sst_method=mariabackup

wsrep_sst_auth=root:Maria@123

# =====================================================
# IMPORTANT GALERA SETTINGS
# =====================================================

# Required for Galera
binlog_format=ROW

# Required for Galera
default_storage_engine=InnoDB

# Required for Galera
innodb_autoinc_lock_mode=2

# =====================================================
# GCACHE
# =====================================================
#
# VERY IMPORTANT IN PRODUCTION
#
# Helps IST recovery
# Prevents expensive SST
#
# Small gcache:
#    node down long time -> SST
#
# Large gcache:
#    node down -> IST possible
#
# =====================================================

wsrep_provider_options="gcache.size=10G;gcache.recover=yes"

# =====================================================
# FLOW CONTROL / PERFORMANCE
# =====================================================

# Avoid flow control pauses under heavy load
wsrep_slave_threads=8

# =====================================================
# INNODB MEMORY TUNING
# =====================================================

# Usually 60-70% RAM in production
innodb_buffer_pool_size=4G

# Buffer pool instances
innodb_buffer_pool_instances=4

# Log file size
innodb_log_file_size=1G

# Flush behavior
innodb_flush_log_at_trx_commit=1

# File per table
innodb_file_per_table=1

# IO capacity
innodb_io_capacity=2000

# =====================================================
# CONNECTIONS
# =====================================================

max_connections=1000

thread_cache_size=100

table_open_cache=4000

open_files_limit=65535

# =====================================================
# TEMP TABLES
# =====================================================

tmp_table_size=256M

max_heap_table_size=256M

# =====================================================
# BINARY LOGGING
# =====================================================

sync_binlog=1

expire_logs_days=7

# =====================================================
# CHARACTER SET
# =====================================================

character-set-server=utf8mb4

collation-server=utf8mb4_general_ci

# =====================================================
# TIMEOUTS
# =====================================================

wait_timeout=600

interactive_timeout=600

# =====================================================
# SLOW QUERY LOG
# =====================================================

slow_query_log=ON

slow_query_log_file=/var/lib/mysql/slow.log

long_query_time=2

log_queries_not_using_indexes=ON

# =====================================================
# ERROR LOG
# =====================================================

log_error=/var/lib/mysql/error.log

# =====================================================
# PERFORMANCE SCHEMA
# =====================================================

performance_schema=ON

# =====================================================
# SECURITY
# =====================================================

local_infile=0

skip_name_resolve=ON

# =====================================================
# CRASH SAFETY
# =====================================================

innodb_flush_method=O_DIRECT

# =====================================================
# REPLICATION RELIABILITY
# =====================================================

wsrep_retry_autocommit=3

# =====================================================
# DONOR PREFERENCE
# =====================================================
#
# Optional:
# Preferred donor during SST
#
# wsrep_sst_donor=mariadb3
#
# =====================================================

# =====================================================
# MONITORING RECOMMENDED
# =====================================================
#
# Monitor these:
#
# wsrep_cluster_size
# wsrep_cluster_status
# wsrep_local_state_comment
# wsrep_ready
# wsrep_flow_control_paused
#
# =====================================================

# =====================================================
# PRODUCTION BEST PRACTICES
# =====================================================
#
# 1. Use odd number nodes (3/5/7)
#
# 2. Use dedicated MaxScale/Proxy layer
#
# 3. Applications should connect ONLY to proxy
#
# 4. Use large gcache for IST recovery
#
# 5. Avoid direct multi-node writes
#
# 6. Prefer single-writer logical architecture
#
# 7. Monitor flow control closely
#
# 8. Use physical backups:
#    mariabackup/xtrabackup
#
# 9. Use rolling restarts only
#
# 10. Avoid SST on large databases
#
# =====================================================
