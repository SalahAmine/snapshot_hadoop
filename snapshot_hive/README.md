# snapshot_hive
snapshot_hive is intended for backuping hive tables and applying a retention policy on backups
It depends on the snapshot_hdfs projetcs because the data is snapshotted
using the hdfs snapshot feature

## STRATEGY
a backup constists of
     1-backup schema into output/<hive_db_name>.<hive_table_name>.<SNAPSHOT_NAME>
     2-bachkup of data table ( using hdfs snapshot mechanism ) under the table location/.snapshot in hdfs  with the same <SNAPSHOT_NAME>

```
./bin/core/hive_backup_operations.bash

     utility script for backuping hive tables and applying a retention policy on backups

     STRATEGY: a backup constists of
     1-backup schema into output/<hive_db_name>.<hive_table_name>.<SNAPSHOT_NAME>
     2-bachkup of data table ( using hdfs snapshot mechanism ) under the table location  with the same <SNAPSHOT_NAME>


   MUST BE RUN WITH TABLE OWNER PRIVILEGES

         ## backup an hive table
         backup_table <hive_db_name> <hive_table_name>

         backup_table_check_and_apply_retention <hive_db_name> <hive_table_name> <nb_copies_to_retain>
         ## usage guide
         usage


```

this script is to be launched by hadoop SUPERUSER (hdfs by default ) to perform
a backup on table and apply a retention policy on that backup


Retaled environment variables are to be declared under conf/env.bash


snapshot_hive does not expose a restauring functionality.

## To perform a restauration on a table

### Restaure data (table schema has not changed):
-remove the corrupted data ( or partition in cas of partionned table ) by the desired snapshot under <hdfs_location_of_data>/.snapshots
-on hive  perform an update the hive metastore
  "set hive.msck.path.validation =skip;  MSCK REPAIR TABLE <table_name> ;"

### Restaure data (table schema has changed):
-delete the hive table + data ( if not a managed table )
-recreate the schema by executing the DDL_scehama of the table backed
up in output/ directory
-copy the snapshot having the same timestamp under the LOCATION of the hive table 
-on hive  perform an update the hive metastore
  "set hive.msck.path.validation =skip;  MSCK REPAIR TABLE <table_name> ;"
