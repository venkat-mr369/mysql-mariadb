#!/bin/bash
# =============================================================================
# MySQL NDB Cluster Setup Script
# Project  : ams-kap
# Run from : ANY node — login to ams-vm-1 and execute this script
#
# CLUSTER NODES:
#   ams-vm-1  10.0.1.2  Management Node  (ndb_mgmd)
#   ams-vm-2  10.0.2.2  Data Node 1      (ndbd)
#   ams-vm-3  10.0.3.2  Data Node 2      (ndbd)
#   ams-vm-4  10.0.1.3  SQL Node 1       (mysqld)
#   ams-vm-5  10.0.2.3  SQL Node 2       (mysqld)
#
# HOW TO RUN:
#   Step 1 — Copy script to the VM you are logged into
#             scp ndb_cluster_setup.sh ams2007dj@34.31.0.254:~/
#   Step 2 — SSH into that VM
#             ssh ams2007dj@34.31.0.254
#   Step 3 — Setup SSH keys first (see STEP 0 below)
#   Step 4 — Make executable and run
#             chmod +x ndb_cluster_setup.sh
#             ./ndb_cluster_setup.sh
#
# STARTUP ORDER  : Management Node → Data Nodes → SQL Nodes
# SHUTDOWN ORDER : SQL Nodes → ndb_mgm -e "SHUTDOWN"
# =============================================================================

set -e

# =============================================================================
# CONFIGURATION — Edit these if your values change
# =============================================================================
MYSQL_ROOT_PASSWORD="AmsKap@NDB8!"
SSH_USER="ams2007dj"

MGMT_IP="10.0.1.2";  MGMT_HOST="ams-vm-1"
DATA1_IP="10.0.2.2"; DATA1_HOST="ams-vm-2"
DATA2_IP="10.0.3.2"; DATA2_HOST="ams-vm-3"
SQL1_IP="10.0.1.3";  SQL1_HOST="ams-vm-4"
SQL2_IP="10.0.2.3";  SQL2_HOST="ams-vm-5"

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================
log()  {
  echo ""
  echo "================================================================"
  echo "==> $1"
  echo "================================================================"
}
info() { echo "    [INFO] $1"; }
ok()   { echo "    [OK]   $1"; }

# SSH into remote node and run command as root
ssh_cmd() {
  local IP=$1
  local CMD=$2
  ssh -o StrictHostKeyChecking=no \
      -o ConnectTimeout=10 \
      -o BatchMode=yes \
      "$SSH_USER@$IP" "sudo bash -s" <<< "$CMD"
}

# Run locally as root
local_cmd() {
  sudo bash -s <<< "$1"
}

# Auto detect which IP this script is running on
CURRENT_IP=$(hostname -I | awk '{print $1}')
info "Script running from IP: $CURRENT_IP"

# =============================================================================
# STEP 0 — SSH Key Setup
#           Must be done ONCE before running this script.
#           Allows passwordless SSH between all nodes.
# =============================================================================
log "STEP 0 — Checking SSH key connectivity between all nodes"

echo ""
echo "  ---------------------------------------------------------------"
echo "  If this is your first time, run these commands manually ONCE:"
echo ""
echo "  ssh-keygen -t rsa -b 2048 -f ~/.ssh/id_rsa -N ''"
echo ""
echo "  ssh-copy-id $SSH_USER@$MGMT_IP"
echo "  ssh-copy-id $SSH_USER@$DATA1_IP"
echo "  ssh-copy-id $SSH_USER@$DATA2_IP"
echo "  ssh-copy-id $SSH_USER@$SQL1_IP"
echo "  ssh-copy-id $SSH_USER@$SQL2_IP"
echo ""
echo "  Then re-run: ./ndb_cluster_setup.sh"
echo "  ---------------------------------------------------------------"
echo ""

