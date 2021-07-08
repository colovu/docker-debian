#!/bin/bash
# Ver: 1.1 by Endial Fang (endial@126.com)
#
# 文件管理函数库

# 加载依赖项
. /usr/local/scripts/liblog.sh          # 日志输出函数库

# 函数列表

# 域名解析
# 参数:
#   $1 - 需要解析的主机名
dns_lookup() {
    local host="${1:?host is missing}"
    getent ahosts "$host" | awk '/STREAM/ {print $1 }'
}

# 尝试解析域名并返回对应的 IP
# 参数:
#   $1 - 主机名
#   $2 - 尝试次数
#   $3 - 重试间隔时间（秒）
wait_for_dns_lookup() {
    local hostname="${1:?hostname is missing}"
    local retries="${2:-5}"
    local seconds="${3:-1}"
    check_host() {
        if [[ $(dns_lookup "$hostname") == "" ]]; then
            false
        else
            true
        fi
    }
    # Wait for the host to be ready
    retry_while "check_host ${hostname}" "$retries" "$seconds"
    dns_lookup "$hostname"
}

# 获取当前主机 IP
get_machine_ip() {
    local -a ip_addresses
    local hostname
    hostname="$(hostname)"
    read -r -a ip_addresses <<< "$(dns_lookup "$hostname" | xargs echo)"
    if [[ "${#ip_addresses[@]}" -gt 1 ]]; then
        LOG_W "Found more than one IP address associated to hostname ${hostname}: ${ip_addresses[*]}, will use ${ip_addresses[0]}"
    elif [[ "${#ip_addresses[@]}" -lt 1 ]]; then
        LOG_E "Could not find any IP address associated to hostname ${hostname}"
        exit 1
    fi
    echo "${ip_addresses[0]}"
}

# Check if the provided argument is a resolved hostname
# 参数:
#   $1 - 待检测的主机名
# 返回值:
#   布尔值
is_hostname_resolved() {
    local -r host="${1:?missing value}"
    if [[ -n "$(dns_lookup "$host")" ]]; then
        true
    else
        false
    fi
}

# 解析 URL
# 参数:
#   $1 - URI 字符串  
#   $2 - 类型字符串. 有效值 (scheme, authority, userinfo, host, port, path, query or fragment)
# 返回值:
#   字符串
parse_uri() {
    local uri="${1:?uri is missing}"
    local component="${2:?component is missing}"

    # Solution based on https://tools.ietf.org/html/rfc3986#appendix-B with
    # additional sub-expressions to split authority into userinfo, host and port
    # Credits to Patryk Obara (see https://stackoverflow.com/a/45977232/6694969)
    local -r URI_REGEX='^(([^:/?#]+):)?(//((([^@/?#]+)@)?([^:/?#]+)(:([0-9]+))?))?(/([^?#]*))?(\?([^#]*))?(#(.*))?'
    #                    ||            |  |||            |         | |            | |         |  |        | |
    #                    |2 scheme     |  ||6 userinfo   7 host    | 9 port       | 11 rpath  |  13 query | 15 fragment
    #                    1 scheme:     |  |5 userinfo@             8 :...         10 path     12 ?...     14 #...
    #                                  |  4 authority
    #                                  3 //...
    local index=0
    case "$component" in
        scheme)
            index=2
            ;;
        authority)
            index=4
            ;;
        userinfo)
            index=6
            ;;
        host)
            index=7
            ;;
        port)
            index=9
            ;;
        path)
            index=10
            ;;
        query)
            index=13
            ;;
        fragment)
            index=14
            ;;
        *)
            stderr_print "unrecognized component $component"
            return 1
            ;;
    esac
    [[ "$uri" =~ $URI_REGEX ]] && echo "${BASH_REMATCH[${index}]}"
}
