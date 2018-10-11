#!/usr/bin/env bash
# debug: use set -x

## source bash_toolkit from bash_boilerplate project
.  "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../utils/bash_toolkit.bash"

.  "${__project_dir}/conf/env.bash"
.  "${__project_dir}/bin/utils/hive_backup_utils.bash"


# echo "####################################"
# echo "script_name" $script_name
# echo "script_dir" $script_dir
# echo "project_dir" $project_dir
# echo "####################################"
# echo ""


  case "$1" in
    backup_table)
      shift
      backup_table "$@"
      exit
      ;;
    backup_table_check_and_apply_retention)
      shift
      backup_table_check_and_apply_retention "$@"
      exit
      ;;
    usage)
      usage ; exit
      ;;
    *)  usage ; exit 1
      ;;
  esac
