#!/usr/bin/env bash

# debug: use set -x
set -o pipefail
set -e

. "../utils/hdfs_backup_admin_utils.bash"

  case "$1" in
    allow_snapshot)
      shift
      allow_snapshot $@
      exit
      ;;
    disallow_snapshot)
      shift
      disallow_snapshot $@
      exit
      ;;
    list_snapshottable_dirs)
      shift
      list_snapshottable_dirs $@
      exit
      ;;
    *)  usage
      exit 1
      ;;
  esac
