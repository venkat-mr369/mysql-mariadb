✅ Step-by-Step Galera Cluster Setup on Oracle Linux 9.5
This guide sets up a 4-node Galera Cluster using MariaDB on Oracle Linux 9.5.

📌 1️⃣ Prerequisites
1.1 Update & Disable SELinux
Run this on all nodes (server1, server2, server3, server4):
sudo dnf update -y
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config

1.2 Configure Firewall
Allow MySQL (3306), Galera (4567, 4568, 4444):
sudo firewall-cmd --permanent --add-port={3306,4444,4567,4568}/tcp
sudo firewall-cmd --permanent --add-port=4567/udp
sudo firewall-cmd --reload

1.3 Configure Hostnames
Edit /etc/hosts on all nodes:
192.168.17.101  server1
192.168.17.102  server2
192.168.17.103  server3
192.168.17.104  server4


📌 2️⃣ Install MariaDB & Galera
Run on all nodes:
sudo dnf install -y mariadb-server galera-4


📌 3️⃣ Create Galera Config File
Edit /etc/my.cnf.d/galera.cnf on all nodes:
[mysqld]
binlog_format=ROW
default-storage-engine=InnoDB
innodb_autoinc_lock_mode=2
bind-address=0.0.0.0

# Galera settings
wsrep_on=ON
wsrep_provider=/usr/lib64/galera-4/libgalera_smm.so
wsrep_cluster_name="my_galera_cluster"
wsrep_cluster_address="gcomm://192.168.17.101,192.168.17.102,192.168.17.103,192.168.17.104"
wsrep_node_name=$(hostname)
wsrep_node_address="$(hostname -I | awk '{print $1}')"

# Galera User
wsrep_sst_method=rsync
wsrep_sst_auth=galera_user:galera_pass


📌 4️⃣ Create Galera User
Run on server1:
sudo systemctl start mariadb
sudo mysql_secure_installation

Then, create the Galera user:
CREATE USER 'galera_user'@'%' IDENTIFIED BY 'galera_pass';
GRANT ALL PRIVILEGES ON *.* TO 'galera_user'@'%' IDENTIFIED BY 'galera_pass';
FLUSH PRIVILEGES;


📌 5️⃣ Start the Cluster
5.1 Bootstrap First Node (server1)
sudo galera_new_cluster

Verify with:
mysql -u root -p -e "SHOW STATUS LIKE 'wsrep_cluster_size';"

It should show 1.
5.2 Start MariaDB on Other Nodes
Run on server2, server3, server4:
sudo systemctl start mariadb

5.3 Verify Cluster
Run on any node:
mysql -u root -p -e "SHOW STATUS LIKE 'wsrep_cluster_size';"

Expected output:
+--------------------+-------+
| Variable_name      | Value |
+--------------------+-------+
| wsrep_cluster_size| 4     |
+--------------------+-------+


🎉 Galera Cluster is Now Up & Running!
=====================================
Here are some additional configurations for your Galera Cluster on Oracle Linux 9.5 to improve failover, monitoring, and backups.

📌 1️⃣ Automatic Failover with HAProxy
Since Galera allows multi-master writes, we need HAProxy to ensure that clients connect to the available node.
1.1 Install HAProxy on a Separate Node
Pick a node to act as the HAProxy load balancer (or install it on all nodes for redundancy).
sudo dnf install -y haproxy

1.2 Configure HAProxy for Galera
Edit /etc/haproxy/haproxy.cfg:
global
    log /dev/log local0
    log /dev/log local1 notice
    maxconn 4096
    daemon

defaults
    log global
    timeout connect 10s
    timeout client 1m
    timeout server 1m

frontend mysql_front
    bind *:3306
    mode tcp
    default_backend galera_cluster

backend galera_cluster
    mode tcp
    balance roundrobin
    option tcp-check
    default-server inter 3s downinter 5s rise 2 fall 3

    server server1 192.168.17.101:3306 check
    server server2 192.168.17.102:3306 check
    server server3 192.168.17.103:3306 check
    server server4 192.168.17.104:3306 check

1.3 Restart HAProxy
sudo systemctl enable --now haproxy
sudo systemctl restart haproxy


📌 2️⃣ Monitoring Galera Cluster
Use Percona Monitoring and Management (PMM) or Grafana with Prometheus for real-time metrics.
2.1 Install galera-healthcheck
sudo dnf install -y xinetd
sudo systemctl enable --now xinetd

Create /etc/xinetd.d/mysqlchk:
service mysqlchk
{
    disable         = no
    flags           = REUSE
    socket_type     = stream
    port            = 9200
    wait            = no
    user            = nobody
    server          = /usr/bin/clustercheck
    log_on_failure  += USERID
    only_from       = 0.0.0.0/0
}

