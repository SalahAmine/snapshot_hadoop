# snapshot_hbase
snapshot_hbase is intended for backuping hbase tables, restauring tables
and applying a retention policy on backups.
It uses the snapshot feature offered by hbase

It is divided into two main scripts :

```
 ./bin/core/hbase_backup_admin_operations.bash 

  Admin  utility script for managing HDFS snapnshots
  MUST BE RUN WITH HADOOP SUPERUSER PRIVILEGES

        ## allow snapshot on a directory: ADMIN ONLY action
        allow_snapshot <dir>
        ## disallow snapshot on a directory
        disallow_snapshot <dir>
        ## list all  snapshottable directories for all users
        list_snapshottable_dirs
        ## usage guide
        usage

```
this script is to be launched by hbase admin (hbase by default ) to perform
admin operations for managing HBase snapnshots

```
./bin/core/hbase_backup_user_operations.bash

 User utility script for managing HDFS snapnshots
    ## list all the snapshot directories availalble for user $user
    list_snapshottable_dirs
    ## creates a snapshot for a directory,user vagrant must be owner of this directory
    create_snapshot <dir> [snapshot_name]
    ## list all  availalble snapnshots for a directory
    list_all_snapshots <dir>
    ## apply retention policy on snapshotted directories
    hdfs_check_and_apply_retention <dir> [number_of_snapshot_copies_to_retain :7 by default]
    ## usage guide
    usage

```
this script is intended for snapshot user operations. it allows to perform
taks like  creating snapshots
this script can either be launched by the user owner of the directory
or the hbase SUPERUSER. If the responsibility of backup is delegated entirely
to the admin, launch it as hbase admin



Retaled environment variables are to be declared under conf/env.bash
