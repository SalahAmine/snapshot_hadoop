# snapshot_hadoop_API
This project is aimed to expose wrapper APIs to make snapshotting, restoring, recovering and applying retention policy of data in Hadoop easier. 
There are 3 main APIs: 
-snapshot_HDFS : uses hdfs snapshots under the hood ( See: https://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-hdfs/HdfsSnapshots.html )
-snapshot_hive: enables to extract hive DDL + relies on snapshot_HDFS API to snapshot data.
-snapshot_hbase: uses hbase snapshot under the hood ( See https://blog.cloudera.com/blog/2013/03/introduction-to-apache-hbase-snapshots/) 
