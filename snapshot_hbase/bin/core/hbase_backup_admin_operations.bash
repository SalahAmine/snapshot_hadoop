#!/usr/bin/env bash
# debug: use set -x
## source bash utility functions & variables
.  "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../utils/bash_toolkit.bash"

.  "${__project_dir}/conf/env.bash"
.  "${__project_dir}/bin/utils/hbase_backup_admin_utils.bash"


  case "$1" in
    list_all_snapshots)
      shift
      list_all_snapshots "$@"
      exit
      ;;
    restore_table)
      shift
      restore_table "$@"
      exit
      ;;
    check_hbase_table_exists)
      shift
      check_hbase_table_exists "$@"
      exit
      ;;
    check_and_apply_retention)
      shift
      check_and_apply_retention "$@"
      exit
      ;;
    *)  usage
      exit 1
      ;;
  esac
