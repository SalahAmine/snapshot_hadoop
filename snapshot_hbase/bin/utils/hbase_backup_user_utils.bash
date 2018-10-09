
##
## The HBase shell uses the standard convention of returning a value of 0
## for successful commands, and some non-zero value for failed commands.
##

usage() {
    cat <<- EOF

  User utility script for managing HDFS snapnshots
    ## list all the snapshot directories availalble for user ${USER}
    list_snapshottable_dirs
    ## creates a snapshot for a directory,user ${USER} must be owner of this directory
    create_table_snapshot <dir> [snapshot_name]
    ## list all  availalble snapnshots for a directory
    list_all_snapshots <dir>
    ## apply retention policy on snapshotted directories
    hdfs_check_and_apply_retention <dir> <number_of_snapshot_copies_to_retain>
    ## usage guide
    usage

EOF
}

DEFAULT_NB_SNAPSHOTS=7

###################################
###################################
###utlities###

is_strictly_positive_integer() {
    [[ $# -eq 1 ]] && [[ "$1" =~ ^[0-9]+$ ]] && [[ $1 -gt 0 ]] || \
    { echo "$FUNCNAME: ERROR $1 must be a valid integer and > 0" ; exit 1 ;}
}

check_hbase_table_exists() {

  echo "exists '$1:$2' "  | hbase shell -n 2>&1 | grep -q "does exist"
  ([[ $? -eq 0 ]] && return 0 ) || return 1
}

###########################################
###########################################
### user operations ###

##
create_table_snapshot () {

  [[ $# -eq 2 ]] || \
  { echo "$FUNCNAME: ERROR required args are <namespace> <table_name> "; exit 1 ;}
  { check_hbase_table_exists $1 $2 ;} || exit 1
  local hbase_namespace=$1 ; local hbase_table=$2
  # snapshot cmd does not accept : char, so we replace it by .
  echo "snapshot '${hbase_namespace}:${hbase_table}', '${hbase_namespace}.${hbase_table}${SNAPSHOT_SUFFIX}$(date +"%Y%m%d-%H%M%S-%3N")' " | hbase shell -n
  [[ $? -eq 0 ]] || \
    { echo "$FUNCNAME: ERROR creating a snapshot for table ${hbase_namespace}:${hbase_table}  "; exit 1 ;}
}
