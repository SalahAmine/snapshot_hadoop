#!/usr/bin/env bash

 # set -o errexit   # abort on nonzero exitstatus
 # set -o nounset   # abort on unbound variable
 set -o pipefail  # don't hide errors within pipes

TERMINATE=";"
BEELINE="beeline -u jdbc:hive2://sandbox-hdp.hortonworks.com:2181/;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=hiveserver2
--showHeader=false --outputformat=tsv2 "


extract_table_DDL () {
  echo "$FUNCNAME"

  # check
  [[ $# -eq 2 ]]  || \
  { echo "ERROR usage " ; exit 1 ;}

  hive_db_name=$1
  [[ -z ${hive_db_name} ]] && hive_db_name="default"
  hive_table_name=$2
  [[ -z ${hive_table_name} ]] && hive_table_name="managedpartitioned"

  SCHEMA_DDL_FILE="${hive_db_name}.${hive_table_name}_extract_table_creation_DDL.hql"

  #clean up
  rm  -fr ${SCHEMA_DDL_FILE}

  # extract schema
   ${BEELINE} -e \
    "show create table ${hive_db_name}.${hive_table_name} ${TERMINATE}" \
    >>  ${SCHEMA_DDL_FILE}
    [[  $? -eq 0 ]] || { echo "ERROR" ; exit ;}

     echo ${TERMINATE} >>  ${SCHEMA_DDL_FILE}

  # extract partitions DDL if any
  listpartitions=$( ${BEELINE} -e "show partitions ${hive_db_name}.${hive_table_name} ;" 2> /dev/null )
    [[  $? -eq 0 ]] || {  exit 0 ;}

  for tablepart in ${listpartitions}
     do
        local partname=`echo ${tablepart/=/=\"}`
        echo $partname
        echo "ALTER TABLE ${hive_table_name} ADD PARTITION ($partname\");" \
         >> ${SCHEMA_DDL_FILE}
     done

  echo "TABLE ${hive_db_name}.${hive_table_name} created in ${SCHEMA_DDL_FILE}"

  echo "table data saved by snapshott mecanism"
  table_location=$( cat ${SCHEMA_DDL_FILE} | egrep "^LOCATION$" -A 1 |  egrep -v  "^LOCATION$")


}


save_table_data () {


}

# restauration process is better to be done manually
restore_table () {
  # args : db , tab, version ?

  # check if schema has changed
  # remove data in current location and change it by the availalble versions
  hdfs dfs -rm -r /tmp/ManagedPartitioned/*
  hdfs dfs -cp -f   hdfs://sandbox-hdp.hortonworks.com:8020/tmp/ManagedPartitioned/.snapshot/s20181001-193740.263/*   hdfs://sandbox-hdp.hortonworks.com:8020/tmp/ManagedPartitioned/
  #!!! in case of managed table the snamshots are crated by the owner ( =hive ) or superuser
  # if table is partitionned, a manual add of partitions requires the refresh of metadata
  MSCK REPAIR TABLE t1;
}


# save_table_creation $@
extract_table_DDL $@

cat ${SCHEMA_DDL_FILE}

save_table_data
