## 构建

~~~
docker build -f 7.4-fpm/Dockerfile -t zhiqiangwang/php:7.4-fpm  .
docker build -f 7.4-cli/Dockerfile -t zhiqiangwang/php:7.4-cli  .
docker build -f 8.1-fpm/Dockerfile -t zhiqiangwang/php:8.1-fpm  .
docker build -f 8.1-cli/Dockerfile -t zhiqiangwang/php:8.1-cli  .
docker build -f 8.2-fpm/Dockerfile -t zhiqiangwang/php:8.2-fpm  .
docker build -f 8.2-cli/Dockerfile -t zhiqiangwang/php:8.2-cli  .


docker build -f 7.4-fpm-wxwork-finance/Dockerfile -t zhiqiangwang/php:7.4-fpm-wxwork-finance .
docker build -f 7.4-cli-wxwork-finance/Dockerfile -t zhiqiangwang/php:7.4-cli-wxwork-finance .

docker build -f phpmyadmin/Dockerfile -t zhiqiangwang/php:phpmyadmin .

docker build --build-arg="IMAGE_TAG=7.4-fpm" -f Dockerfile.nginx -t zhiqiangwang/php:7.4-fpm-nginx  .
docker build --build-arg="IMAGE_TAG=7.4-fpm" -f Dockerfile.composer -t zhiqiangwang/php:7.4-fpm-composer  .

~~~


## 启动容器
~~~
docker run --name myphp -p 9000:9000 -v /data/wwwroot/laravel/:/var/www/html -d zhiqiangwang/php:7.4-fpm 

docker run --name myphp -p 8080:80 -d zhiqiangwang/php:7.4-fpm-nginx
~~~

## 常见配置目录

- /etc/nginx
- /usr/local/etc
- /etc/supervisor
- /var/spool/cron/crontabs

## 常见命令

- /etc/init.d/cron

~~~
echo * * * * * Command >> /var/spool/cron/crontabs/root
chmod 600 /var/spool/cron/crontabs/root
/etc/init.d/cron start
~~~
- nginx -g "daemon off;"
- php -i | grep php.ini
-  php-fpm --nodaemonize

## 将日志打印到docker运行控制

~~~
ln -sf /dev/stdout /usr/local/openresty/nginx/logs/access.log
~~~

## 启动nginx+php容器

加入已经启动了一个nginx容器

~~~
docker run --name nginx  -d -p 8080:80 -v tp:/code nginx:latest
~~~

我们需要做的是

~~~
创建网络
docker network create php-nginx-network
将nginx加入到php-nginx-network网络
docker network connect php-nginx-network nginx
启动php容器加入到php-nginx-network网络
docker run --name myphp -v tp:/var/www/html --network php-nginx-network -p 9000:9000 -d zhiqiangwang/php:8.2-fpm-composer
~~~

> 需要注意的是nginx 配置 root目录一定是php中的目录/var/www/html
>
> fastcgi_pass 使用myphp:9000监听即可

### thinkphp nginx config

~~~
server {
  listen 80 default_server;
  listen [::]:80 default_server;
  root /var/www/html/public;
  index index.php;
  server_name _;
  location / {
    if (!-e $request_filename){
    	rewrite  ^(.*)$  /index.php?s=$1  last;   break;
    }
  }
  location ~ \.php$ {
    fastcgi_pass 127.0.0.1:9000;
    fastcgi_index index.php;
    fastcgi_param SCRIPT_FILENAME $DOCUMENT_ROOT$fastcgi_script_name;
    include fastcgi_params;
  }
}
~~~

### 启动容器

~~~
docker run --name myphp -p 8080:80 -v /data/thinkphp:/var/www/html -v /data/thinkphp/thinkphp.conf:/etc/nginx/sites-enabled/default  -d zhiqiangwang/php:7.4-fpm-nginx
~~~
