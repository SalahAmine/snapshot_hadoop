#!/usr/bin/env bash


usage() {
    cat <<- EOF

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

EOF
}

# utility

is_strictly_positive_integer() {
    [[ $# -eq 1 ]] && [[ "$1" =~ ^[0-9]+$ ]] && [[ $1 -gt 0 ]] || \
    { echo "$FUNCNAME: ERROR $1 must be a valid integer and > 0" ; exit 1 ;}
}

check_hbase_table_exists() {
  echo "exists '$1:$2' "  | hbase shell -n 2>&1 | grep -q "does exist"
  [[ $? -eq 0 ]] || { echo "$FUNCNAME: ERROR table $1:$2 does not exist"; exit 1 ;}
}

check_snapshot_exists() {
  [[ $# -eq 1 ]] || { echo "$FUNCNAME: Please provide a snapshot_name "; exit 1 ;}
  local snapshot_name=$1
  local res=$( echo "list_snapshots '^${snapshot_name}$' " | hbase shell -n 2>&1  )
  res= $( echo $res | tr " "  "\n" | egrep  "^${hbase_namespace}.${hbase_table}.*$" | sort -u )
  [[ -z ${res} ]] && { echo "$FUNCNAME: the provided snapshot_name ${snapshot_name} does not exist "; exit 1 ;}
  [[ ! $( echo ${res} | wc -l ) -eq 1 ]] && { return 0 ;}
}

# get list of retained snapnshots in chronological order
list_all_snapshots () {
  [[ $# -eq 2 ]] || \
  { echo "$FUNCNAME: ERROR required args are  <hbase_namespace> <hbase_table> "; exit 1 ;}
  check_hbase_table_exists $1 $2
  local hbase_namespace=$1 ; local hbase_table=$2
  local res=$( echo "list_snapshots '^${hbase_namespace}.${hbase_table}.*$'" | hbase shell -n )
  echo $res | tr " "  "\n" | egrep  "^${hbase_namespace}.${hbase_table}.*$" | sort -u
}

restore_table() {
  [[ $# -eq 3 ]] || \
  { echo "$FUNCNAME: ERROR required args are <hbase_namespace> <hbase_table> <snapshot_name> "; exit 1 ;}
  check_hbase_table_exists $1 $2
  check_snapshot_exists $3
  local hbase_namespace=$1 ; local hbase_table=$2; local snapshot_name=$3

  echo " disable '${hbase_namespace}:${hbase_table}' ; \
         restore_snapshot  '${snapshot_name}', {RESTORE_ACL=>true} ; \
         enable '${hbase_namespace}:${hbase_table}';" | hbase shell -n

  ##hbase usesRPC protocol,  RPC commands are stateless. The only way to be sure of the status of an operation is to check.
  [[ $? -eq 0 ]] || \
  { echo "$FUNCNAME: ERROR either the command didn't really succed or it succeeds but client
  didnt catch that, please redo the action "; exit 1 ;}

}

check_and_apply_retention() {

  [[ $# -eq 2 || $# -eq 3  ]]  || { usage && exit 1 ;}
  check_hbase_table_exists $1 $2
  local hbase_namespace=$1 ; local hbase_table=$2
  [[ ! -z $3 ]] && is_strictly_positive_integer $3
  local nb_snapshots_to_retain=$3
  [[ -z ${nb_snapshots_to_retain} ]] && nb_snapshots_to_retain=${DEFAULT_NB_SNAPSHOTS} && \
  echo "INFO number of snapshots to retain not set, applying default retention= ${DEFAULT_NB_SNAPSHOTS}"

  # core
  local arr_existing_snapshots=( $(list_all_snapshots ${hbase_namespace} ${hbase_table}) )
  local nb_existing_snapshots=${#arr_existing_snapshots[@]}

  if [[ ${nb_existing_snapshots} -gt ${nb_snapshots_to_retain} ]]; then
    local nb_snapshots_to_remove=$((nb_existing_snapshots - nb_snapshots_to_retain ))
    local arr_snapshots_to_remove=( ${arr_existing_snapshots[@]:0:$nb_snapshots_to_remove} )
    #echo "arr_snapshots_to_remove" $arr_snapshots_to_remove

    for snap_to_remove in ${arr_snapshots_to_remove[@]}; do
      snap_version_name=$( echo ${snap_to_remove} | awk  -F  "/"  '{ print $NF }' )
      #echo "snap to remove" ${snap_to_remove}
      # echo "snap_version_name to remove $snap_version_name"
      #hdfs dfs -ls ${snap_to_remove}
      echo " delete_snapshot '${snap_to_remove}' ; " | hbase shell -n
      [[ $? -eq 0 ]] || { echo "ERROR removing snapshot ${snap_to_remove}"; exit 1 ;}
    done
  else
    echo "INFO no additional snapnshots to remove, ${nb_existing_snapshots} \
     snapnshots exists for table ${hbase_namespace} ${hbase_table}  "
    # echo "INFO list of existing_snapshots"
    # printf "%s\n"  "${arr_existing_snapshots[@]}"
    exit 0
  fi

}
