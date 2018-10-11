#!/usr/bin/env bash

## source bash_toolkit from bash_boilerplate project
.  "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../utils/bash_toolkit.bash"

.  "${__project_dir}/conf/env.bash"
.  "${__project_dir}/bin/utils/hdfs_backup_admin_utils.bash"



  case "$1" in
    allow_snapshot)
      shift
      allow_snapshot "$@"
      exit
      ;;
    disallow_snapshot)
      shift
      disallow_snapshot "$@"
      exit
      ;;
    list_snapshottable_dirs)
      shift
      list_snapshottable_dirs "$@"
      exit
      ;;
    *)  usage
      exit 1
      ;;
  esac
