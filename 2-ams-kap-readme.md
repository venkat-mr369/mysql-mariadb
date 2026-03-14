Here's your shell script. To run it from GCP Cloud Shell:

```bash
# Step 1 — Upload the file via Cloud Shell (click the 3-dot menu → Upload)
# OR paste contents directly into a file:
vi ndb_cluster_setup.sh   # paste and save

# Step 2 — Make it executable
chmod +x ndb_cluster_setup.sh

# Step 3 — Run it
./ndb_cluster_setup.sh
```

**What the script does in order:**

| Step | Action | VMs |
|---|---|---|
| 0 | Sets GCP project | Cloud Shell |
| 1 | Updates `/etc/hosts` with all IPs | All 5 VMs |
| 2 | Adds MySQL Cluster 8.0 repo | All 5 VMs |
| 3 | Opens ports 1186, 2202, 3306 via firewalld | All 5 VMs |
| 4 | Installs `ndb_mgmd` + writes `config.ini` + systemd | ams-vm-1 |
| 5 | Installs `ndbd` + systemd service | ams-vm-2, ams-vm-3 |
| 6 | Installs `mysqld` + resets password + creates DB | ams-vm-4, ams-vm-5 |
| 7 | Verifies all 5 nodes via `ndb_mgm show` | ams-vm-1 |
| 8 | Insert on vm-4, verify replication on vm-5 | ams-vm-4, ams-vm-5 |
