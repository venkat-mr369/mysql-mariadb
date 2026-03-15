Complete steps covering all 12 parts of the setup. 

1. **mysql user creation** with `/sbin/nologin` as a system service account
2. **dzdo / sudo configuration** so `venkat` can switch to `mysql` via `dzdo -u mysql -i`
3. **SSH key generation and distribution** across all 3 nodes for passwordless cross-node operations
4. **MySQL 8.0 installation** from the official repo on Oracle Linux 9
5. **my.cnf configuration** with all Group Replication prerequisites (GTID, binlog, etc.)
6. **Instance preparation** using `dba.configureInstance()` via MySQL Shell
7. **Cluster creation** with `dba.createCluster()` + `cluster.addInstance()` using clone recovery
8. **MySQL Router bootstrap** for automatic R/W and R/O routing
9. **Failover/Failback** — both automatic (built-in) and manual (`setPrimaryInstance`), plus a reusable shell script leveraging the mysql user's SSH keys
10. **Full outage recovery** with `dba.rebootClusterFromCompleteOutage()`