ALL_SSH_OK=true
for IP in $MGMT_IP $DATA1_IP $DATA2_IP $SQL1_IP $SQL2_IP; do
  if [[ "$IP" == "$CURRENT_IP" ]]; then
    ok "Local node ($IP) — no SSH needed"
    continue
  fi
  if ssh -o StrictHostKeyChecking=no \
         -o ConnectTimeout=5 \
         -o BatchMode=yes \
         "$SSH_USER@$IP" "echo reachable" &>/dev/null; then
    ok "SSH to $IP — reachable"
  else
    echo "    [FAIL] Cannot reach $IP — set up SSH keys first (see above)"
    ALL_SSH_OK=false
  fi
done

if [ "$ALL_SSH_OK" = false ]; then
  echo ""
  echo "  ERROR: Fix SSH key setup first then re-run this script."
  exit 1
fi
ok "All nodes reachable."

# =============================================================================
# STEP 1 — Update /etc/hosts on ALL 5 VMs
# =============================================================================
log "STEP 1 — Updating /etc/hosts on all VMs"

HOSTS_BLOCK="$MGMT_IP  ams-vm-1
$DATA1_IP ams-vm-2
$DATA2_IP ams-vm-3
$SQL1_IP  ams-vm-4
$SQL2_IP  ams-vm-5"

HOSTS_CMD="grep -q 'ams-vm-1' /etc/hosts && echo 'already set' || printf '$HOSTS_BLOCK\n' >> /etc/hosts
grep 'ams-vm' /etc/hosts"

for IP in $MGMT_IP $DATA1_IP $DATA2_IP $SQL1_IP $SQL2_IP; do
  info "Updating /etc/hosts on $IP..."
  if [[ "$IP" == "$CURRENT_IP" ]]; then
    local_cmd "$HOSTS_CMD"
  else
    ssh_cmd "$IP" "$HOSTS_CMD"
  fi
  ok "Done on $IP"
done

# =============================================================================
# STEP 2 — Add MySQL Cluster 8.0 repo on ALL 5 VMs
# =============================================================================
log "STEP 2 — Installing MySQL Cluster 8.0 repo on all VMs"

REPO_CMD="rpm -q mysql80-community-release 2>/dev/null || rpm -ivh https://dev.mysql.com/get/mysql80-community-release-el9-5.noarch.rpm
dnf config-manager --disable mysql80-community -y 2>/dev/null || true
dnf config-manager --enable mysql-cluster-8.0-community -y
yum repolist enabled | grep mysql"

for IP in $MGMT_IP $DATA1_IP $DATA2_IP $SQL1_IP $SQL2_IP; do
  info "Setting MySQL Cluster repo on $IP..."
  if [[ "$IP" == "$CURRENT_IP" ]]; then
    local_cmd "$REPO_CMD"
  else
    ssh_cmd "$IP" "$REPO_CMD"
  fi
  ok "Repo ready on $IP"
done

# =============================================================================
# STEP 3 — Open firewall ports on ALL 5 VMs
#           22=SSH, 1186=NDB Mgmt, 2202=NDB Data, 3306=MySQL
# =============================================================================
log "STEP 3 — Opening firewall ports on all VMs"

FIREWALL_CMD="systemctl enable firewalld
systemctl start firewalld
firewall-cmd --permanent --add-port=22/tcp
firewall-cmd --permanent --add-port=1186/tcp
firewall-cmd --permanent --add-port=2202/tcp
firewall-cmd --permanent --add-port=3306/tcp
firewall-cmd --reload
echo 'Open ports on '$(hostname)
firewall-cmd --list-ports"

for IP in $MGMT_IP $DATA1_IP $DATA2_IP $SQL1_IP $SQL2_IP; do
  info "Opening ports on $IP..."
  if [[ "$IP" == "$CURRENT_IP" ]]; then
    local_cmd "$FIREWALL_CMD"
  else
    ssh_cmd "$IP" "$FIREWALL_CMD"
  fi
  ok "Ports open on $IP"
done

# =============================================================================
# STEP 4 — Setup Management Node on ams-vm-1 (10.0.1.2)
# =============================================================================
log "STEP 4 — Setting up Management Node on $MGMT_HOST ($MGMT_IP)"

MGMT_CMD="echo '>>> Installing ndb_mgmd...'
dnf install -y mysql-cluster-community-management-server
mkdir -p /var/lib/mysql-cluster
cat > /var/lib/mysql-cluster/config.ini << 'CONFIGEOF'
[ndbd default]
NoOfReplicas=2
DataMemory=512M

