#!/bin/bash
# Ver: 1.0 by Endial Fang (endial@126.com)
#
# 服务管理函数库

# shellcheck disable=SC1091

# 加载依赖项
. /usr/local/scripts/liblog.sh              # 日志输出函数库
. /opt/bitnami/scripts/libvalidations.sh    # 数据有效性检测函数库

# 函数列表

# 获取并返回服务 PID
# 参数:
#   $1 - PID 文件
# 返回值:
#   PID
get_pid_from_file() {
    local pid_file="${1:?pid file is missing}"

    if [[ -f "$pid_file" ]]; then
        if [[ -n "$(< "$pid_file")" ]] && [[ "$(< "$pid_file")" -gt 0 ]]; then
            echo "$(< "$pid_file")"
        fi
    fi
}

# 检测 PID 对应的服务是否在运行中 
# 参数:
#   $1 - PID
# 返回值:
#   0 / 1
is_service_running() {
    local pid="${1:?pid is missing}"

    kill -0 "$pid" 2>/dev/null
}

# 通过发送信号停止一个指定 PID 的服务
# 参数:
#   $1 - PID 文件
#   $2 - 信号 (可选)
stop_service_using_pid() {
    local pid_file="${1:?pid file is missing}"
    local signal="${2:-}"
    local pid

    pid="$(get_pid_from_file "$pid_file")"
    [[ -z "$pid" ]] || ! is_service_running "$pid" && return

    if [[ -n "$signal" ]]; then
        kill "-${signal}" "$pid"
    else
        kill "$pid"
    fi

    local counter=10
    while [[ "$counter" -ne 0 ]] && is_service_running "$pid"; do
        sleep 1
        counter=$((counter - 1))
    done
}

# 启动一个 cron 守护进程
# 返回值:
#   true / false
cron_start() {
    if [[ -x "/usr/sbin/cron" ]]; then
        /usr/sbin/cron
    elif [[ -x "/usr/sbin/crond" ]]; then
        /usr/sbin/crond
    else
        false
    fi
}

# 为指定的服务生成 cron 配置文件
# 参数:
#   $1 - 服务名称
#   $2 - 命令
# 标志位:
#   --run-as - 运行的用户. 默认值: root
#   --schedule - Cron 周期配置. 默认值: * * * * *
generate_cron_conf() {
    local service_name="${1:?service name is missing}"
    local cmd="${2:?command is missing}"
    local run_as="root"
    local schedule="* * * * *"
    local clean="true"

    local clean="true"

    # 检测标志位
    shift 2
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            --run-as)
                shift
                run_as="$1"
                ;;
            --schedule)
                shift
                schedule="$1"
                ;;
            --no-clean)
                clean="false"
                ;;
            *)
                echo "Invalid command line flag ${1}" >&2
                return 1
                ;;
        esac
        shift
    done

    mkdir -p /etc/cron.d
    if "$clean"; then
        echo "${schedule} ${run_as} ${cmd}" > /etc/cron.d/"$service_name"
    else
        echo "${schedule} ${run_as} ${cmd}" >> /etc/cron.d/"$service_name"
    fi
}

# 为指定的服务生成 monit 配置文件
# 参数:
#   $1 - 服务名
#   $2 - PID 文件
#   $3 - 启动命令
#   $4 - 停止命令
# 标志位:
#   --disabled - 是否禁用. 默认值: no
generate_monit_conf() {
    local service_name="${1:?service name is missing}"
    local pid_file="${2:?pid file is missing}"
    local start_command="${3:?start command is missing}"
    local stop_command="${4:?stop command is missing}"
    local monit_conf_dir="/etc/monit/conf.d"
    local disabled="no"

    # 检测标志位
    shift 4
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            --disabled)
                shift
                disabled="$1"
                ;;
            *)
                echo "Invalid command line flag ${1}" >&2
                return 1
                ;;
        esac
        shift
    done

    is_boolean_yes "$disabled" && conf_suffix=".disabled"
    mkdir -p "$monit_conf_dir"
    cat >"${monit_conf_dir}/${service_name}.conf${conf_suffix:-}" <<EOF
check process ${service_name}
  with pidfile "${pid_file}"
  start program = "${start_command}" with timeout 90 seconds
  stop program = "${stop_command}" with timeout 90 seconds
EOF
}

# 为指定的服务生成 Logrotate 配置文件
# 参数:
#   $1 - 应用名称
#   $2 - 日志路径
# 标志位:
#   --period - 周期
#   --rotations - Rotations 存储的数量
#   --extra - 扩展参数 (可选)
generate_logrotate_conf() {
    local service_name="${1:?service name is missing}"
    local log_path="${2:?log path is missing}"
    local period="weekly"
    local rotations="150"
    local extra=""
    local logrotate_conf_dir="/etc/logrotate.d"
    local var_name
    
    # 检测标志位
    shift 2
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            --period|--rotations|--extra)
                var_name="$(echo "$1" | sed -e "s/^--//" -e "s/-/_/g")"
                shift
                declare "$var_name"="${1:?"$var_name" is missing}"
                ;;
            *)
                echo "Invalid command line flag ${1}" >&2
                return 1
                ;;
        esac
        shift
    done

    mkdir -p "$logrotate_conf_dir"
    cat <<EOF | sed '/^\s*$/d' >"${logrotate_conf_dir}/${service_name}"
${log_path} {
  ${period}
  rotate ${rotations}
  dateext
  compress
  copytruncate
  missingok
$(indent "$extra" 2)
}
EOF
}
