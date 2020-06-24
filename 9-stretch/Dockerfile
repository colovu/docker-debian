FROM debian:stretch-slim

ARG gosu_ver=1.12

LABEL \
	"Version"="v9" \
	"Description"="Docker image for Debian 9(Stretch)." \
	"Dockerfile"="https://github.com/colovu/docker-debian" \
	"Vendor"="Endial Fang (endial@126.com)"

ENV GOSU_VERSION=${gosu_ver} \
	GPG_KEYS="0xB42F6819007F00F88E364FD4036A9C25BF357DD4"

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
	apt update; \
	apt upgrade -y; \
	savedAptMark="$(apt-mark showmanual)"; \
	apt install -y locales; \
	\
	localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8; \
	\
	fetchDeps=" \
		ca-certificates \
		wget \
		gnupg \
		dirmngr \
		binutils \
	"; \
	apt install -y --no-install-recommends $fetchDeps; \
	\
	dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"; \
	wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch"; \
	wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc"; \
	\
# 安装软件包需要使用的GPG证书
	export GNUPGHOME="$(mktemp -d)"; \
	for key in ${GPG_KEYS}; do \
		gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys "${key}"|| \
		gpg --batch --keyserver pgp.mit.edu --recv-keys "${key}" || \
		gpg --batch --keyserver keys.gnupg.net --recv-keys "${key}" || \
		gpg --batch --keyserver keyserver.pgp.com --recv-keys "${key}"; \
	done; \
	gpg --batch --verify "/usr/local/bin/gosu.asc" "/usr/local/bin/gosu"; \
	\
	command -v gpgconf > /dev/null && gpgconf --kill all; \
	rm -rf "$GNUPGHOME"; \
	\
	strip /usr/local/bin/gosu; \
	chmod +x /usr/local/bin/gosu; \
# 验证新安装的软件是否工作正常
	gosu nobody true; \
	\
# 查找新安装的应用相应的依赖软件包，并表示为'manual'，防止后续自动清理时被删除
	apt-mark auto '.*' > /dev/null; \
	{ [ -z "$savedAptMark" ] || apt-mark manual $savedAptMark; }; \
	find /usr/local -type f -executable -exec ldd '{}' ';' \
		| awk '/=>/ { print $(NF-1) }' \
		| sort -u \
		| xargs -r dpkg-query --search \
		| cut -d: -f1 \
		| sort -u \
		| xargs -r apt-mark manual; \
# 删除临时软件包，清理缓存
	apt purge -y --auto-remove --force-yes -o APT::AutoRemove::RecommendsImportant=false $fetchDeps; \
	apt autoclean -y; \
	rm -rf /var/lib/apt/lists/*;

ENV LANG en_US.utf8

CMD []