[ndb_mgmd]
HostName=ams-vm-1
NodeId=1
DataDir=/var/lib/mysql-cluster

[ndbd]
HostName=ams-vm-2
NodeId=2
DataDir=/usr/local/mysql/data

[ndbd]
HostName=ams-vm-3
NodeId=3
DataDir=/usr/local/mysql/data

[mysqld]
HostName=ams-vm-4
NodeId=12

[mysqld]
HostName=ams-vm-5
NodeId=13
CONFIGEOF
echo '>>> Starting ndb_mgmd initial run...'
/usr/sbin/ndb_mgmd --initial -f /var/lib/mysql-cluster/config.ini
sleep 5
pkill -f ndb_mgmd || true
sleep 2
cat > /etc/systemd/system/ndb_mgmd.service << 'SVCEOF'
[Unit]
Description=MySQL NDB Cluster Management Server
After=network.target auditd.service

[Service]
Type=forking
ExecStart=/usr/sbin/ndb_mgmd -f /var/lib/mysql-cluster/config.ini
ExecReload=/bin/kill -HUP \$MAINPID
KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target
SVCEOF
systemctl daemon-reload
systemctl enable ndb_mgmd
systemctl start ndb_mgmd
systemctl status ndb_mgmd --no-pager
echo '>>> Management Node READY'"

if [[ "$MGMT_IP" == "$CURRENT_IP" ]]; then
  local_cmd "$MGMT_CMD"
else
  ssh_cmd "$MGMT_IP" "$MGMT_CMD"
fi
ok "Management Node UP. Waiting 10 seconds..."
sleep 10

# =============================================================================
# STEP 5 — Setup Data Nodes on ams-vm-2 and ams-vm-3
# =============================================================================
log "STEP 5 — Setting up Data Nodes ($DATA1_HOST and $DATA2_HOST)"

DATA_CMD="dnf install -y mysql-cluster-community-data-node
mkdir -p /usr/local/mysql/data
cat > /etc/my.cnf << 'CNFEOF'
[mysqld]
ndbcluster

[mysql_cluster]
ndb-connectstring=ams-vm-1
CNFEOF
/usr/sbin/ndbd --initial
sleep 5
pkill -f ndbd || true
sleep 2
cat > /etc/systemd/system/ndbd.service << 'SVCEOF'
[Unit]
Description=MySQL NDB Data Node Daemon
After=network.target auditd.service

[Service]
Type=forking
ExecStart=/usr/sbin/ndbd
ExecReload=/bin/kill -HUP \$MAINPID
KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target
SVCEOF
systemctl daemon-reload
systemctl enable ndbd
systemctl start ndbd
systemctl status ndbd --no-pager
echo '>>> Data Node READY on '$(hostname)"

for IP in $DATA1_IP $DATA2_IP; do
  info "Setting up Data Node on $IP..."
  if [[ "$IP" == "$CURRENT_IP" ]]; then
    local_cmd "$DATA_CMD"
  else
    ssh_cmd "$IP" "$DATA_CMD"
  fi
  ok "Data Node ready on $IP"
done

info "Waiting 15 seconds for data nodes to sync..."
sleep 15

# =============================================================================
# STEP 6 — Setup SQL Nodes on ams-vm-4 and ams-vm-5
# =============================================================================
log "STEP 6 — Setting up SQL Nodes ($SQL1_HOST and $SQL2_HOST)"

SQL_CMD="dnf install -y mysql-cluster-community-server
cat > /etc/my.cnf << 'CNFEOF'
[mysqld]
ndbcluster
ndb-connectstring=ams-vm-1
bind-address=0.0.0.0

