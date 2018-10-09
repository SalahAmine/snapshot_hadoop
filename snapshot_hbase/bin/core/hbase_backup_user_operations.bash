#!/usr/bin/env bash

# set -x
# include set -e at the top. This tells bash that it
#should exit the script if any statement returns a non-true return value.
set -e    # abort on unbound variable
set -o pipefail  # don't hide errors within pipes

readonly script_name=$(basename "${0}")
readonly script_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

.  "${script_dir}/../utils/hdfs_backup_user_utils.bash"
.  "${project_dir}/conf/env.bash"

[[ $# -eq 0 ]] && usage && exit 1 ;

case "$1" in
  check_hbase_table_exists)
    shift
    check_hbase_table_exists $@
    ;;
  create_table_snapshot)
    shift
    create_table_snapshot $@
    ;;
    delete_snapshot)
      shift
      delete_snapshot $@
      ;;
  list_all_snapshots)
    shift
    list_all_snapshots $@
    ;;
  list_all_snapshttable_dirs)
    shift
    list_all_snapshttable_dirs $@
    ;;
  is_snapshottable)
      shift
    is_snapshottable $@
      ;;
  hdfs_check_and_apply_retention)
    shift
    hdfs_check_and_apply_retention $@
    ;;
  -h | --help) usage
    exit 0
    ;;
  *)  usage
    exit 1;
    ;;
esac
