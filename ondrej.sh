#!/bin/bash

# ===============================================================
# 🚀 ondrej安装
#
# 👉 支持系统：
#       - Ubuntu
# 👉 使用方式（直接运行）：
#      bash -c "$(curl -fsSL https://raw.githubusercontent.com/chihqiang/docker-php/main/ondrej.sh)"
#
# 🧑‍💻 作者：zhiqiang
# ===============================================================

# 检查是否使用 root 用户
if [[ $(id -u) -ne 0 ]]; then
    echo "❌ 请使用 root 用户或具有 sudo 权限的用户执行此脚本！"
    exit 1
fi

# 检查操作系统
OS=$(lsb_release -i | awk -F: '{print $2}' | sed 's/^[ \t]*//')  # 直接去掉前后空格
if [[ "$OS" != "Ubuntu" && "$OS" != "Debian" ]]; then
    echo "❌ 此脚本仅支持 Ubuntu 或 Debian 系统！"
    exit 1
fi

# 可选版本列表
versions=("7.4" "8.0" "8.1" "8.2" "8.3")
echo "请选择要安装的 PHP 版本："
select version in "${versions[@]}"; do
    if [[ -n "$version" ]]; then
        echo "你选择了 PHP $version"
        break
    else
        echo "无效选择，请重新输入"
    fi
done

# 更新并添加 PPA
echo "🔄 正在更新软件包列表..."
apt update
echo "🔄 正在安装软件包支持工具..."
apt install -y software-properties-common
echo "🔄 正在添加 PHP PPA 仓库..."
add-apt-repository -y ppa:ondrej/php
echo "🔄 更新软件包列表..."
apt update

# 安装 PHP 及常用模块
EXTENSIONS=(
    "cli"
    "fpm"
    "common"
    "mbstring"
    "xml"
    "gd"
    "curl"
    "mysql"
    "zip"
    "bcmath"
    "intl"
    "readline"
    "bz2"
    "redis"
    "memcached"
    "opcache"
    "soap"
    "swoole"
    "imagick"
)

for ext in "${EXTENSIONS[@]}"; do
    echo "🔧 正在安装 PHP $version 扩展：$ext"
    if ! apt install -y "php$version-$ext"; then
        echo "⚠️ PHP $version 扩展 $ext 安装失败，继续安装其他扩展..."
    fi
done

# 安装完成提示
php_path="/usr/bin/php$version"
if [[ -x "$php_path" ]]; then
    echo "🎉 PHP $version 安装完成：$php_path"
    "$php_path" -v
else
    echo "❌ PHP $version 安装失败！"
    exit 1
fi

# 动态配置 PHP-FPM 路径
CONF_PATH="/etc/php/$version/fpm/pool.d/www.conf"
PHP_FPM_SERVICE="php$version-fpm"

read -p "请输入 PHP-FPM 的监听地址（默认：127.0.0.1:9000）: " input_address
LISTEN_ADDRESS="${input_address:-127.0.0.1:9000}"
RESERVE_MEM_MB=2048      # 系统预留内存
DEFAULT_MEM_PER_CHILD=40 # 默认单个 PHP-FPM 子进程内存占用 MB（如检测失败）

# 获取内存信息
echo "🔍 正在获取系统内存信息..."
TOTAL_MEM=$(free -m | awk '/Mem:/ {print $2}')
AVAIL_MEM=$((TOTAL_MEM - RESERVE_MEM_MB))

# 获取平均 PHP-FPM 子进程内存占用
echo "🔍 正在计算 PHP-FPM 子进程平均内存占用..."
MEM_PER_CHILD=$(ps --no-headers -o rss -C php-fpm | awk '{ sum+=$1; count+=1 } END { if(count>0) print int(sum/count/1024); else print 0 }')
if [[ $MEM_PER_CHILD -lt 10 ]]; then
    MEM_PER_CHILD=$DEFAULT_MEM_PER_CHILD
fi

# 计算合理的 max_children
MAX_CHILDREN=$((AVAIL_MEM / MEM_PER_CHILD))
# 获取 CPU 核心数
CPU_CORES=$(nproc)
START_SERVERS=$((CPU_CORES * 2))
MIN_SPARE_SERVERS=$((CPU_CORES * 2))
MAX_SPARE_SERVERS=$((CPU_CORES * 4))
# 动态生成 pm.max_requests 和 request_terminate_timeout
MAX_REQUESTS=$((CPU_CORES * 1000))
if [[ $MAX_REQUESTS -gt 10000 ]]; then
    MAX_REQUESTS=10000
fi

if [[ $CPU_CORES -lt 4 ]]; then
    TERMINATE_TIMEOUT="60s"
else
    TERMINATE_TIMEOUT="30s"
fi

