#!/bin/bash
set -e

echo "Iniciando QloApps..."

chown -R www-data:www-data /var/www/html
find /var/www/html -type d -exec chmod 755 {} \;
find /var/www/html -type f -exec chmod 644 {} \;

chmod -R 777 /var/www/html/cache
chmod -R 777 /var/www/html/log  
chmod -R 777 /var/www/html/img
chmod -R 777 /var/www/html/upload
chmod -R 777 /var/www/html/download

echo "Testing PHP..."
php -v
php -m | grep -i mysql

echo "Testing QloApps..."
cd /var/www/html
php -f index.php || echo "PHP error detected"

echo "Starting Apache..."
exec apache2-foreground
