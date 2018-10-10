usage() {
    cat <<- EOF

  User utility script for managing HBase snapnshots
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
    [[ $# -eq 1 ]] && [[ "$1" =~ ^[0-9]+$ ]] && [[ $1 -gt 0 ]] || \
    { error "$FUNCNAME:$1 must be a valid integer and > 0" ; exit 1 ;}
}

check_hbase_table_exists() {
  # exits hbase cmd does an exat match
  echo "exists '$1:$2' "  | hbase shell -n 2>&1 | grep -q "does exist"
  [[ $? -eq 0 ]]  || { error "$FUNCNAME: hbase table $1:$2 does not exist" ; exit 1 ;}
}

#########################################################
# public functions
#########################################################
create_table_snapshot () {
  [[ $# -eq 2 ]] || \
  { error "$FUNCNAME: required args are <hbase_namespace> <hbase_table>  "; exit 1 ;}
  check_hbase_table_exists $1 $2
  local hbase_namespace=$1 ; local hbase_table=$2
  # snapshot cmd does not accept : char, so we replace it by .
  echo "snapshot '${hbase_namespace}:${hbase_table}', '${hbase_namespace}.${hbase_table}${SNAPSHOT_SUFFIX}$(date +"%Y%m%d-%H%M%S-%3N")' " | hbase shell -n
  [[ $? -eq 0 ]] || \
    { error "$FUNCNAME: error creating a snapshot for table ${hbase_namespace}:${hbase_table}  "; exit 1 ;}
}
