# Ver: 1.8 by Endial Fang (endial@126.com)
#

# 可变参数 ========================================================================

# 设置当前应用名称及版本
ARG app_name=debian-buster
ARG app_version=10

# 设置默认仓库地址，默认为 阿里云 仓库
ARG registry_url="registry.cn-shenzhen.aliyuncs.com"

# 设置 apt-get 源：default / tencent / ustc / aliyun / huawei
ARG apt_source=aliyun

# 编译镜像时指定用于加速的本地服务器地址
ARG local_url=""


# 1. 生成镜像 =====================================================================
FROM debian:buster-slim

# 声明需要使用的全局可变参数
ARG app_name
ARG app_version
ARG registry_url
ARG apt_source
ARG local_url

LABEL \
	"Version"="v${app_version}" \
	"Description"="Docker image for Debian OS v${app_version}(Buster)." \
	"Dockerfile"="https://github.com/colovu/docker-debian" \
	"Vendor"="Endial Fang (endial@126.com)"

# 拷贝默认的通用脚本文件
COPY prebuilds /

# 选择软件包源(Optional)，以加速后续软件包安装
RUN select_source ${apt_source}

# 增加 NSS_WRAPPER 支持；安装 curl 工具
RUN install_pkg locales apt-utils libnss-wrapper curl

# 增加locales支持，并设置默认为 UTF-8
RUN set -eux; \
	sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen; \
	sed -i -e 's/# zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/' /etc/locale.gen; \
	locale-gen; \
	update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 LANGUAGE=en_US.UTF-8 LC_MESSAGES=POSIX; \
	dpkg-reconfigure -f noninteractive locales;

# 配置时区默认为 Shanghai
RUN set -eux; \
	ln -fs /usr/share/zoneinfo/Asia/Shanghai /etc/localtime; \
	dpkg-reconfigure -f noninteractive tzdata; 

ENV LANG=en_US.UTF-8 \
	LANGUAGE=en_US.UTF-8 \
	LC_ALL=en_US.UTF-8

WORKDIR /

# 应用程序的服务命令，必须使用非守护进程方式运行。如果使用变量，则该变量必须在运行环境中存在（ENV可以获取）
CMD []
