usage() {
    cat <<- EOF

  User utility script for managing HBase snapnshots
  In case if using coprocessors only admin user is able to manage snapshots
    ## creates a snapshot for table <hbase_namespace>:<hbase_table>
    create_table_snapshot <hbase_namespace> <hbase_table>
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

#########################################################
# public functions
#########################################################
create_table_snapshot () {
  [[ $# -eq 2 ]] || \
  { error "${FUNCNAME[0]}: required args are <hbase_namespace> <hbase_table>  "; exit 1 ;}
  check_hbase_table_exists "$1" "$2"
  local hbase_namespace=$1 ; local hbase_table=$2
  # snapshot cmd does not accept : char, so we replace it by .
  if  echo "snapshot '${hbase_namespace}:${hbase_table}', '${hbase_namespace}.${hbase_table}${SNAPSHOT_SUFFIX}$(date +"%Y%m%d-%H%M%S-%3N")' " | hbase shell -n ; then
     info "${FUNCNAME[0]}:a snapshot is successfully created for table ${hbase_namespace}:${hbase_table} "
  else
  { error "${FUNCNAME[0]}: error creating a snapshot for table ${hbase_namespace}:${hbase_table}  "; exit 1 ;}
  fi

}
