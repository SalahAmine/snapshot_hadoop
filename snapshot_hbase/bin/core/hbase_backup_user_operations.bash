#!/usr/bin/env bash

## source bash utility functions & variables
.  "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../utils/bash_toolkit.bash"

.  "${__project_dir}/conf/env.bash"
.  "${__project_dir}/bin/utils/hbase_backup_user_utils.bash"


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
