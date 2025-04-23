#!/bin/bash

set -eux

apt-get update

apt install -y --no-install-recommends procps coreutils cron autoconf make gcc wget
# php default ext
docker-php-ext-install  -j$(nproc) bcmath calendar exif gettext dba mysqli pcntl pdo_mysql shmop sysvmsg sysvsem sysvshm

# php zip ext
apt-get install -y --no-install-recommends zip unzip libzip-dev
docker-php-ext-install zip

# php gd ext
apt-get install -y --no-install-recommends libfreetype6-dev libjpeg62-turbo-dev libpng-dev
docker-php-source extract && cd /usr/src/php/ext/gd \
    && docker-php-ext-configure gd --with-jpeg=/usr/include --with-freetype=/usr/include/freetype2 \
    && make && make install \
    && docker-php-ext-install gd

# php redis ext
if [ -n "${REDIS_VERSION+x}" ]; then
    pecl install http://pecl.php.net/get/redis-${REDIS_VERSION}.tgz && docker-php-ext-enable redis
fi

# php mongodb ext
if [ -n "${MONGODB_VERSION+x}" ]; then
    pecl install http://pecl.php.net/get/mongodb-${MONGODB_VERSION}.tgz && docker-php-ext-enable mongodb
fi

# http://pecl.php.net/package/rdkafka
if [ -n "${RDKAFKA_VERSION+x}" ]; then
    apt install -y --no-install-recommends librdkafka-dev
    pecl install http://pecl.php.net/get/rdkafka-${RDKAFKA_VERSION}.tgz && docker-php-ext-enable rdkafka
fi

# http://pecl.php.net/package/swoole
if [ -n "${SWOOLE_VERSION+x}" ]; then
    docker-php-ext-install  -j$(nproc) sockets
    apt-get install -y --no-install-recommends openssl libssl-dev libcurl4-openssl-dev
    cd /tmp && wget https://github.com/swoole/swoole-src/archive/v${SWOOLE_VERSION}.tar.gz -O swoole.tar.gz \
    && mkdir /tmp/swoole \
    && tar -xf swoole.tar.gz -C /tmp/swoole --strip-components=1 \
    && cd /tmp/swoole && phpize \
    && ./configure --enable-openssl --enable-http2 --enable-swoole-json --enable-swoole-curl --enable-mysqlnd --enable-sockets \
    && make && make install \
    && docker-php-ext-enable swoole
fi

if [ -n "${SOLR_VERSION+x}" ]; then
    apt-get install -y --no-install-recommends libcurl4-gnutls-dev libxml2-dev
    pecl install http://pecl.php.net/get/solr-${SOLR_VERSION}.tgz && docker-php-ext-enable solr
fi

apt clean
rm -rf /var/lib/apt/lists/*
rm -rf /tmp/*