#!/bin/bash
# Ver: 1.2 by Endial Fang (endial@126.com)
#
# 操作系统控制函数库

# 加载依赖项
. /usr/local/scripts/liblog.sh          # 日志输出函数库
. /usr/local/scripts/libfs.sh           # 文件系统函数库

# 函数列表

# 检测指定用户账户是否存在
# 参数:
#   $1 - 用户账户
# 返回值:
#   0 / 1
is_user_exists() {
    local user="${1:?user is missing}"
    id "$user" >/dev/null 2>&1
}

# 检测指定用户分组是否存在
# 参数:
#   $1 - 用户组
# 返回值:
#   0 / 1
is_group_exists() {
    local group="${1:?group is missing}"
    getent group "$group" >/dev/null 2>&1
}

# 检测当前是否为 root 用户
# 返回值:
#   true / false
is_root() {
    if [[ "$(id -u)" = "0" ]]; then
        LOG_D "Run as root."
        true
    else
        LOG_D "Run as non-root: $(id -u)"
        false
    fi
}

# 确保指定用户组在系统中存在
# 参数:
#   $1 - 用户组
# 标志位:
#   -s|--system - 创建系统用户 (uid <= 999)
ensure_group_exists() {
    local group="${1:?group is missing}"
    local is_system_user=false

    # 检测标志位
    shift 1
    while [ "$#" -gt 0 ]; do
        case "$1" in
            -s|--system)
                is_system_user=true
                ;;
            *)
                echo "Invalid command line flag $1" >&2
                return 1
                ;;
        esac
        shift
    done

    if ! is_group_exists "$group"; then
        local -a args=("$group")
        $is_system_user && args+=("--system")
        groupadd "${args[@]}" >/dev/null 2>&1
    fi
}

# 确保指定用户在系统中存在
# 参数:
#   $1 - 用户
# 标志位:
#   -g|--group - 用户组
#   -h|--home - 用户家目录
#   -s|--system - 创建系统用户 (uid <= 999)
ensure_user_exists() {
    local user="${1:?user is missing}"
    local group=""
    local home=""
    local is_system_user=false

    # Validate arguments
    shift 1
    while [ "$#" -gt 0 ]; do
        case "$1" in
            -g|--group)
                shift
                group="${1:?missing group}"
                ;;
            -h|--home)
                shift
                home="${1:?missing home directory}"
                ;;
            -s|--system)
                is_system_user=true
                ;;
            *)
                echo "Invalid command line flag $1" >&2
                return 1
                ;;
        esac
        shift
    done

    if ! is_user_exists "$user"; then
        local -a user_args=("-N" "$user")
        $is_system_user && user_args+=("--system")
        useradd "${user_args[@]}" >/dev/null 2>&1
    fi

    if [[ -n "$group" ]]; then
        local -a group_args=("$group")
        $is_system_user && group_args+=("--system")
        ensure_group_exists "${group_args[@]}"
        usermod -g "$group" "$user" >/dev/null 2>&1
    fi

    if [[ -n "$home" ]]; then
        mkdir -p "$home"
        usermod -d "$home" "$user" >/dev/null 2>&1
        configure_permissions_ownership "$home" -d "775" -f "664" -u "$user" -g "$group"
    fi
}

# 获取系统可用内存大小(MB)信息
# 返回值:
#   内存大小(兆字节)
get_total_memory() {
    echo $(($(grep MemTotal /proc/meminfo | awk '{print $2}') / 1024))
}