echo "🔍 系统总内存: ${TOTAL_MEM}MB"
echo "🔍 可用内存: ${AVAIL_MEM}MB"
echo "🔍 平均 PHP 子进程内存: ${MEM_PER_CHILD}MB"
echo "🔧 计算得到 pm.max_children: ${MAX_CHILDREN}"
echo "🔍 最大 PHP 子进程数: ${MAX_CHILDREN}"
echo "🔍 CPU 核心数: ${CPU_CORES}"
echo "🔍 启动服务器数: ${START_SERVERS}"
echo "🔍 最小空闲服务器数: ${MIN_SPARE_SERVERS}"
echo "🔍 最大空闲服务器数: ${MAX_SPARE_SERVERS}"
echo "🔍 最大请求数: ${MAX_REQUESTS}"
echo "🔍 终止超时时间: ${TERMINATE_TIMEOUT}"

if [[ ! -f "$CONF_PATH" ]]; then
    echo "❌ 配置文件不存在：$CONF_PATH"
    exit 1
fi

# 优化 php.ini 配置（动态）
PHP_INI_FILE="/etc/php/$version/fpm/php.ini"
PHP_INI_BACKUP="$PHP_INI_FILE.bak.$(date +%Y%m%d_%H%M%S)"
if [[ -f "$PHP_INI_FILE" ]]; then
    echo "📦 正在备份 php.ini 配置..."
    cp "$PHP_INI_FILE" "$PHP_INI_BACKUP"
    echo "📦 php.ini 备份完成：$PHP_INI_BACKUP"

    echo "⚙️ 正在动态优化 php.ini 配置..."

    # 动态设置 memory_limit（为可用内存的 1/4，最多 1024M）
    DYN_MEM_LIMIT=$((AVAIL_MEM / 4))
    [[ $DYN_MEM_LIMIT -gt 1024 ]] && DYN_MEM_LIMIT=1024
    [[ $DYN_MEM_LIMIT -lt 128 ]] && DYN_MEM_LIMIT=128

    # 动态设置 max_execution_time 和 max_input_time（根据 CPU 核心数量）
    DYN_MAX_TIME=$((CPU_CORES * 15))
    [[ $DYN_MAX_TIME -gt 120 ]] && DYN_MAX_TIME=120

    # 上传和 POST 大小（固定建议值）
    UPLOAD_MAX=50
    POST_MAX=100

    sed -i -e "s/^memory_limit = .*/memory_limit = ${DYN_MEM_LIMIT}M/" \
           -e "s/^upload_max_filesize = .*/upload_max_filesize = ${UPLOAD_MAX}M/" \
           -e "s/^post_max_size = .*/post_max_size = ${POST_MAX}M/" \
           -e "s/^max_execution_time = .*/max_execution_time = ${DYN_MAX_TIME}/" \
           -e "s/^max_input_time = .*/max_input_time = ${DYN_MAX_TIME}/" \
           -e "s/^;date.timezone =.*/date.timezone = Asia\/Shanghai/" \
           -e "s/^display_errors = .*/display_errors = Off/" \
           -e "s/^;cgi.fix_pathinfo=.*/cgi.fix_pathinfo=0/" \
           "$PHP_INI_FILE"

    echo "✅ php.ini 动态配置优化完成"
else
    echo "❌ 找不到 php.ini 文件：$PHP_INI_FILE"
fi

# 备份原配置
BACKUP_PATH="$CONF_PATH.bak.$(date +%Y%m%d_%H%M%S)"
cp "$CONF_PATH" "$BACKUP_PATH"
echo "📦 原配置文件已备份为：$BACKUP_PATH"
# 生成新配置
echo "⚙️ 生成新的 PHP-FPM 配置..."
cat > "$CONF_PATH" <<EOF
[www]
user = www-data
group = www-data

listen = $LISTEN_ADDRESS
listen.owner = www-data
listen.group = www-data

pm = dynamic
pm.max_children = ${MAX_CHILDREN}
pm.start_servers = ${START_SERVERS}
pm.min_spare_servers = ${MIN_SPARE_SERVERS}
pm.max_spare_servers = ${MAX_SPARE_SERVERS}

pm.max_requests = ${MAX_REQUESTS}
request_terminate_timeout = ${TERMINATE_TIMEOUT}
request_slowlog_timeout = 5s
slowlog = /var/log/php${version}-slow.log
EOF

echo "🔍 配置 PHP-FPM 监听地址为: $LISTEN_ADDRESS"

# 重启 PHP-FPM 服务
echo "🔄 正在重启 PHP-FPM 服务..."
systemctl restart "$PHP_FPM_SERVICE"
if [[ $? -eq 0 ]]; then
    echo "🚀 PHP-FPM 服务已重启，配置生效 ✅"
else
    echo "❌ 重启 PHP-FPM 失败，请检查服务状态"
    exit 1
fi