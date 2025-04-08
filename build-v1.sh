#!/bin/bash

set -eux

versions=("7.4" "8.1" "8.2")

# 循环构建镜像
for version in "${versions[@]}"; do
  docker build -f Dockerfile.${version}-fpm -t zhiqiangwang/php:${version}-fpm  .
  docker build -f Dockerfile.${version}-cli -t zhiqiangwang/php:${version}-cli  .
  docker build --build-arg="IMAGE_TAG=${version}-fpm" -f Dockerfile.nginx -t zhiqiangwang/php:${version}-fpm-nginx .
  docker build --build-arg="IMAGE_TAG=${version}-fpm" -f Dockerfile.composer -t zhiqiangwang/php:${version}-fpm-composer  .
  # push
  docker push zhiqiangwang/php:${version}-fpm
  docker push zhiqiangwang/php:${version}-cli
  docker push zhiqiangwang/php:${version}-fpm-nginx
  docker push zhiqiangwang/php:${version}-fpm-composer
done

docker build -f Dockerfile.7.4-fpm-wxwork-finance -t zhiqiangwang/php:7.4-fpm-wxwork-finance .
docker build -f Dockerfile.7.4-cli-wxwork-finance -t zhiqiangwang/php:7.4-cli-wxwork-finance .
docker build -f Dockerfile.phpmyadmin -t zhiqiangwang/php:phpmyadmin .

# push
docker push zhiqiangwang/php:7.4-fpm-wxwork-finance
docker push zhiqiangwang/php:7.4-cli-wxwork-finance
docker push zhiqiangwang/php:phpmyadmin