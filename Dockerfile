FROM postgres:15

LABEL maintainer="loyayz - https://loyayz.com"

ENV SCWS_URL http://www.xunsearch.com/scws/down/scws-1.2.3.tar.bz2
ENV ZHPARSER_URL https://github.com/amutu/zhparser/archive/refs/heads/master.tar.gz
ENV SAFEUPDATE_URL https://github.com/eradman/pg-safeupdate/archive/master.tar.gz
ENV PG_CRON_URL https://github.com/citusdata/pg_cron/archive/main.tar.gz

RUN apt-get update \
      && apt-get install -y --no-install-recommends \
           ca-certificates \
           wget \
           bzip2 \
           make \
           gcc \
           libc6-dev \
           postgresql-15-cron \
           postgresql-server-dev-$PG_MAJOR \
           \
      ## install scws
      && cd / \
      && wget -q -O - $SCWS_URL | tar xjf - \
      && SCWS_DIR=${SCWS_URL##*/} \
      && SCWS_DIR=${SCWS_DIR%%.tar*} \
      && cd $SCWS_DIR && ./configure && make install \
      ## install zhparser
      && cd / \
      && wget -q -O - $ZHPARSER_URL | tar xzf - \
      && cd zhparser-master && make install \
      ## install pg-safeupdate
      && cd / \
      && wget -q -O - $SAFEUPDATE_URL | tar xzf - \
      && cd pg-safeupdate-master && gmake && make install \
      # clean
      && apt-get purge -y \
            ca-certificates \
            wget \
            bzip2 \
            make \
            gcc \
            libc6-dev \
            postgresql-server-dev-$PG_MAJOR \
      && apt-get autoremove --purge -y \
      && rm -rf /$SCWS_DIR \
            /zhparser-master \
            /pg-safeupdate-master \
            /var/lib/apt/lists/*

RUN mkdir -p /docker-entrypoint-initdb.d
COPY  config/init_extension.sh /docker-entrypoint-initdb.d/
RUN chmod 755 /docker-entrypoint-initdb.d/init_extension.sh
