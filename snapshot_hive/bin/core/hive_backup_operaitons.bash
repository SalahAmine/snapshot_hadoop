#!/usr/bin/env bash
# debug: use set -x

readonly script_name=$(basename "${0}")
readonly script_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
readonly project_dir=$( readlink -f  ${script_dir}/../.. )

.  "${script_dir}/../utils/hive_backup_utils.bash"
# source env variables
.  "${project_dir}/conf/env.bash"


echo "####################################"
echo "script_name" $script_name
echo "script_dir" $script_dir
echo "project_dir" $project_dir
echo "####################################"
echo ""


  case "$1" in
    extract_table_DDL)
      shift
      extract_table_DDL $@
      exit
      ;;
    DDL_check_and_apply_retention)
      shift
      DDL_check_and_apply_retention $@
      exit
      ;;
    usage)
      usage ; exit
      ;;
    *)  usage
      exit 1
      ;;
  esac
