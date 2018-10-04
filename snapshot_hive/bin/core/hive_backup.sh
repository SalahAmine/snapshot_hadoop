#!/usr/bin/env bash

 # set -o errexit   # abort on nonzero exitstatus
 # set -o nounset   # abort on unbound variable
 set -o pipefail  # don't hide errors within pipes


readonly script_name=$(basename "${0}")
readonly script_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
readonly project_dir=$( readlink -f  ${script_dir}/../.. )

echo "script_name" $script_name
echo "script_dir" $script_dir
echo "project_dir" $project_dir
# source env variables
. ${project_dir}/conf/env.sh


extract_table_DDL () {
  echo "$FUNCNAME"

  # every_version of data & metadata is timestamped with $snapshot_name
  snapshot_name=$(echo  s`date +"%Y%m%d-%H%M%S.%3N"`)

  # check
  [[ $# -eq 2 ]]  || \
  { echo "ERROR usage " ; exit 1 ;}

  hive_db_name=$1
  [[ -z ${hive_db_name} ]] && hive_db_name="default"
  hive_table_name=$2
  [[ -z ${hive_table_name} ]] && hive_table_name="managedpartitioned"

  SCHEMA_DDL_FILE="${hive_db_name}.${hive_table_name}_${snapshot_name}.hql"


  echo "INFO: extracting schema for table ${hive_db_name}.${hive_table_name} "
  # extract schema
   ${BEELINE} -e \
    "show create table ${hive_db_name}.${hive_table_name} ${TERMINATE}" \
    >>  ${project_dir}/output/${SCHEMA_DDL_FILE}
    [[  $? -eq 0 ]] || { echo "ERROR" ; exit 1 ;}

     echo ${TERMINATE} >>  ${project_dir}/output/${SCHEMA_DDL_FILE}

  # extract partitions DDL if any
  listpartitions=$( ${BEELINE} -e "show partitions ${hive_db_name}.${hive_table_name} ;" 2> /dev/null )


  if [[  $? -eq 0 && ! -z ${listpartitions} ]]; then

    echo "INFO: table ${hive_table_name} is  a partionned table"
    echo "INFO: Extracting Partition DDL"

    for tablepart in ${listpartitions}
       do
          local partname=`echo ${tablepart/=/=\"}`
          echo $partname
          echo "ALTER TABLE ${hive_table_name} ADD PARTITION ($partname\");" \
           >> ${project_dir}/output/${SCHEMA_DDL_FILE}
       done
  fi
  echo "INFO: table ${hive_db_name}.${hive_table_name} created in ${project_dir}/output/${SCHEMA_DDL_FILE}"

  echo "INFO: Taking a snapshot of the table ${hive_db_name}.${hive_table_name}"

  table_absolute_path=$(cat ${project_dir}/output/${SCHEMA_DDL_FILE} | egrep "^LOCATION$" -A 1 |  egrep -v  "^LOCATION$" | tr -d "'" )
  table_relative_path=$(echo ${table_absolute_path} | sed -E 's#hdfs://([^/]+)*##')
  # create hdfs snapshot for the table
  ${project_dir}/../snapshot_hdfs/bin/core/hdfs_backup_user_operations.bash create_snapshot ${table_relative_path} ${snapshot_name}

  [[  $? -eq 0 ]] || \
  { echo "ERROR: while taking  snapshot for table ${hive_db_name}.${hive_table_name}  " ; exit 1 ;}


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

# cat ${project_root_dir}/output/${SCHEMA_DDL_FILE}
