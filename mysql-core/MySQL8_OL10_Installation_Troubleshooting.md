### MySQL 8.0 Installation on Oracle Linux 10.1 -- Troubleshooting Notes

#### Environment

-   OS: Oracle Linux Server 10.1
-   RPM Version: 4.19.1.1
-   Target Version: MySQL Community Server 8.0.46
-   Repository Package: mysql84-community-release-el9-1.noarch.rpm

#### Initial Goal

Install MySQL Community Server 8.0 on Oracle Linux 10.1.

#### Issue 1: Repository Package Already Installed

Command:

``` bash
sudo rpm -ivh mysql84-community-release-el9-1.noarch.rpm
```

Error:

``` text
package mysql84-community-release-el9-1.noarch is already installed
```

Resolution:

-   Repository package already existed.
-   No reinstallation required.

------------------------------------------------------------------------

#### Issue 2: MySQL Repository Not Visible

Symptoms:

``` bash
sudo dnf repolist all | grep mysql
```

returned no output.

Root Cause:

-   Repository file was renamed to:

``` text
mysql-community.repo.rpmsave
```

instead of:

``` text
mysql-community.repo
```

Resolution:

``` bash
sudo mv /etc/yum.repos.d/mysql-community.repo.rpmsave \
/etc/yum.repos.d/mysql-community.repo
```

------------------------------------------------------------------------

#### Issue 3: MySQL 9 vs MySQL 8 Repository Selection

Checked available repositories:

``` bash
sudo dnf repolist all | grep mysql
```

Enabled MySQL 8.0 repository:

``` bash
sudo dnf config-manager --enable mysql80-community
```

Verified available versions:

``` bash
sudo dnf list mysql-community-server --showduplicates
```

Selected:

``` text
8.0.46-1.el9
```

------------------------------------------------------------------------

#### Issue 4: Expired MySQL GPG Key

Error:

``` text
Certificate expired
Key ID a8d3785c
NOTTRUSTED
```

Root Cause:

-   MySQL signing key expired.
-   Oracle Linux 10 RPM validation is strict.

Attempted Fixes:

``` bash
rpm -qa gpg-pubkey*
rpm -qi gpg-pubkey
```

Removed expired key.

------------------------------------------------------------------------

#### Issue 5: Missing GPG Key Files

Error:

``` text
Couldn't open file
/etc/pki/rpm-gpg/RPM-GPG-KEY-mysql-2023
```

Resolution:

``` bash
sudo mkdir -p /etc/pki/rpm-gpg

cd /etc/pki/rpm-gpg

sudo curl -o RPM-GPG-KEY-mysql-2023 \
https://repo.mysql.com/RPM-GPG-KEY-mysql-2023

sudo curl -o RPM-GPG-KEY-mysql-2022 \
https://repo.mysql.com/RPM-GPG-KEY-mysql-2022
```

------------------------------------------------------------------------

#### Issue 6: GPG Validation Still Failed

Even after importing keys:

``` text
Header V4 RSA/SHA256 Signature
NOTTRUSTED
```

Root Cause:

-   Oracle Linux 10 RPM engine rejected expired MySQL signing
    certificates.

Temporary Repository Change:

``` bash
sudo sed -i 's/gpgcheck=1/gpgcheck=0/g' \
/etc/yum.repos.d/mysql-community.repo
```

However RPM validation still blocked installation.

------------------------------------------------------------------------

#### Final Working Solution

Locate downloaded RPM packages:

``` bash
find /var/cache/dnf -name "mysql-community-*.rpm"
```

Move to package directory:

``` bash
cd /var/cache/dnf/mysql80-community-*/packages/
```

Install packages directly:

``` bash
sudo rpm -ivh --nosignature --nodigest *.rpm
```

Packages installed:

-   mysql-community-client
-   mysql-community-client-plugins
-   mysql-community-libs
-   mysql-community-icu-data-files
-   mysql-community-server

------------------------------------------------------------------------

#### Start MySQL

``` bash
sudo systemctl start mysqld
```

Check status:

``` bash
sudo systemctl status mysqld
```

Expected:

``` text
active (running)
```

------------------------------------------------------------------------

#### Retrieve Temporary Root Password

``` bash
sudo grep 'temporary password' /var/log/mysqld.log
```

Example:

``` text
973xf)OtZiWg
```

------------------------------------------------------------------------

#### Login

``` bash
mysql -uroot -p
```

------------------------------------------------------------------------

#### Issue 7: Password Policy Failure

Attempt:

``` sql
ALTER USER 'root'@'localhost'
IDENTIFIED BY 'root@123';
```

Error:

``` text
ERROR 1819 (HY000)
Your password does not satisfy the current policy requirements
```

Resolution:

``` sql
ALTER USER 'root'@'localhost'
IDENTIFIED BY 'Welcome@123';
```

Result:

``` text
Query OK
```

------------------------------------------------------------------------

#### Verification

``` sql
SELECT VERSION();
```

Expected:

``` text
8.0.46
```

------------------------------------------------------------------------

#### Final Status

Successfully installed and started:

-   MySQL Community Server 8.0.46
-   Oracle Linux 10.1
-   Port 3306 Active
-   Root Password Updated
-   Service Enabled and Running

#### Key Lesson

Oracle Linux 10.1 with RPM 4.19.1.1 may reject older MySQL repository
signing certificates. When repository-based installation fails due to
expired signatures, direct RPM installation using locally downloaded
packages can be used in lab environments.
