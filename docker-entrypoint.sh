#!/bin/bash
set -e

echo "Iniciando QloApps..."
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

if [ ! -f /var/www/html/.htaccess ]; then
    echo "RewriteEngine On" > /var/www/html/.htaccess
fi

echo "Iniciando Apache..."
exec apache2-foreground
