#!/bin/bash
# Ver: 1.0 by Endial Fang (endial@126.com)
#
# 服务管理函数库

# shellcheck disable=SC1091

# 加载依赖项
. /usr/local/scripts/liblog.sh          # 日志输出函数库

# 函数列表

# 获取并返回服务 PID
# 参数:
#   $1 - PID 文件
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
is_service_running() {
    local pid="${1:?pid is missing}"

    kill -0 "$pid" 2>/dev/null
}

# 通过发送信号停止一个指定的服务
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

# 生成一个 Logrotate 配置文件
# 参数:
#   $1 - 应用名称
#   $2 - 日志路径及日志文件名
#   $3 - 周期
#   $4 - Rotations 存储的数量
#   $5 - 其他参数 (可选)
generate_logrotate_conf() {
    local service_name="${1:?service name is missing}"
    local log_path="${2:?log path is missing}"
    local period="${3:-weekly}"
    local rotations="${4:-150}"
    local extra_options="${5:-}"
    local logrotate_conf_dir="/etc/logrotate.d"

    mkdir -p "$logrotate_conf_dir"
    cat >"${logrotate_conf_dir}/${service_name}" <<-'EOF'
        ${log_path} {
            ${period}
            rotate ${rotations}
            dateext
            compress
            copytruncate
            missingok
            ${extra_options}
        }
EOF
}
