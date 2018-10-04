#!/usr/bin/env bash

 # set -o errexit   # abort on nonzero exitstatus
 # set -o nounset   # abort on unbound variable
 set -o pipefail  # don't hide errors within pipes

usage() {
     cat <<- EOF

   Admin  utility script for managing HDFS snapnshots
   MUST BE RUN WITH HADOOP SUPERUSER PRIVILEGES

         ## extracts schema of table
         extract_table_DDL <hive_db_name> <hive_table_name>
         ##
         DDL_check_and_apply_retention <dir>
         ## usage guide
         usage

EOF
}

## private  functions

check_table_exists() {

  [[ $# -eq 2 ]]  ||  { usage  ; exit 1 ;}
  # check table existence
  ${BEELINE} -e \
  "describe  $1.$2 ;"  >/dev/null
  [[ $? -eq 0 ]] || { echo "ERROR checking existence of table $1.$2" ; exit 1 ; }

}


## public functions
backup_hive_table() {
  echo "$FUNCNAME"
  # check
  [[ $# -eq 2 ]]  ||   { usage  ; exit 1 ;}

backup_table_schema $1 $2

backup_table_data $1 $2


}

backup_table_schema () {
  echo "$FUNCNAME"
  # check
  [[ $# -eq 2 ]]  ||   { usage  ; exit 1 ;}
  local hive_db_name=$1
  local hive_table_name=$2

  SCHEMA_DDL_FILE="${hive_db_name}.${hive_table_name}.${snapshot_name}.hql"

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

}


backup_table_data() {
  echo "$FUNCNAME"
  # check
  [[ $# -eq 2 ]]  ||   { usage  ; exit 1 ;}
  local hive_db_name=$1
  local hive_table_name=$2

  echo "INFO: Taking a snapshot of the table ${hive_db_name}.${hive_table_name}"

  table_absolute_path=$(cat ${project_dir}/output/${SCHEMA_DDL_FILE} | egrep "^LOCATION$" -A 1 |  egrep -v  "^LOCATION$" | tr -d "'" )
  table_relative_path=$(echo ${table_absolute_path} | sed -E 's#hdfs://([^/]+)*##')
  # create hdfs snapshot for the table
  ${project_dir}/../snapshot_hdfs/bin/core/hdfs_backup_user_operations.bash create_snapshot ${table_relative_path} ${snapshot_name}

  [[  $? -eq 0 ]] || \
  { echo "ERROR: while taking  snapshot for table ${hive_db_name}.${hive_table_name}  " ; exit 1 ;}

}


hive_check_and_apply_retention() {

  [[ $# -eq 2 || $# -eq 3  ]]  || { echo "ERROR: usage" && exit 1 ;}

  hive_db_name=$1
  hive_table_name=$2
  DDL_check_and_apply_retention ${hive_db_name} ${hive_table_name}

}


DDL_check_and_apply_retention() {

  local nb_DDL_snapshots_to_retain=$3
  [[ -z ${nb_DDL_snapshots_to_retain} ]] && nb_DDL_snapshots_to_retain=${DEFAULT_NB_DDL_SNAPSHOTS} && \
  echo "INFO number of DDL snapshots to retain not set, applying default retention=${DEFAULT_NB_DDL_SNAPSHOTS}"

  ## list of existing schema snapshots for a table in a chronological order
  local arr_existing_DDL_snapshots=( $(ls -tr  ${project_dir}/output/ | egrep "^${hive_db_name}.${hive_table_name}(.+).hql$" ) )
  local nb_existing_DDL_snapshots=${#arr_existing_DDL_snapshots[@]}

  # core
  if [[ ${nb_existing_DDL_snapshots} -gt ${nb_DDL_snapshots_to_retain} ]]; then

    local nb_DDL_snapshots_to_remove=$((nb_existing_DDL_snapshots - nb_DDL_snapshots_to_retain ))
    local arr_DDL_snapshots_to_remove=( ${arr_existing_DDL_snapshots[@]:0:$nb_DDL_snapshots_to_remove} )

    for DDL_snap_to_remove in ${arr_DDL_snapshots_to_remove[@]}; do
      rm -f  ${project_dir}/output/${DDL_snap_to_remove}
    done

  else
    echo "INFO no additional DDL snapnshots to remove, ${nb_existing_DDL_snapshots} DDL snapnshots exists for table ${hive_db_name}.${hive_table_name}  "
  fi

  echo "INFO list of existing_DDL_snapshots"
  echo "$(ls -tr  ${project_dir}/output/ | egrep "^${hive_db_name}.${hive_table_name}(.+).hql$"  | xargs -I {} ls -tr  ${project_dir}/output/{} ) "

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
#extract_table_DDL $@
DDL_check_and_apply_retention $@
# cat ${project_root_dir}/output/${SCHEMA_DDL_FILE}