Restart xinetd:
sudo systemctl restart xinetd

Now, you can monitor Galera with:
curl http://192.168.17.101:9200

Expected output:
HTTP/1.1 200 OK


📌 3️⃣ Backup Strategy
Use Percona XtraBackup for hot backups without stopping the cluster.
3.1 Install Percona XtraBackup
sudo dnf install -y percona-xtrabackup-80

3.2 Run Backup
xtrabackup --backup --target-dir=/backups/galera

3.3 Restore Backup
xtrabackup --prepare --target-dir=/backups/galera
xtrabackup --copy-back --target-dir=/backups/galera
sudo systemctl restart mariadb


✅ Final Checks

Failover: If a node goes down, HAProxy automatically switches to a healthy node.
Monitoring: Use curl or Grafana to monitor node status.
Backup: Set up Percona XtraBackup for automated backups.

========= automated failover scripts or a detailed Grafana setup? 🚀
I'll provide a detailed guide on setting up automated failover and Grafana monitoring for your Galera Cluster on Oracle Linux 9.5.

🚀 Automating Failover & Setting Up Grafana Monitoring for Galera Cluster on Oracle Linux 9.5
📌 1️⃣ Automating Failover with Keepalived & HAProxy
To ensure automatic failover, we'll use:
✅ HAProxy for load balancing between Galera nodes
✅ Keepalived for managing a Virtual IP (VIP) that fails over to a healthy node
1.1 Install Keepalived & HAProxy
Run the following on all Galera nodes:
sudo dnf install -y keepalived haproxy


1.2 Configure HAProxy
Edit /etc/haproxy/haproxy.cfg:
global
    log /dev/log local0
    maxconn 4096
    daemon

defaults
    log global
    timeout connect 10s
    timeout client 1m
    timeout server 1m

frontend mysql_front
    bind *:3306
    mode tcp
    default_backend galera_cluster

backend galera_cluster
    mode tcp
    balance leastconn
    option tcp-check
    default-server inter 3s downinter 5s rise 2 fall 3

    server server1 192.168.17.101:3306 check
    server server2 192.168.17.102:3306 check
    server server3 192.168.17.103:3306 check
    server server4 192.168.17.104:3306 check

Restart HAProxy:
sudo systemctl enable --now haproxy


1.3 Configure Keepalived
On server1 (Primary Node), edit /etc/keepalived/keepalived.conf:
vrrp_instance VI_1 {
    state MASTER
    interface ens192  # Change based on `ip a` output
    virtual_router_id 51
    priority 200
    advert_int 1

    authentication {
        auth_type PASS
        auth_pass mysecurepass
    }

    virtual_ipaddress {
        192.168.17.200
    }
}

On server2, server3, and server4 (Backup Nodes), change state MASTER to BACKUP and priority 200 to 100.
Restart Keepalived:
sudo systemctl enable --now keepalived

✅ Now, if the primary fails, the VIP (192.168.17.200) moves to another node automatically!

📌 2️⃣ Setting Up Grafana Monitoring
We’ll use Prometheus and Percona Exporter to monitor Galera metrics.
2.1 Install Prometheus
sudo dnf install -y prometheus

Edit /etc/prometheus/prometheus.yml:
global:
  scrape_interval: 5s

scrape_configs:
  - job_name: 'galera'
    static_configs:
      - targets: ['192.168.17.101:9104', '192.168.17.102:9104', '192.168.17.103:9104']

Start Prometheus:
sudo systemctl enable --now prometheus


2.2 Install Percona MySQL Exporter on Each Galera Node
sudo dnf install -y percona-toolkit

Start the exporter:
nohup mysqld_exporter --config.my-cnf=/etc/mysql/my.cnf --collect.global_status > /var/log/mysql_exporter.log 2>&1 &

Now, Prometheus can collect Galera metrics!

2.3 Install Grafana
sudo dnf install -y grafana
sudo systemctl enable --now grafana-server


Login to Grafana (http://your-server-ip:3000)
Add Data Source → Choose Prometheus → Enter http://192.168.17.101:9090
Import Galera Dashboard: Use Percona Galera Cluster Dashboard (ID: 12172)

✅ Now, you have a live Grafana dashboard monitoring your Galera Cluster!

🎯 Final Checks

Failover works: Run systemctl stop keepalived on the master, and the VIP should move to a backup node.
Monitoring active: Open Grafana and check if metrics are displayed.

Would you like me to add automatic failover testing scripts or backup automation? 🚀
