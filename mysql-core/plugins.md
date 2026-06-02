1. What is a Plugin?

Plugin = A software module that extends MySQL/MariaDB functionality without changing the database source code.

Example:

* InnoDB
* Audit Plugin
* Authentication Plugin
* Group Replication Plugin
* Validate Password Plugin

Think of a plugin like an app installed on your mobile.

Example:
WhatsApp = App
Audit Plugin = MySQL App

Document reference: Plugin is a modular component loaded into the server to add functionality. 

2. Why Plugins are Needed?

Without plugins:
MySQL can only do basic database operations.

With plugins:

* Authentication
* Audit logging
* Replication
* New storage engines
* Password validation
* Encryption

can be added without recompiling MySQL.

Interview Answer:
Plugins provide additional functionality without modifying MySQL server code.

3. Plugin Lifecycle (Most Important)

This is what your flowchart was trying to explain.

```text
Copy .so file
      |
      v
INSTALL PLUGIN
      |
      v
Plugin Loaded
      |
      v
plugin_init()
      |
      v
ACTIVE
      |
      v
UNINSTALL PLUGIN
      |
      v
plugin_deinit()
      |
      v
Plugin Removed
```

Example:

```sql
INSTALL PLUGIN validate_password
SONAME 'validate_password.so';
```

MySQL:

1. Loads validate_password.so
2. Executes plugin_init()
3. Plugin becomes ACTIVE

Later:

```sql
UNINSTALL PLUGIN validate_password;
```

MySQL:

1. Executes plugin_deinit()
2. Removes plugin
3. Unloads library

Document reference: Installation loads the library and initialization routine; uninstall calls deinitialization and removes it from mysql.plugin. 

4. Plugin Types You Must Know

Storage Engine Plugins

Examples:

* InnoDB
* MyISAM
* Aria (MariaDB)
* Spider (MariaDB)
* ColumnStore (MariaDB)

Authentication Plugins

Examples:

* mysql_native_password
* caching_sha2_password
* ed25519
* unix_socket

Audit Plugins

Examples:

* MySQL Enterprise Audit
* MariaDB server_audit

Replication Plugins

Examples:

* Group Replication (MySQL)
* Galera (MariaDB)

Password Plugins

Examples:

* validate_password
* simple_password_check

Interview Question:
What are common plugin types?

Answer:
Storage Engine, Authentication, Audit, Replication, Password Validation, and Encryption plugins.

5. MySQL vs MariaDB Plugin Differences

MySQL

* Group Replication
* MySQL Router
* X Plugin
* Enterprise Audit
* caching_sha2_password default

MariaDB

* Galera Cluster
* MaxScale
* server_audit (free)
* Aria Engine
* Spider Engine
* ColumnStore
* unix_socket auth

Easy Interview Table:

```text
MySQL                MariaDB
------               -------
Group Replication    Galera
Router               MaxScale
InnoDB               InnoDB + Aria
Enterprise Audit     Free Audit Plugin
caching_sha2         mysql_native_password
X Plugin             No X Plugin
```

Commands You Should Remember

Show plugins:

```sql
SHOW PLUGINS;
```

Information schema:

```sql
SELECT * FROM INFORMATION_SCHEMA.PLUGINS;
```

Install plugin:

```sql
INSTALL PLUGIN plugin_name
SONAME 'plugin.so';
```

Remove plugin:

```sql
UNINSTALL PLUGIN plugin_name;
```

Interview One-Liner:

"A plugin is a loadable module that extends MySQL or MariaDB functionality such as authentication, auditing, replication, encryption, or storage engines without modifying the database server code."

<img width="1242" height="1266" alt="ChatGPT Image Jun 2, 2026, 05_38_41 PM" src="https://github.com/user-attachments/assets/c2ca650d-e116-41cf-a75b-f855a6fce1fe" />

