#!/usr/bin/env bash

# set -x
# include set -e at the top. This tells bash that it
#should exit the script if any statement returns a non-true return value.
set -e    # abort on unbound variable
set -o pipefail  # don't hide errors within pipes


. "../utils/hdfs_backup_user_utils.bash"

[[ $# -eq 0 ]] && usage && exit 1 ;

case "$1" in
  list_snapshottable_dirs)
    shift
    list_snapshottable_dirs $@
    ;;
  create_snapshot)
    shift
    create_snapshot $@
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
  check_and_apply_retention)
    shift
    check_and_apply_retention $@
    ;;
  -h | --help) usage
    exit 0
    ;;
  *)  usage
    exit 1;
    ;;
esac