# 获取以内存定量方式描述的机器类型
# 标志位:
#   --memory - 内存大小 (MB，可选)
# 返回值:
#   类型名称
get_machine_size() {
    local memory=""

    # 检测标志位
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            --memory)
                shift
                memory="${1:?missing memory}"
                ;;
            *)
                echo "Invalid command line flag $1" >&2
                return 1
                ;;
        esac
        shift
    done

    if [[ -z "$memory" ]]; then
        debug "Memory was not specified, detecting available memory automatically"
        memory="$(get_total_memory)"
    fi
    sanitized_memory=$(convert_to_mb "$memory")
    if [[ "$sanitized_memory" -gt 26000 ]]; then
        echo 2xlarge
    elif [[ "$sanitized_memory" -gt 13000 ]]; then
        echo xlarge
    elif [[ "$sanitized_memory" -gt 6000 ]]; then
        echo large
    elif [[ "$sanitized_memory" -gt 3000 ]]; then
        echo medium
    elif [[ "$sanitized_memory" -gt 1500 ]]; then
        echo small
    else
        echo micro
    fi
}

# 获取已定义的所有内存大小描述
# 返回值:
#   描述值列表
get_supported_machine_sizes() {
    echo micro small medium large xlarge 2xlarge
}

# 将以字符串表示的内存大小转换为以MB为单位的内存大小值 (i.e. 2G -> 2048)
# 参数:
#   $1 - 内存大小
# 返回值:
#   转换后的数值
convert_to_mb() {
    local amount="${1:-}"
    if [[ $amount =~ ^([0-9]+)(M|G) ]]; then
        size="${BASH_REMATCH[1]}"
        unit="${BASH_REMATCH[2]}"
        if [[ "$unit" = "G" ]]; then
            amount="$((size * 1024))"
        else
            amount="$size"
        fi
    fi
    echo "$amount"
}

# 如果禁用调试模式，将输出信息重定向至 /dev/null
# 参数:
#   $@ - 待执行的命令
debug_execute() {
    local bool="${ENV_DEBUG:-false}"
    shopt -s nocasematch
    if [[ "$bool" = 1 || "$bool" =~ ^(yes|true)$ ]]; then
        "$@"
    else
        "$@" >/dev/null 2>&1
    fi   
}

# 重试执行命令
# 参数:
#   $1 - 命令 (字符串)
#   $2 - 最大尝试次数. 默认值: 12
#   $3 - 重试前等待时间(秒). 默认值: 5
# 返回值:
#   0 / 1
retry_while() {
    local -r cmd="${1:?cmd is missing}"
    local -r retries="${2:-12}"
    local -r sleep_time="${3:-5}"
    local return_value=1

    read -r -a command <<< "$cmd"
    for ((i = 1 ; i <= retries ; i+=1 )); do
        "${command[@]}" && return_value=0 && break
        sleep "$sleep_time"
    done
    return $return_value
}

# 生成随机字符串
# 标志位:
#   -t|--type - 字符串类型 (ascii, alphanumeric, numeric). 默认值: ascii
#   -c|--count - 字符串长度. 默认值: 32
# 返回值:
#   字符串
generate_random_string() {
    local type="ascii"
    local count="32"
    local filter
    local result

    # 检测标志位
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            -t|--type)
                shift
                type="$1"
                ;;
            -c|--count)
                shift
                count="$1"
                ;;
            *)
                echo "Invalid command line flag $1" >&2
                return 1
                ;;
        esac
        shift
    done

    # 检测类型
    case "$type" in
        ascii)
            filter="[:print:]"
            ;;
        alphanumeric)
            filter="a-zA-Z0-9"
            ;;
        numeric)
            filter="0-9"
            ;;
        *)
        echo "Invalid type ${type}" >&2
        return 1
    esac
    # Obtain count + 10 lines from /dev/urandom to ensure that the resulting string has the expected size
    # Note there is a very small chance of strings starting with EOL character
    # Therefore, the higher amount of lines read, this will happen less frequently
    result="$(head -n "$((count + 10))" /dev/urandom | tr -dc "$filter" | head -c "$count")"
    echo "$result"
}

# 为指定字符串生成 MD5 值
# 参数:
#   $1 - 字符串
# 返回值:
#   字符串对应的 MD5
generate_md5_hash() {
  local -r str="${1:?missing input string}"
  echo -n "$str" | md5sum | awk '{print $1}'
}
