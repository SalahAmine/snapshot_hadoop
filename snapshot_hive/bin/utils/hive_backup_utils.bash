usage() {
     cat <<- EOF

     utility script for backuping hive tables and applying a retention policy on backups

     STRATEGY: a backup constists of
     1-backup schema into output/<hive_db_name>.<hive_table_name>.<SNAPSHOT_NAME>
     2-bachkup of data table ( using hdfs snapshot mechanism ) under the table location  with the same ${SNAPSHOT_NAME}


   MUST BE RUN WITH TABLE OWNER PRIVILEGES

         ## backup an hive table
         backup_table <hive_db_name> <hive_table_name>

         backup_table_check_and_apply_retention <hive_db_name> <hive_table_name> <nb_copies_to_retain>
         ## usage guide
         usage

EOF
}


###############################
## private  functions
###############################

check_table_exists() {
  [[ $# -eq 2 ]]  ||  { usage  ; exit 1 ;}
  # check table existence
  if ! ${BEELINE} -e  "describe  $1.$2 ;"  >/dev/null ; then
    { echo "${FUNCNAME[0]}: ERROR checking existence of table $1.$2" ; exit 1 ; }
  fi
}

is_strictly_positive_integer() {
    { [[ $# -eq 1 ]] && [[ "$1" =~ ^[0-9]+$ ]] && [[ $1 -gt 0 ]] ;}  || \
    { error "${FUNCNAME[0]}: $1 must be a valid integer and > 0" ; exit 1 ;}
}

get_table_relative_location() {

  local table_absolute_path
  if ! table_absolute_path=$( ${BEELINE} -e "show create table $1.$2 ${TERMINATE}" | \
    grep -E "^LOCATION$" -A 1 |  grep -E -v  "^LOCATION$" | tr -d "'"); then
    { echo "${FUNCNAME[0]}: ERROR while seraching HDFS LOCATION for table $1.$2  " ; exit 1 ;}
  fi
  local table_relative_path
  table_relative_path=$(echo "${table_absolute_path}" | sed -E 's#hdfs://([^/]+)*##')
  echo "${table_relative_path}"
}

backup_table_schema () {
  echo "${FUNCNAME[0]}"
  # check
  [[ $# -eq 2 ]]  || { usage  ; exit 1 ;}
  check_table_exists "$1" "$2"
  local hive_db_name=$1
  local hive_table_name=$2

  SCHEMA_DDL_FILE="${hive_db_name}.${hive_table_name}.${SNAPSHOT_NAME}.hql"

  echo "INFO: extracting schema for table ${hive_db_name}.${hive_table_name} "
  # extract schema ; check of ${hive_db_name}.${hive_table_name} validity provided by beeline
   if ! ${BEELINE} -e \
  "show create table ${hive_db_name}.${hive_table_name} ${TERMINATE}" \
   >>  "${project_dir}"/output/"${SCHEMA_DDL_FILE}" ;then
    { echo "ERROR" ; exit 1 ;}
  fi

  echo "${TERMINATE}" >>  "${project_dir}"/output/"${SCHEMA_DDL_FILE}"
  # extract partitions DDL if any
  if listpartitions=$( ${BEELINE} -e "show partitions ${hive_db_name}.${hive_table_name} ;" 2> /dev/null ) \
     && [[ ! -z "${listpartitions}" ]]; then
    echo "INFO: table ${hive_table_name} is  a partionned table"
    echo "INFO: Extracting Partition DDL"

    for tablepart in ${listpartitions}
       do
          local partname
          partname=$(echo "${tablepart/=/=\"}" )
          # echo $partname
          echo "ALTER TABLE ${hive_table_name} ADD PARTITION ($partname\");" \
           >> "${project_dir}"/output/"${SCHEMA_DDL_FILE}"
       done
  fi
  echo "INFO: table ${hive_db_name}.${hive_table_name} created in ${project_dir}/output/${SCHEMA_DDL_FILE}"

}

backup_table_data() {
  echo "${FUNCNAME[0]}"
  # check
  [[ $# -eq 2 ]]  ||   { usage  ; exit 1 ;}

  check_table_exists "$1" "$2"
  local hive_db_name=$1
  local hive_table_name=$2

  echo "INFO: Taking a snapshot of the table ${hive_db_name}.${hive_table_name}"

  table_absolute_path=$(cat "${project_dir}/output/${SCHEMA_DDL_FILE}" | grep -E "^LOCATION$" -A 1 |  grep -E -v  "^LOCATION$" | tr -d "'" )
  table_relative_path=$(echo "${table_absolute_path}" | sed -E 's#hdfs://([^/]+)*##')
  # create hdfs snapshot for the table
  if ! "${project_dir}/../snapshot_hdfs/bin/core/hdfs_backup_user_operations.bash create_snapshot ${table_relative_path} ${SNAPSHOT_NAME}" ; then
    { echo "ERROR: while taking  snapshot for table ${hive_db_name}.${hive_table_name} " ; exit 1 ; }
  fi

}

schema_table_check_and_apply_retention() {
  echo "${FUNCNAME[0]}"
  local hive_db_name ; local hive_table_name
  hive_db_name=$1
  hive_table_name=$2
  [[ ! -z $3 ]] && is_strictly_positive_integer "$3" && local nb_DDL_snapshots_to_retain=$3
  [[ -z ${nb_DDL_snapshots_to_retain} ]] && nb_DDL_snapshots_to_retain=${DEFAULT_NB_DDL_SNAPSHOTS} && \
  echo "INFO number of DDL snapshots to retain not set, applying default retention=${DEFAULT_NB_DDL_SNAPSHOTS}"

  ## list of existing schema snapshots for a table in a chronological order
  local arr_existing_DDL_snapshots=( $(ls -tr  "${project_dir}/output/" | grep -E "^${hive_db_name}.${hive_table_name}(.+).hql$" ) )
  local nb_existing_DDL_snapshots=${#arr_existing_DDL_snapshots[@]}

  # core
  if [[ ${nb_existing_DDL_snapshots} -gt ${nb_DDL_snapshots_to_retain} ]]; then

    local nb_DDL_snapshots_to_remove=$((nb_existing_DDL_snapshots - nb_DDL_snapshots_to_retain ))
    local arr_DDL_snapshots_to_remove=( ${arr_existing_DDL_snapshots[@]:0:$nb_DDL_snapshots_to_remove} )

    for DDL_snap_to_remove in "${arr_DDL_snapshots_to_remove[@]}"; do
      rm -f  "${project_dir}/output/${DDL_snap_to_remove}"
    done

  else
    echo "INFO no additional DDL snapnshots to remove, ${nb_existing_DDL_snapshots} DDL snapnshots exists for table ${hive_db_name}.${hive_table_name}  "
  fi

  echo "INFO list of existing_DDL_snapshots"
  echo "$(ls -tr  ${project_dir}/output/ | egrep "^${hive_db_name}.${hive_table_name}(.+).hql$"  | xargs -I {} ls -tr  ${project_dir}/output/{} ) "

}

data_table_check_and_apply_retention(){
  echo "${FUNCNAME[0]}"
  #check
  check_table_exists "$1" "$2"

  local nb_snapshots_to_retain=$3
  local table_relative_path
  table_relative_path=$(get_table_relative_location "$1" "$2")

  "${project_dir}/../snapshot_hdfs/bin/core/hdfs_backup_user_operations.bash" \
   hdfs_check_and_apply_retention "${table_relative_path}" "${nb_snapshots_to_retain}"

}

###############################
## public functions
###############################
backup_table() {
  echo "${FUNCNAME[0]}"
  # check
  [[ $# -eq 2 ]]  ||   { usage  ; exit 1 ;}

  SNAPSHOT_NAME=$(echo  s`date +"%Y%m%d-%H%M%S.%3N"`)

  backup_table_schema "$1" "$2"
  backup_table_data "$1" "$2"

  echo "INFO: backup table $1 $2 finished"
}
backup_table_check_and_apply_retention() {

  [[ $# -eq 2 || $# -eq 3  ]]  || { usage && exit 1 ;}

  schema_table_check_and_apply_retention "$1" "$2" "$3"
  data_table_check_and_apply_retention "$1" "$2" "$3"
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
