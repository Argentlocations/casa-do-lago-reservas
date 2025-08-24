#!/bin/bash
set -e

echo "Iniciando QloApps..."
chown -R www-data:www-data /var/www/html
exec apache2-foreground