[mysql_cluster]
ndb-connectstring=ams-vm-1
CNFEOF
systemctl enable mysqld
systemctl start mysqld
sleep 10
TEMP_PASS=\$(grep 'temporary password' /var/log/mysqld.log | awk '{print \$NF}' | tail -1)
echo \"Temp password found: \$TEMP_PASS\"
mysql --connect-expired-password -uroot -p\"\$TEMP_PASS\" -e \"
ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';
CREATE DATABASE IF NOT EXISTS ams_db;
CREATE USER IF NOT EXISTS 'ams_user'@'%' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';
GRANT ALL PRIVILEGES ON ams_db.* TO 'ams_user'@'%';
FLUSH PRIVILEGES;\"
echo '>>> SQL Node READY on '$(hostname)
mysql -uroot -p\"$MYSQL_ROOT_PASSWORD\" -e 'SELECT VERSION();'"

for IP in $SQL1_IP $SQL2_IP; do
  info "Setting up SQL Node on $IP..."
  if [[ "$IP" == "$CURRENT_IP" ]]; then
    local_cmd "$SQL_CMD"
  else
    ssh_cmd "$IP" "$SQL_CMD"
  fi
  ok "SQL Node ready on $IP"
done

# =============================================================================
# STEP 7 — Verify cluster from Management Node
# =============================================================================
log "STEP 7 — Verifying cluster status"

VERIFY_CMD="ndb_mgm -e 'show'"
if [[ "$MGMT_IP" == "$CURRENT_IP" ]]; then
  local_cmd "$VERIFY_CMD"
else
  ssh_cmd "$MGMT_IP" "$VERIFY_CMD"
fi

# =============================================================================
# STEP 8 — Test replication between SQL Node 1 and SQL Node 2
# =============================================================================
log "STEP 8 — Testing NDB replication"

info "Writing test data on $SQL1_HOST ($SQL1_IP)..."
WRITE_CMD="mysql -uroot -p\"$MYSQL_ROOT_PASSWORD\" -e \"
CREATE DATABASE IF NOT EXISTS test_cluster;
USE test_cluster;
CREATE TABLE IF NOT EXISTS ndb_test (
  id INT AUTO_INCREMENT PRIMARY KEY,
  message VARCHAR(100),
  node VARCHAR(20),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=NDBCLUSTER;
INSERT INTO ndb_test (message, node) VALUES ('Hello from ams-vm-4', 'sql-node-1');
INSERT INTO ndb_test (message, node) VALUES ('NDB Cluster working!', 'sql-node-1');
SELECT * FROM ndb_test;\""

if [[ "$SQL1_IP" == "$CURRENT_IP" ]]; then
  local_cmd "$WRITE_CMD"
else
  ssh_cmd "$SQL1_IP" "$WRITE_CMD"
fi

info "Reading data on $SQL2_HOST ($SQL2_IP) to confirm replication..."
READ_CMD="mysql -uroot -p\"$MYSQL_ROOT_PASSWORD\" -e \"USE test_cluster; SELECT * FROM ndb_test;\""
if [[ "$SQL2_IP" == "$CURRENT_IP" ]]; then
  local_cmd "$READ_CMD"
else
  ssh_cmd "$SQL2_IP" "$READ_CMD"
fi

# =============================================================================
# DONE
# =============================================================================
echo ""
echo "================================================================"
echo "  MySQL NDB Cluster Setup COMPLETE"
echo "================================================================"
echo ""
echo "  Node        IP          Role"
echo "  ams-vm-1   $MGMT_IP   Management Node  (ndb_mgmd)"
echo "  ams-vm-2   $DATA1_IP  Data Node 1      (ndbd)"
echo "  ams-vm-3   $DATA2_IP  Data Node 2      (ndbd)"
echo "  ams-vm-4   $SQL1_IP   SQL Node 1       (mysqld)"
echo "  ams-vm-5   $SQL2_IP   SQL Node 2       (mysqld)"
echo ""
echo "  MySQL Root Password : $MYSQL_ROOT_PASSWORD"
echo "  Database            : ams_db"
echo "  App User            : ams_user"
echo ""
echo "  Check cluster:     sudo ndb_mgm -e 'show'    (from ams-vm-1)"
echo "  Startup order  :   ndb_mgmd → ndbd → mysqld"
echo "  Shutdown order :   stop mysqld → ndb_mgm -e SHUTDOWN"
echo "================================================================"
