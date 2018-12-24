# snapshot_hdfs
snapshot_hdfs is a wrapper tool of hdfs snapshot functionality.
It uses the hdfs snapshot feature.
It is divided into two main scripts :

hdfs_backup_admin_operations.bash

this script is to be launched by hadoop SUPERUSER (hdfs by default ) to perform
related snapshot tasks: allow snapshot , disallow snapshot and  list
all snapshottable directories for all users

hdfs_backup_user_operations.bash

this script is intended for snapshot user operations. it allows to perform
taks like  creating snapshots, listing all available snapshots for a user
and applying retention policy on snapshots.
this script can either be launched by the user owner of the directory
or the hadoop SUPERUSER. If the responsibility of backup is delegated entirely
to the admin, launch it as hadoop SUPERUSER



Retaled environment variables are to be declared under conf/env.bash
