#!/bin/bash

set -eux

versions=("7.4" "8.1" "8.2")

for version in "${versions[@]}"; do
  # 构建 fpm 镜像
  if [[ -f Dockerfile.${version}-fpm ]]; then
    docker build -f Dockerfile.${version}-fpm -t zhiqiangwang/php:${version}-fpm .
    docker push zhiqiangwang/php:${version}-fpm
  fi

  # 构建 cli 镜像
  if [[ -f Dockerfile.${version}-cli ]]; then
    docker build -f Dockerfile.${version}-cli -t zhiqiangwang/php:${version}-cli .
    docker push zhiqiangwang/php:${version}-cli
  fi

  # 构建 fpm-nginx 镜像
  if [[ -f Dockerfile.nginx ]]; then
    docker build --build-arg="IMAGE_TAG=${version}-fpm" -f Dockerfile.nginx -t zhiqiangwang/php:${version}-fpm-nginx .
    docker push zhiqiangwang/php:${version}-fpm-nginx
  fi

  # 构建 fpm-composer 镜像
  if [[ -f Dockerfile.composer ]]; then
    docker build --build-arg="IMAGE_TAG=${version}-fpm" -f Dockerfile.composer -t zhiqiangwang/php:${version}-fpm-composer .
    docker push zhiqiangwang/php:${version}-fpm-composer
  fi
done


# 额外的构建
if [[ -f Dockerfile.7.4-fpm-wxwork-finance ]]; then
  docker build -f Dockerfile.7.4-fpm-wxwork-finance -t zhiqiangwang/php:7.4-fpm-wxwork-finance .
  docker push zhiqiangwang/php:7.4-fpm-wxwork-finance 
fi


if [[ -f Dockerfile.7.4-cli-wxwork-finance ]]; then
  docker build -f Dockerfile.7.4-cli-wxwork-finance -t zhiqiangwang/php:7.4-cli-wxwork-finance .
  docker push zhiqiangwang/php:7.4-cli-wxwork-finance
fi

if [[ -f Dockerfile.phpmyadmin ]]; then
  docker build -f Dockerfile.phpmyadmin -t zhiqiangwang/php:phpmyadmin .
  docker push zhiqiangwang/php:phpmyadmin
fi


