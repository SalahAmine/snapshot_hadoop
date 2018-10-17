
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

#########################################################
# private functions
#########################################################
is_hdfs_dir() {
  debug "${FUNCNAME[0]} $@"
  local dir=$1
  [[ -z  ${dir} ]] && { usage ; exit 1 ; }
  hadoop fs -test -d "${dir}" || { error "${FUNCNAME[0]}: ERROR directory ${dir} does not exist" && exit 1 ;}
}

list_snapshottable_dirs() {
  debug "${FUNCNAME[0]} $@"
  [[ $# -eq 0 ]] || { usage ; exit 1 ;}

  info "${FUNCNAME[0]} listing snapshottable directories for all users"
  #  hdfs lsSnapshottableDir
  hdfs lsSnapshottableDir |  awk '{print $NF}' | grep "^/"
}

#########################################################
# public functions
#########################################################
#idempotent operation
# To allow snapnshot upon a dir you must be a SUPERUSER, the owner of the dir is NOT allowed
allow_snapshot() {
  debug "${FUNCNAME[0]} $@"
  [[ $# -eq 1 ]] || { usage ; exit 1 ;}
  local dir=$1
  if  is_hdfs_dir "${dir}" ; then
    hdfs dfsadmin -allowSnapshot "${dir}"
  fi
}

# disallow the snapnshottalbe directory, must have removed all the snapnshots
disallow_snapshot() {
  debug "${FUNCNAME[0]} $@"
  [[ $# -eq 1 ]] || { usage ; exit 1 ;}
  info "${FUNCNAME[0]}"
  local dir=$1
  if  is_hdfs_dir "${dir}" ; then
    hdfs dfsadmin -disallowSnapshot "${dir}"
  fi
}
