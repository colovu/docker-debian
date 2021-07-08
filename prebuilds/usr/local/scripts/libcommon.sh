#!/bin/bash
# Ver: 1.3 by Endial Fang (endial@126.com)
#
# 通用函数库

# 加载依赖项
. /usr/local/scripts/liblog.sh          # 日志输出函数库

# 函数列表

# 打印包含包含Logo的欢迎信息
print_welcome_info() {
    [[ -n "${APP_NAME}" ]] && github_url="/docker-${APP_NAME}"

    LOG_I '  ____      _ '
    LOG_I ' / ___|___ | | _____   ___   _ '
    LOG_I '| |   / _ \| |/ _ \ \ / / | | |  '"Docker : ${BOLD}${APP_NAME:-undefined}${RESET}"
    LOG_I '| |__| (_) | | (_) \ V /| |_| |  '"Version: ${BOLD}${APP_VERSION:-0.0}${RESET}"
    LOG_I ' \____\___/|_|\___/ \_/  \__,_|  '"PowerBy: ${BOLD}Endial@126.com${RESET}"
    LOG_D " Project Repo: https://github.com/colovu/${github_url:-}"
    LOG_I ""
}

# 根据需要打印欢迎信息
print_image_welcome() {
    if [[ "$(id -u)" = "0" ]]; then
        print_welcome_info
    fi
}

# 检测可能导致容器执行后直接退出的命令，如"--help"；如果存在，直接返回 0
# 参数:
#   $1 - 待检测的参数表
print_command_help() {
    local arg
    for arg; do
        case "$arg" in
            -'?'|--help|-V|--version|-version)
                exec "$@"
                exit
                ;;
        esac
    done
}

# 检测应用相应的配置文件是否存在，如果不存在，则从默认配置文件目录拷贝一份
# 默认配置文件路径：/etc/${APP_NAME}
# 目标配置文件路径：/srv/conf/${APP_NAME}
# 参数：
#   $1 - 基础路径
#   $* - 基础路径下的文件及目录列表，以" "分割
# 例子: 
#   ensure_config_file_exist /etc/${APP_NAME} conf.d server.conf
ensure_config_file_exist() {
    local -r base_path="${1:?paths is missing}"
    local f=""
    local dist=""

    shift 1
    LOG_D "List to check: $@"
    while [ "$#" -gt 0 ]; do
        f="${1}"
        LOG_D " Process \"${f}\""
        if [ -d "${base_path}/${f}" ]; then
            dist="$(echo ${base_path}/${f} | sed -e 's/\/etc/\/srv\/conf/g')"
            [[ ! -d "${dist}" ]] && LOG_D " Create directory: ${dist}" && mkdir -p "${dist}"
            [[ ! -z $(ls -A "${base_path}/${f}") ]] && ensure_config_file_exist "${base_path}/${f}" $(ls -A "${base_path}/${f}")
        else
            dist="$(echo ${base_path}/${f} | sed -e 's/\/etc/\/srv\/conf/g')"
            [[ ! -e "${dist}" ]] && LOG_D " Copy: ${base_path}/${f} ===> ${dist}" && cp "${base_path}/${f}" "${dist}" && rm -rf "/srv/conf/${APP_NAME}/.app_init_flag"
        fi
        shift
    done
}

# 根据脚本扩展名及权限，执行相应的初始化脚本
# 参数:
#   $1 - 文件列表，支持路径通配符
# 使用: 
#   process_init_files [file [file [...]]]
# 例子: 
#   process_init_files /src/conf/${APP_NAME}/initdb.d/*
process_init_files() {
    echo
    local f
    for f; do
        case "$f" in
            *.sh)
                if [ -x "$f" ]; then
                    LOG_I "$0: running $f"
                    "$f"
                else
                    LOG_I "$0: sourcing $f"
                    . "$f"
                fi
                ;;
            *)      LOG_W "$0: ignoring $f" ;;
        esac
        echo
    done
}

# 检测当前是否为 root 用户
is_root() {
    if [[ "$(id -u)" = "0" ]]; then
        LOG_D "Run as root."
        true
    else
        LOG_D "Run as non-root: $(id -u)"
        false
    fi
}

# 检测当前脚本是被直接执行的，还是从其他脚本中使用 "source" 调用的
is_sourced() {
    [ "${#FUNCNAME[@]}" -ge 2 ] \
    && [ "${FUNCNAME[0]}" = 'is_sourced' ] \
    && [ "${FUNCNAME[1]}" = 'source' ]
}
