# snapshot_hbase
snapshot_hbase is intended for backuping hbase tables, restauring tables
and applying a retention policy on backups.
It uses the snapshot feature offered by hbase

It is divided into two main scripts :

```
 ./bin/core/hbase_backup_admin_operations.bash 

  Admin utility script for managing HBase snapnshots

    ## list all snapshots for a given table
    list_all_snapshots  <hbase_namespace> <hbase_table>
    ## restore a hbase table to  <snapshot_name>  state
    restore_table <hbase_namespace> <hbase_table> <snapshot_name>
    ## apply a retention policy on a table
    check_and_apply_retention <hbase_namespace> <hbase_table> [nb_snapshots_to_retain]
    ## delete snapshot by providing its name
    delete_snapshot <snapshot_name>
    ## usage guide
    usage


```
this script is to be launched by hbase admin (hbase by default ) to perform
admin operations for managing HBase snapnshots

```
./bin/core/hbase_backup_user_operations.bash
  User utility script for managing HBase snapnshots
  In case if using coprocessors only admin user is able to manage snapshots
    ## creates a snapshot for table <hbase_namespace>:<hbase_table>
    create_table_snapshot <hbase_namespace> <hbase_table>
    ## usage guide
    usage

```
this script is intended for snapshot user operations. it allows to perform
taks like  creating snapshots
this script can either be launched by the user owner of the directory
or the hbase SUPERUSER. If the responsibility of backup is delegated entirely
to the admin, launch it as hbase admin



Retaled environment variables are to be declared under conf/env.bash
