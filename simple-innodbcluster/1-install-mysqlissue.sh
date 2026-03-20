```sh
[venkat@oel9-vm3 ~]$ sudo dnf install -y https://dev.mysql.com/get/mysql80-community-release-el9-1.noarch.rpm

sudo dnf install -y mysql-community-server
Last metadata expiration check: 0:05:47 ago on Fri 20 Mar 2026 11:14:18 PM IST.
mysql80-community-release-el9-1.noarch.rpm                                                                       6.5 kB/s |  10 kB     00:01
Dependencies resolved.
=================================================================================================================================================
 Package                                        Architecture                Version                      Repository                         Size
=================================================================================================================================================
Installing:
 mysql80-community-release                      noarch                      el9-1                        @commandline                       10 k

Transaction Summary
=================================================================================================================================================
Install  1 Package

Total size: 10 k
Installed size: 5.7 k
Downloading Packages:
Running transaction check
Transaction check succeeded.
Running transaction test
Transaction test succeeded.
Running transaction
  Preparing        :                                                                                                                         1/1
  Installing       : mysql80-community-release-el9-1.noarch                                                                                  1/1
  Verifying        : mysql80-community-release-el9-1.noarch                                                                                  1/1

Installed:
  mysql80-community-release-el9-1.noarch

Complete!
MySQL 8.0 Community Server                                                                                       492 kB/s | 3.1 MB     00:06
MySQL Connectors Community                                                                                       152 kB/s | 106 kB     00:00
MySQL Tools Community                                                                                            1.5 MB/s | 1.4 MB     00:00
Last metadata expiration check: 0:00:01 ago on Fri 20 Mar 2026 11:20:21 PM IST.
Dependencies resolved.
=================================================================================================================================================
 Package                                         Architecture            Version                        Repository                          Size
=================================================================================================================================================
Installing:
 mysql-community-server                          x86_64                  8.0.45-1.el9                   mysql80-community                   50 M
Installing dependencies:
 mysql-community-client                          x86_64                  8.0.45-1.el9                   mysql80-community                  3.3 M
 mysql-community-client-plugins                  x86_64                  8.0.45-1.el9                   mysql80-community                  1.4 M
 mysql-community-common                          x86_64                  8.0.45-1.el9                   mysql80-community                  556 k
 mysql-community-icu-data-files                  x86_64                  8.0.45-1.el9                   mysql80-community                  2.3 M
 mysql-community-libs                            x86_64                  8.0.45-1.el9                   mysql80-community                  1.5 M

Transaction Summary
=================================================================================================================================================
Install  6 Packages

Total download size: 59 M
Installed size: 337 M
Downloading Packages:
(1/6): mysql-community-common-8.0.45-1.el9.x86_64.rpm                                                            404 kB/s | 556 kB     00:01
(2/6): mysql-community-client-plugins-8.0.45-1.el9.x86_64.rpm                                                    606 kB/s | 1.4 MB     00:02
(3/6): mysql-community-libs-8.0.45-1.el9.x86_64.rpm                                                              771 kB/s | 1.5 MB     00:01
(4/6): mysql-community-icu-data-files-8.0.45-1.el9.x86_64.rpm                                                    657 kB/s | 2.3 MB     00:03
(5/6): mysql-community-client-8.0.45-1.el9.x86_64.rpm                                                            484 kB/s | 3.3 MB     00:06
(6/6): mysql-community-server-8.0.45-1.el9.x86_64.rpm                                                            1.5 MB/s |  50 MB     00:32
-------------------------------------------------------------------------------------------------------------------------------------------------
Total                                                                                                            1.6 MB/s |  59 MB     00:37
MySQL 8.0 Community Server                                                                                       3.0 MB/s | 3.1 kB     00:00
Importing GPG key 0x3A79BD29:
 Userid     : "MySQL Release Engineering <mysql-build@oss.oracle.com>"
 Fingerprint: 859B E8D7 C586 F538 430B 19C2 467B 942D 3A79 BD29
 From       : /etc/pki/rpm-gpg/RPM-GPG-KEY-mysql-2022
Key imported successfully
Import of key(s) didn't help, wrong key(s)?
Public key for mysql-community-client-8.0.45-1.el9.x86_64.rpm is not installed. Failing package is: mysql-community-client-8.0.45-1.el9.x86_64
 GPG Keys are configured as: file:///etc/pki/rpm-gpg/RPM-GPG-KEY-mysql-2022
Public key for mysql-community-client-plugins-8.0.45-1.el9.x86_64.rpm is not installed. Failing package is: mysql-community-client-plugins-8.0.45-1.el9.x86_64
 GPG Keys are configured as: file:///etc/pki/rpm-gpg/RPM-GPG-KEY-mysql-2022
Public key for mysql-community-common-8.0.45-1.el9.x86_64.rpm is not installed. Failing package is: mysql-community-common-8.0.45-1.el9.x86_64
 GPG Keys are configured as: file:///etc/pki/rpm-gpg/RPM-GPG-KEY-mysql-2022
Public key for mysql-community-icu-data-files-8.0.45-1.el9.x86_64.rpm is not installed. Failing package is: mysql-community-icu-data-files-8.0.45-1.el9.x86_64
 GPG Keys are configured as: file:///etc/pki/rpm-gpg/RPM-GPG-KEY-mysql-2022
Public key for mysql-community-libs-8.0.45-1.el9.x86_64.rpm is not installed. Failing package is: mysql-community-libs-8.0.45-1.el9.x86_64
 GPG Keys are configured as: file:///etc/pki/rpm-gpg/RPM-GPG-KEY-mysql-2022
Public key for mysql-community-server-8.0.45-1.el9.x86_64.rpm is not installed. Failing package is: mysql-community-server-8.0.45-1.el9.x86_64
 GPG Keys are configured as: file:///etc/pki/rpm-gpg/RPM-GPG-KEY-mysql-2022
The downloaded packages were saved in cache until the next successful transaction.
You can remove cached packages by executing 'dnf clean packages'.
Error: GPG check FAILED
```
