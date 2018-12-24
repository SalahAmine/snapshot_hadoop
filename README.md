# snapshot_hadoop_API
This project is aimed to expose wrapper APIs to make snapshotting, restoring, recovering and applying retention policy of data in Hadoop easier. 

There are 3 main APIs:
## snapshot_HDFS 
relies on [hdfs snapshots](https://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-hdfs/HdfsSnapshots.html)

* [README.md](https://github.com/SalahAmine/snapshot_hadoop_API/blob/master/snapshot_hdfs/README.md) 
## snapshot_hive
enables to extract hive DDL + relies on snapshot_HDFS API to snapshot data.

* [README.md](https://github.com/SalahAmine/snapshot_hadoop_API/blob/master/snapshot_hive/README.md) 
## snapshot_hbase 
relies on [hbase snapshot](https://blog.cloudera.com/blog/2013/03/introduction-to-apache-hbase-snapshots/) 

* [README.md](https://github.com/SalahAmine/snapshot_hadoop_API/edit/master/snapshot_hbase/README.md) 

## Authors
 S.A SELLAMI
