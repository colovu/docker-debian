# Ver: 1.0 by Endial Fang (endial@126.com)
#
FROM debian:stretch-slim

ARG gosu_ver=1.12

LABEL \
	"Version"="v9" \
	"Description"="Docker image for Debian 9(Stretch)." \
	"Dockerfile"="https://github.com/colovu/docker-debian" \
	"Vendor"="Endial Fang (endial@126.com)"

RUN set -eux; \
# 启用非交互模式安装软件包，规避Readline/Teletype等警告
	export DEBIAN_FRONTEND=noninteractive; \
	\
	mv /etc/apt/sources.list /etc/apt/sources.list.bak; \
	echo '\
deb http://mirrors.aliyun.com/debian/ stretch main contrib non-free \n\
deb-src http://mirrors.aliyun.com/debian/ stretch main contrib non-free \n\
deb http://mirrors.aliyun.com/debian/ stretch-updates main contrib non-free \n\
deb-src http://mirrors.aliyun.com/debian/ stretch-updates main contrib non-free \n\
deb http://mirrors.aliyun.com/debian/ stretch-proposed-updates main contrib non-free \n\
deb-src http://mirrors.aliyun.com/debian/ stretch-proposed-updates main contrib non-free \n\
deb http://mirrors.aliyun.com/debian/ stretch-backports main contrib non-free \n\
deb-src http://mirrors.aliyun.com/debian/ stretch-backports main contrib non-free \n\
' >/etc/apt/sources.list; \
	\
	apt-get update; \
	apt-get upgrade -y; \
	savedAptMark="$(apt-mark showmanual)"; \
	apt-get install -y locales; \
	\
# 安装 UTF-8 编码。需要安装 locales 软件包
	localedef -c -i en_US -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8; \
	echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen && locale-gen; \
	update-locale LANG=en_US.UTF-8 LANGUAGE=en_US.UTF-8 LC_ALL=en_US.UTF-8 LC_MESSAGES=POSIX && dpkg-reconfigure locales; \
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
	apt-get install -y --no-install-recommends $fetchDeps; \
	\
	dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"; \
	wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/${gosu_ver}/gosu-$dpkgArch"; \
	wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/${gosu_ver}/gosu-$dpkgArch.asc"; \
	\
# 安装软件包需要使用的GPG证书，并验证软件
	GPG_KEYS="0xB42F6819007F00F88E364FD4036A9C25BF357DD4"
	export GNUPGHOME="$(mktemp -d)"; \
	for key in ${GPG_KEYS}; do \
		gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys "${key}"|| \
		gpg --batch --keyserver pgp.mit.edu --recv-keys "${key}" || \
		gpg --batch --keyserver keys.gnupg.net --recv-keys "${key}" || \
		gpg --batch --keyserver keyserver.pgp.com --recv-keys "${key}"; \
	done; \
	gpg --batch --verify "/usr/local/bin/gosu.asc" "/usr/local/bin/gosu"; \
	command -v gpgconf > /dev/null && gpgconf --kill all; \
	rm -rf "$GNUPGHOME"; \
	\
	strip /usr/local/bin/gosu; \
	chmod +x /usr/local/bin/gosu; \
	rm -rf /usr/local/bin/gosu.asc; \
	\
# 查找新安装的应用相应的依赖软件包，并标识为'manual'，防止后续自动清理时被删除
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
# 删除临时软件包，清理缓存
	apt-get purge -y --auto-remove --force-yes -o APT::AutoRemove::RecommendsImportant=false $fetchDeps; \
	apt-get autoclean -y; \
	rm -rf /var/lib/apt/lists/*;
	\
# 验证新安装的软件是否工作正常，正常情况下放置在镜像制作最后
	gosu --version;

ENV LANG=en_US.UTF-8 \
	LANGUAGE=en_US.UTF-8 \
	LC_ALL=en_US.UTF-8

CMD []
