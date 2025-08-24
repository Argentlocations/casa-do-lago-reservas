#!/bin/bash
set -e

echo "Iniciando QloApps..."

if [ -n "$DB_HOST" ]; then
    echo "Testando conexão com MySQL..."
    until nc -z "$DB_HOST" "$DB_PORT" 2>/dev/null; do
        echo "Aguardando MySQL..."
        sleep 2
    done
    echo "MySQL conectado!"
fi

chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

if [ ! -f /var/www/html/.htaccess ]; then
    echo "RewriteEngine On" > /var/www/html/.htaccess
fi

ls -la /var/www/html/index.php || echo "ERRO: index.php não encontrado!"

echo "Iniciando Apache..."
exec apache2-foreground
