snapshot hive is intended for backuping hive tables and applying a retention policy on backups

STRATEGY: a backup constists of
1-backup schema into output/<hive_db_name>.<hive_table_name>.<SNAPSHOT_NAME>
2-bachkup of data table ( using hdfs snapshot mechanism ) under the table location/.snapshot
in hdfs  with the same <SNAPSHOT_NAME>


hive_backup_operations.bash

this script is to be launched by hadoop SUPERUSER (hdfs by default ) to perform
a backup on table and apply a retention policy on that backup


Retaled environment variables are to be declared under conf/env.bash
