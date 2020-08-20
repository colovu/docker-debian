# Ver: 1.0 by Endial Fang (endial@126.com)
#
FROM debian:buster-slim

# ARG参数使用"--build-arg"指定，如 "--build-arg apt_source=tencent"
# sources.list 可使用版本：default / tencent / ustc / aliyun / huawei
ARG apt_source=default

# 编译镜像时指定本地服务器地址，如 "--build-arg local_url=http://172.29.14.108/dist-files/"
ARG local_url=""

ARG gosu_ver=1.12

LABEL \
	"Version"="v10" \
	"Description"="Docker image for Debian 10(Buster)." \
	"Dockerfile"="https://github.com/colovu/docker-debian" \
	"Vendor"="Endial Fang (endial@126.com)"

COPY sources/* /etc/apt/

# 镜像内相应应用及依赖软件包的安装脚本；以下脚本可按照不同需求拆分为多个段，但需要注意各个段在结束前需要清空缓存
RUN \
# 设置程序使用静默安装，而非交互模式；默认情况下，类似 tzdata/gnupg/ca-certificates 等程序配置需要交互
	export DEBIAN_FRONTEND=noninteractive; \
	\
# 设置 shell 执行参数，分别为 -e(命令执行错误则退出脚本) -u(变量未定义则报错) -x(打印实际待执行的命令行)
	set -eux; \
	\
# 更改源为当次编译指定的源
	cp /etc/apt/sources.list.${apt_source} /etc/apt/sources.list; \
	\
	apt-get update; \
	apt-get upgrade -y; \
	apt-get install -y --no-install-recommends locales apt-utils; \
	savedAptMark="$(apt-mark showmanual)"; \
	\
# 配置系统默认编码为 en_US.UTF-8 编码
	sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && locale-gen; \
	update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 LANGUAGE=en_US.UTF-8 LC_MESSAGES=POSIX; \
	dpkg-reconfigure -f noninteractive locales; \
	\
# 配置系统默认 TimeZone 信息为 中国/上海
	ln -fs /usr/share/zoneinfo/Asia/Shanghai /etc/localtime; \
	dpkg-reconfigure -f noninteractive tzdata; \
	\
	fetchDeps=" \
		ca-certificates \
		wget \
		\
		gnupg \
		dirmngr \
		\
		binutils \
	"; \
	apt-get install -y --no-install-recommends ${fetchDeps}; \
	\
	dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"; \
	if [ -n "${local_url}" ]; then \
		wget -O /usr/local/bin/gosu "${local_url}/gosu-${dpkgArch}"; \
		wget -O /usr/local/bin/gosu.asc "${local_url}/gosu-${dpkgArch}.asc"; \
	else \
		wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/${gosu_ver}/gosu-$dpkgArch"; \
		wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/${gosu_ver}/gosu-$dpkgArch.asc"; \
	fi; \
	\
# 安装软件包需要使用的GPG证书，并验证软件
	export GPG_KEYS="0xB42F6819007F00F88E364FD4036A9C25BF357DD4"; \
	export GNUPGHOME="$(mktemp -d)"; \
	for key in ${GPG_KEYS}; do \
		gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys "${key}"|| \
		gpg --batch --keyserver pgp.mit.edu --recv-keys "${key}" || \
		gpg --batch --keyserver keys.gnupg.net --recv-keys "${key}" || \
		gpg --batch --keyserver keyserver.pgp.com --recv-keys "${key}"; \
	done; \
	gpg --batch --verify "/usr/local/bin/gosu.asc" "/usr/local/bin/gosu"; \
	command -v gpgconf > /dev/null && gpgconf --kill all; \
	rm -rf "${GNUPGHOME}"; \
	\
	strip /usr/local/bin/gosu; \
	chmod +x /usr/local/bin/gosu; \
	rm -rf /usr/local/bin/gosu.asc; \
	\
# 查找新安装的应用及应用依赖软件包，并标识为'manual'，防止后续自动清理时被删除
	apt-mark auto '.*' > /dev/null; \
	{ [ -z "$savedAptMark" ] || apt-mark manual $savedAptMark; }; \
	find /usr/local -type f -executable -exec ldd '{}' ';' \
		| awk '/=>/ { print $(NF-1) }' \
		| sort -u \
		| xargs -r dpkg-query --search \
		| cut -d: -f1 \
		| sort -u \
		| xargs -r apt-mark manual; \
	\
# 删除安装的临时依赖软件包，清理缓存
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false ${fetchDeps}; \
	apt-get autoclean -y; \
	rm -rf /var/lib/apt/lists/*; \
	\
# 验证新安装的软件是否工作正常，正常情况下放置在镜像制作最后
	gosu --version;
	:;

ENV LANG=en_US.UTF-8 \
	LANGUAGE=en_US.UTF-8 \
	LC_ALL=en_US.UTF-8

CMD []
