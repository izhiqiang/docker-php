#!/bin/bash

echo "Docker phpmyadmin project initialization"

if [ ! -f ${PMA_CONFIG_DIR}/config.secret.inc.php ]; then
    cat > ${PMA_CONFIG_DIR}/config.secret.inc.php <<EOT
<?php
\$cfg['blowfish_secret'] = '$(tr -dc 'a-zA-Z0-9~!@#$%^&*_()+}{?></";.,[]=-' < /dev/urandom | fold -w 32 | head -n 1)';
EOT
fi


echo "Modify /var/www/html owner and group to www-data:www-data"
chown -R www-data:www-data /var/www/html


echo "Start the daemon supervisor"
supervisord -u root -c /etc/supervisor/supervisord.conf

