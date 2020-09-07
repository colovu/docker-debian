# Ver: 1.2 by Endial Fang (endial@126.com)
#
FROM colovu/dbuilder as builder

# sources.list 可使用版本：default / tencent / ustc / aliyun / huawei
ARG apt_source=tencent

# 编译镜像时指定用于加速的本地服务器地址
ARG local_url=""

WORKDIR /usr/local

RUN set -eux; \
	appVersion=1.12; \
	appName=gosu-"$(dpkg --print-architecture | awk -F- '{ print $NF }')"; \
	appKeys="0xB42F6819007F00F88E364FD4036A9C25BF357DD4"; \
	appUrls=" \
		${local_url}/gosu \
		https://github.com/tianon/gosu/releases/download/${appVersion} \
		"; \
	download_pkg install ${appName} "${appUrls}" -g "${appKeys}"; \
	chmod +x /usr/local/bin/${appName}; \
# 验证安装的应用软件是否正常
	${appName} nobody true;

# 镜像生成 ========================================================================
FROM debian:buster-slim
ARG apt_source=default

LABEL   "Version"="v10" \
	"Description"="Docker image for Debian 10(Buster)." \
	"Dockerfile"="https://github.com/colovu/docker-debian" \
	"Vendor"="Endial Fang (endial@126.com)"

COPY prebuilds /
RUN select_source ${apt_source}
RUN install_pkg locales apt-utils tini libnss-wrapper
RUN set -eux; \
	sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && locale-gen; \
	update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 LANGUAGE=en_US.UTF-8 LC_MESSAGES=POSIX; \
	dpkg-reconfigure -f noninteractive locales; \
	\
	ln -fs /usr/share/zoneinfo/Asia/Shanghai /etc/localtime; \
	dpkg-reconfigure -f noninteractive tzdata; 

COPY --from=builder /usr/local/bin/gosu-amd64 /usr/local/bin/gosu

WORKDIR /

ENV LANG=en_US.UTF-8 \
	LANGUAGE=en_US.UTF-8 \
	LC_ALL=en_US.UTF-8

CMD []
