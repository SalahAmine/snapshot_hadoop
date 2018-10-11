# This is a toolkit file to be sourced whenever bash is used for scripting
# It includes tools, like env vars, looger and trap functions

# This file is based on a deep revision of a template by BASH3 Boilerplate v2.3.0
# http://bash3boilerplate.sh/#authors

# Exit on error inside any functions or subshells.
# don't use it and prefer handling errors by yourself
# set -o errtrace
# Do not allow use of undefined vars. Use ${VAR:-} to use an undefined VAR
# set -o nounset
# Catch the error in case mysqldump fails (but gzip succeeds) in `mysqldump |gzip`
set -o pipefail
# Turn on traces, useful while debugging but commented out by default
# set -o xtrace  is equal to  set -x
# set -o xtrace  = set -x

#########################################################
# load commun useful variables
#########################################################

## check if the script is sourced or not
## this helps to declare correctly the env vars for the main script
# i.e if sourced
[[ "${BASH_SOURCE[0]}" != "${0}" ]] && __tmp_source_index="1"

readonly __dir="$(cd "$(dirname "${BASH_SOURCE[${__tmp_source_index:-0}]}")" && pwd)"
readonly __file="${__dir}/$(basename "${BASH_SOURCE[${__tmp_source_index:-0}]}")"
readonly __file_basename="$(basename "${__file}" .sh)"
# readonly __invocation="$(printf %q "${__file}")$((($#)) && printf ' %q' "$@" || true)"
readonly __project_dir=$( readlink -f  "${__dir}/../.." )
## use it when project is bundled with ohter projectcs under a parent dir
readonly __project_parent_dir=$( readlink -f  "${__project_dir}/.." )


# echo "__dir" $__dir
# echo "__file" $__file
# echo "__project_dir ${__project_dir}"

#########################################################
# load a logger
#########################################################

# Define the environment variables (and their defaults) that this script depends on
LOG_LEVEL="${LOG_LEVEL:-6}" # 6= info (default)  7 = debug -> 0 = emergency
NO_COLOR="${NO_COLOR:-}"    # true = disable color. otherwise autodetected

function __utils_log () {

  ##assign colors to different log levels
  ## log level: debug ... emergency
  local log_level="${1}"
  shift

  # shellcheck disable=SC2034
  local color_debug="\\x1b[35m"
  # shellcheck disable=SC2034
  local color_info="\\x1b[32m"
  # shellcheck disable=SC2034
  local color_notice="\\x1b[34m"
  # shellcheck disable=SC2034
  local color_warning="\\x1b[33m"
  # shellcheck disable=SC2034
  local color_error="\\x1b[31m"
  # shellcheck disable=SC2034
  local color_critical="\\x1b[1;31m"
  # shellcheck disable=SC2034
  local color_alert="\\x1b[1;33;41m"
  # shellcheck disable=SC2034
  local color_emergency="\\x1b[1;4;5;33;41m"

  local colorvar="color_${log_level}"

  # if colorvar not set or null substitue by ${color_error}
  local color="${!colorvar:-${color_error}}"
  local color_reset="\\x1b[0m"


  if [[ "${NO_COLOR:-}" = "true" ]] || { [[ "${TERM:-}" != "xterm"* ]] && [[ "${TERM:-}" != "screen"* ]] ; } || [[ ! -t 2 ]]; then
    if [[ "${NO_COLOR:-}" != "false" ]]; then
      # Don't use colors on pipes or non-recognized terminals
      color=""; color_reset=""
    fi
  fi

  # all remaining arguments are to be printed
  local log_line=""
  ## IFS=$'\n'  changes the field separator to newline, here it is inside the while
  ## cmd so it take effect locally

  while IFS=$'\n' read -r log_line; do
    echo -e "$(date -u +"%Y-%m-%d %H:%M:%S UTC") ${color}$(printf "[%${#log_level}s]" "${log_level}")${color_reset} ${log_line}" 1>&2
  done <<< "${@:-}"

}

function emergency () {                                __utils_log emergency "${@}"; exit 1; }
function alert ()     { [[ "${LOG_LEVEL:-0}" -ge 1 ]] && __utils_log alert "${@}"; true; }
function critical ()  { [[ "${LOG_LEVEL:-0}" -ge 2 ]] && __utils_log critical "${@}"; true; }
function error ()     { [[ "${LOG_LEVEL:-0}" -ge 3 ]] && __utils_log error "${@}"; true; }
function warning ()   { [[ "${LOG_LEVEL:-0}" -ge 4 ]] && __utils_log warning "${@}"; true; }
function notice ()    { [[ "${LOG_LEVEL:-0}" -ge 5 ]] && __utils_log notice "${@}"; true; }
function info ()      { [[ "${LOG_LEVEL:-0}" -ge 6 ]] && __utils_log info "${@}"; true; }
function debug ()     { [[ "${LOG_LEVEL:-0}" -ge 7 ]] && __utils_log debug "${@}"; true; }


#########################################################
# Signal trapping and reporting
#
#########################################################

# if you need to do an action before exit  include the function+ subsequent trap call in the main script
function __clean_up_before_exit {
  local result=${?}
  # Your cleanup code here
  info "Cleaning up. Done"
  exit ${result}
}
## Uncomment the following line for proviving a cleanup functino after an EXIT
# trap __clean_up_before_exit EXIT

# if you need to trace evrey error even those inside functions
#  include the function+ subsequent trap call in the main script
# requires `set -o errtrace`
function __report_on_error() {
    local error_code=${?}
    error "Error in ${__file} on line ${1}"
    exit ${error_code}
}
# Uncomment the following line for always providing an error backtrace
## trap call on ERROR will catch all errors including those inside functions
#trap '__report_on_error ${LINENO}' ERR
