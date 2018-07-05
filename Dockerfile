FROM thimico/alpine:latest


ARG TINI_VERSION=0.17.0
ARG TINI_TARBALL=https://github.com/krallin/tini/releases/download/v$TINI_VERSION/tini-static-amd64
ARG TINI_GPG_KEY=6380DC428747F6C393FEACA59A84159D7001A4E5

ARG GOSU_VERSION=1.10
ARG GOSU_TARBALL=https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-amd64
ARG GOSU_GPG_KEY=B42F6819007F00F88E364FD4036A9C25BF357DD4

ARG GLIBC_VERSION=2.27-r0
ARG GLIBC_TARBALL=https://github.com/andyshinn/alpine-pkg-glibc/releases/download/$GLIBC_VERSION

ARG WORK=/usr/local/bin

WORKDIR $WORK
RUN set -ex; \
	apk add --no-cache bash libstdc++ curl wget tzdata tar unzip unrar p7zip; \
		ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime; \
		echo "Asia/Shanghai" > /etc/timezone; \
\
	apk add --no-cache --virtual .fetch-deps \
		gnupg \
		openssl \
	; gpg_verify () { file=$1;url=$2;url_asc=$3;gpg_key=$4;wget -qO "$file" "$url";if [ "$url_asc" ]; then wget -qO "$file".asc "$url_asc";export GNUPGHOME="$(mktemp -d)";gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$gpg_key";gpg --batch --verify "$file".asc "$file";rm -rf "$GNUPGHOME" "$file".asc;fi;}; \
		if $(gpg_verify tini "$TINI_TARBALL" "$TINI_TARBALL".asc $TINI_GPG_KEY); then \
			chmod +x tini && mv tini /sbin; \
		fi; \
		if $(gpg_verify gosu "$GOSU_TARBALL" "$GOSU_TARBALL".asc $GOSU_GPG_KEY); then \
			chmod +x gosu && mv gosu /sbin; \
		fi; \
	apk add --no-cache rethinkdb rethinkdb-doc \
	apk del .fetch-deps; \
\
	for pkg in glibc-$GLIBC_VERSION glibc-bin-$GLIBC_VERSION glibc-i18n-$GLIBC_VERSION; do \
		curl -fsSL $GLIBC_TARBALL/${pkg}.apk -o ${pkg}.apk; \
		apk add -q --allow-untrusted ${pkg}.apk && rm ${pkg}.apk; \
	done; \
\
	/usr/glibc-compat/bin/localedef --force --inputfile en_US --charmap UTF-8 en_US.UTF-8; \
	/usr/glibc-compat/sbin/ldconfig /lib /usr/lib /usr/glibc-compat/lib

VOLUME ["/rethinkdb_data"]

ENTRYPOINT ["tini", "-s", "--"]

CMD ["rethinkdb", "--bind", "all"]

EXPOSE 28015 29015 8080