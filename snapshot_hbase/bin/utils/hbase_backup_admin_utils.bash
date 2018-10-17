#!/usr/bin/env bash

usage() {
    cat <<- EOF
  Admin utility script for managing HBase snapnshots

    ## list all snapshots for a given table
    list_all_snapshots  <hbase_namespace> <hbase_table>
    ## restore a hbase table to  <snapshot_name>  state
    restore_table <hbase_namespace> <hbase_table> <snapshot_name>
    ## apply a retention policy on a table
    check_and_apply_retention <hbase_namespace> <hbase_table> [nb_snapshots_to_retain]
    ## usage guide
    usage
EOF
}
#########################################################
# private functions
#########################################################
is_strictly_positive_integer() {
    { [[ $# -eq 1 ]] && [[ "$1" =~ ^[0-9]+$ ]] && [[ $1 -gt 0 ]] ;}  || \
    { error "${FUNCNAME[0]}: $1 must be a valid integer and > 0" ; exit 1 ;}
}

check_hbase_table_exists() {
  if ! echo "exists '$1:$2' " | hbase shell -n | grep -q "does exist" ; then
   { error "${FUNCNAME[0]}: ERROR table $1:$2 does not exist"; exit 1 ;}
  fi
}

check_snapshot_exists() {
  [[ $# -eq 1 ]] || { error "${FUNCNAME[0]}: Please provide a snapshot_name "; exit 1 ;}
  local snapshot_name=$1 ; local res
  res=$( echo "list_snapshots '^${snapshot_name}$' " | hbase shell -n 2>&1  )
  res=$( echo "${res}" | tr " "  "\n" | grep -E  "^${hbase_namespace}.${hbase_table}.*$" | sort -u )
  [[ -z "${res}" ]] && { error "${FUNCNAME[0]}: the provided snapshot_name ${snapshot_name} does not exist "; exit 1 ;}
  [[ ! $( echo "${res}" | wc -l ) -eq 1 ]] && { return 0 ;}
}

#########################################################
# public functions
#########################################################
# get list of retained snapnshots in chronological order
list_all_snapshots () {
  #check
  [[ $# -eq 2 ]] || \
  { error "${FUNCNAME[0]}: ERROR required args are  <hbase_namespace> <hbase_table> "; exit 1 ;}
  check_hbase_table_exists "$1" "$2"
  local hbase_namespace=$1 ; local hbase_table=$2
  local res
  res=$( echo "list_snapshots '^${hbase_namespace}.${hbase_table}.*$'" | hbase shell -n )
  res=$( echo "${res}" | tr " "  "\n" | grep -E  "^${hbase_namespace}.${hbase_table}.*$" | sort -u)
  [[ -z "${res}" ]] && notice "no available snapshots matching regexp ^${hbase_namespace}.${hbase_table}.*$ " && exit 0
  printf "%s\n" "${res}"
}

restore_table() {
  #check
  [[ $# -eq 3 ]] || \
  { error "${FUNCNAME[0]}: required args are <hbase_namespace> <hbase_table> <snapshot_name> "; exit 1 ;}
  check_hbase_table_exists "$1" "$2"
  check_snapshot_exists "$3"
  local hbase_namespace=$1 ; local hbase_table=$2; local snapshot_name=$3

  if echo " disable '${hbase_namespace}:${hbase_table}' ; \
         restore_snapshot  '${snapshot_name}', {RESTORE_ACL=>true} ; \
         enable '${hbase_namespace}:${hbase_table}';" | hbase shell -n ; then
    info "table ${hbase_namespace}:${hbase_table} restored to snapshot ${snapshot_name} "
  else
    {   error "error restoring table ${hbase_namespace}:${hbase_table}  to snapshot ${snapshot_name} "; exit 1 ; }
  fi

}

check_and_apply_retention() {
  #check
  [[ $# -eq 2 || $# -eq 3  ]]  || \
  { error "${FUNCNAME[0]}: required args are <hbase_namespace> <hbase_table> <snapshot_name> [nb_snapshots_to_retain] "; exit 1 ;}
  [[ ! -z "$3" ]] && is_strictly_positive_integer "$3"
  local nb_snapshots_to_retain=$3
  check_hbase_table_exists "$1" "$2"
  local hbase_namespace=$1 ; local hbase_table=$2

  [[ -z ${nb_snapshots_to_retain} ]] && nb_snapshots_to_retain=${DEFAULT_NB_SNAPSHOTS} && \
  info "INFO number of snapshots to retain not set, applying default retention=${DEFAULT_NB_SNAPSHOTS}"

  # core
  local arr_existing_snapshots=( $(list_all_snapshots "${hbase_namespace}" "${hbase_table}") )
  local nb_existing_snapshots=${#arr_existing_snapshots[@]}

  if [[ ${nb_existing_snapshots} -gt ${nb_snapshots_to_retain} ]]; then
    local nb_snapshots_to_remove=$((nb_existing_snapshots - nb_snapshots_to_retain ))
    local arr_snapshots_to_remove=( "${arr_existing_snapshots[@]:0:$nb_snapshots_to_remove}" )
    #echo "arr_snapshots_to_remove" $arr_snapshots_to_remove

    for snap_to_remove in "${arr_snapshots_to_remove[@]}"; do
      if echo " delete_snapshot '${snap_to_remove}' ; " | hbase shell -n ; then
        info " snapshot ${snap_to_remove} removed"
      else
        { error "ERROR removing snapshot ${snap_to_remove}"; exit 1 ;}
      fi
    done
  else
    info "no additional snapnshots to remove, ${nb_existing_snapshots} snapnshots exists for table ${hbase_namespace} ${hbase_table}  "
    # echo "INFO list of existing_snapshots"
    # printf "%s\n"  "${arr_existing_snapshots[@]}"
  fi
  info " retention policy on table ${hbase_namespace}:${hbase_table} with retention=${nb_snapshots_to_retain} applied successfully "


}
