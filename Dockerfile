FROM postgres:15

LABEL maintainer="loyayz - https://loyayz.com"

ENV SCWS_URL http://www.xunsearch.com/scws/down/scws-1.2.3.tar.bz2
ENV ZHPARSER_URL https://github.com/amutu/zhparser/archive/refs/heads/master.tar.gz
ENV SAFEUPDATE_URL https://github.com/eradman/pg-safeupdate/archive/master.tar.gz

# 更新并安装基本依赖
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates wget bzip2 make gcc libc6-dev postgresql-15-cron postgresql-server-dev-15

# 安装 libc-bin
RUN apt-get install -y libc-bin

# 安装 SCWS
RUN cd / && \
    wget -q -O - $SCWS_URL | tar xjf - && \
    SCWS_DIR=scws-1.2.3 && \
    cd $SCWS_DIR && ./configure && make install

# 安装 zhparser
RUN cd / && \
    wget -q -O - $ZHPARSER_URL | tar xzf - && \
    cd zhparser-master && make install

# 安装 pg-safeupdate
RUN cd / && \
    wget -q -O - $SAFEUPDATE_URL | tar xzf - && \
    cd pg-safeupdate-master && gmake && make install

# 清理
RUN apt-get purge -y ca-certificates wget bzip2 make gcc libc6-dev postgresql-server-dev-15 && \
    apt-get autoremove --purge -y && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /docker-entrypoint-initdb.d
COPY config/init_extension.sh /docker-entrypoint-initdb.d/
RUN chmod 755 /docker-entrypoint-initdb.d/init_extension.sh
