#!/usr/bin/env bash


TERMINATE=";"
BEELINE="beeline -u 'jdbc:hive2://sandbox-hdp.hortonworks.com:2181/;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=hiveserver2' --showHeader=false --outputformat=tsv2  --silent"
