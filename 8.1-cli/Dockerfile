FROM php:8.1-cli


# http://pecl.php.net/package/redis
ENV REDIS_VERSION=6.0.2
# http://pecl.php.net/package/mongodb
ENV MONGODB_VERSION=1.16.2
# http://pecl.php.net/package/rdkafka
ENV RDKAFKA_VERSION=6.0.3
# http://pecl.php.net/package/swoole
ENV SWOOLE_VERSION=5.1.0
# http://pecl.php.net/package/solr
ENV SOLR_VERSION=2.6.0

ADD sh/ext-install.sh /tmp/ext-install.sh
RUN chmod +x /tmp/ext-install.sh && sh /tmp/ext-install.sh
