#!/usr/bin/env bash

# debug: use set -x
set -o pipefail

readonly script_name=$(basename "${0}")
readonly script_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
readonly project_dir=$( readlink -f  "${script_dir}/../.." )

.  "${script_dir}/../utils/hbase_backup_admin_utils.bash"
.  "${project_dir}/conf/env.bash"


  case "$1" in
    list_all_snapshots)
      shift
      list_all_snapshots $@
      exit
      ;;
    restore_table)
      shift
      restore_table $@
      exit
      ;;
    check_hbase_table_exists)
      shift
      check_hbase_table_exists $@
      exit
      ;;
    check_and_apply_retention)
      shift
      check_and_apply_retention $@
      exit
      ;;
    *)  usage
      exit 1
      ;;
  esac
