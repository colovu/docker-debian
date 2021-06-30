# Ver: 1.4 by Endial Fang (endial@126.com)
#

# 预处理 =========================================================================
ARG registry_url="registry.cn-shenzhen.aliyuncs.com"
FROM ${registry_url}/colovu/dbuilder as builder

# sources.list 可使用版本：default / tencent / ustc / aliyun / huawei
ARG apt_source=aliyun

# 编译镜像时指定用于加速的本地服务器地址
ARG local_url=""

WORKDIR /usr/local

# 选择软件包源(Optional)，以加速后续软件包安装
RUN select_source ${apt_source};

# 下载并解压软件包
RUN set -eux; \
	appVersion=1.13; \
	appName=gosu-"$(dpkg --print-architecture | awk -F- '{ print $NF }')"; \
	appKeys="0xB42F6819007F00F88E364FD4036A9C25BF357DD4"; \
	[ ! -z ${local_url} ] && localURL=${local_url}/gosu; \
	appUrls="${localURL:-}/${appVersion} \
		https://github.com/tianon/gosu/releases/download/${appVersion} \
		"; \
	download_pkg install ${appName} "${appUrls}" ; \
	chmod +x /usr/local/bin/${appName};

# 镜像生成 ========================================================================
FROM debian:buster-slim

# sources.list 可使用版本：default / tencent / ustc / aliyun / huawei
ARG apt_source=aliyun

ENV APP_NAME=debian-buster

LABEL \
	"Version"="v10" \
	"Description"="Docker image for Debian OS v10(Buster)." \
	"Dockerfile"="https://github.com/colovu/docker-debian" \
	"Vendor"="Endial Fang (endial@126.com)"

# 拷贝默认的通用脚本文件
COPY prebuilds /

# 从预处理过程中拷贝软件包
COPY --from=builder /usr/local/bin/gosu-amd64 /usr/local/bin/gosu

# 选择软件包源(Optional)，以加速后续软件包安装
RUN select_source ${apt_source}

# 增加 NSS_WRAPPER 支持
RUN install_pkg locales apt-utils tini libnss-wrapper curl

# 增加locales支持，并设置默认为 UTF-8；配置时区默认为 Shanghai
RUN set -eux; \
	sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen; \
	sed -i -e 's/# zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/' /etc/locale.gen; \
	locale-gen; \
	update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 LANGUAGE=en_US.UTF-8 LC_MESSAGES=POSIX; \
	dpkg-reconfigure -f noninteractive locales; \
	\
	ln -fs /usr/share/zoneinfo/Asia/Shanghai /etc/localtime; \
	dpkg-reconfigure -f noninteractive tzdata; 
ENV LANG=en_US.UTF-8 \
	LANGUAGE=en_US.UTF-8 \
	LC_ALL=en_US.UTF-8

# 执行预处理脚本，并验证安装的软件包
RUN set -eux; \
	gosu nobody true; \
	gosu --version; \
	tini --version;

WORKDIR /

# 应用程序的服务命令，必须使用非守护进程方式运行。如果使用变量，则该变量必须在运行环境中存在（ENV可以获取）
CMD []

