#!/bin/bash
# Ver: 1.1 by Endial Fang (endial@126.com)

#[[ ${ENV_DEBUG:-false} = true ]] && set -x
MODULE="$(basename "$0")"

RESET='\033[0m'
BOLD='\033[1m'

# 前景色
BLACK='\033[38;5;0m'
RED='\033[38;5;1m'
GREEN='\033[38;5;2m'
YELLOW='\033[38;5;3m'
BLUE='\033[38;5;4m'
MAGENTA='\033[38;5;5m'
CYAN='\033[38;5;6m'
WHITE='\033[38;5;7m'

# 背景色
ON_BLACK='\033[48;5;0m'
ON_RED='\033[48;5;1m'
ON_GREEN='\033[48;5;2m'
ON_YELLOW='\033[48;5;3m'
ON_BLUE='\033[48;5;4m'
ON_MAGENTA='\033[48;5;5m'
ON_CYAN='\033[48;5;6m'
ON_WHITE='\033[48;5;7m'

# 函数列表

# 打印输出到 STDERR 设备
stderr_print() {
    printf "%b\\n" "${*}" >&2
}

# 输出实际日志信息
# 参数:
#   $1 - 日志类型
#   $2 - 日志信息
LOG() {
    local -r bool="${ENV_DEBUG:-false}"
    shopt -s nocasematch
    if [[ "$bool" = 1 || "$bool" =~ ^(yes|true)$ ]]; then
        debugInfo="${CYAN}${APP_NAME:-}:${MODULE:-}"
    else
        debugInfo="${CYAN}${APP_NAME:-}"
    fi  
    stderr_print "${debugInfo} ${MAGENTA}$(date "+%T")}${RESET} ${*}"
}

# 输出调试类日志信息，尽量少使用
# 参数:
#   $1 - 日志类型
#   $2 - 日志信息
LOG_D() {
    local -r bool="${ENV_DEBUG:-false}"
    shopt -s nocasematch
    if [[ "$bool" = 1 || "$bool" =~ ^(yes|true)$ ]]; then
        LOG "${BLUE}DBG${RESET}: ${*}"
    fi   
}

# 输出提示信息类日志信息
# 参数:
#   $1 - 日志类型
#   $2 - 日志信息
LOG_I() {
    LOG "${GREEN}INF${RESET}: ${*}"
}

# 输出警告类日志信息至sterr
# 参数:
#   $1 - 日志类型
#   $2 - 日志信息
LOG_W() {
    LOG "${YELLOW}WRN${RESET}: ${*}"
}

# 输出错误类日志信息至sterr，并退出脚本
# 参数:
#   $1 - 日志类型
#   $2 - 日志信息
LOG_E() {
    LOG "${RED}ERR${RESET}: ${*}"
}
