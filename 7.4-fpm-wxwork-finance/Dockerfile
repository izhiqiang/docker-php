FROM zhiqiangwang/php:7.4-fpm

RUN apt-get update

RUN apt-get install -y --no-install-recommends git

ARG WXWORK_FINANCE_VERSION=v1.2

ENV WXWORK_FINANCE_SDK_VERSION=${WXWORK_FINANCE_VERSION}

ADD ext/wxwork_finance_sdk /usr/local/lib/php/wxwork_finance_sdk

RUN cd /tmp && git clone https://github.com/pangdahua/php7-wxwork-finance-sdk.git wxwork_finance && \
    mv /tmp/wxwork_finance/* /usr/local/lib/php/wxwork_finance_sdk

RUN cd /usr/local/lib/php/wxwork_finance_sdk \
    &&  phpize  \
    && ./configure --with-php-config=/usr/local/bin/php-config --with-wxwork-finance-sdk=./${WXWORK_FINANCE_VERSION} \
    && make && make install 

RUN rm -rf /usr/local/etc/php/conf.d/docker-php-ext-swoole.ini \
    && echo "extension=wxwork_finance_sdk" > /usr/local/etc/php/conf.d/swoole.ini \
    && echo "extension=swoole" >> /usr/local/etc/php/conf.d/swoole.ini 

RUN apt clean && rm -rf /tmp/* && rm -rf /var/lib/apt/lists/*
EXPOSE 9000