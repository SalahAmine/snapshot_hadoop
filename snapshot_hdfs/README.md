# snapshot_hdfs
snapshot_hdfs is a wrapper tool of hdfs snapshot functionality.
It uses the hdfs snapshot feature.
It is divided into two main scripts :


```
./bin/core/hdfs_backup_admin_operations.bash

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

this script is to be launched by hadoop SUPERUSER (hdfs by default ) to perform
related snapshot tasks: allow snapshot , disallow snapshot and  list
all snapshottable directories for all users

```
./bin/core/hdfs_backup_user_operations.bash

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
taks like  creating snapshots, listing all available snapshots for a user
and applying retention policy on snapshots.
this script can either be launched by the user owner of the directory
or the hadoop SUPERUSER. If the responsibility of backup is delegated entirely
to the admin, launch it as hadoop SUPERUSER


Retaled environment variables are to be declared under conf/env.bash
