# snapshot_hbase
snapshot_hbase is intended for backuping hbase tables, restauring tables
and applying a retention policy on backups.
It uses the snapshot feature offered by hbase

It is divided into two main scripts :

```
bin/core/hbase_backup_admin_operations.bash
```
this script is to be launched by hbase admin (hbase by default ) to perform
admin operations for managing HBase snapnshots

```
bin/core/hbase_backup_user_operations.bash
```
this script is intended for snapshot user operations. it allows to perform
taks like  creating snapshots
this script can either be launched by the user owner of the directory
or the hbase SUPERUSER. If the responsibility of backup is delegated entirely
to the admin, launch it as hbase admin



Retaled environment variables are to be declared under conf/env.bash
