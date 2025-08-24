#!/bin/bash
set -e

echo "Iniciando QloApps..."
chown -R www-data:www-data /var/www/html
find /var/www/html -type d -exec chmod 755 {} \;
find /var/www/html -type f -exec chmod 644 {} \;

echo "Creating test file..."
echo "<?php echo 'PHP Test OK'; ?>" > /var/www/html/test.php

echo "Starting Apache..."
exec apache2-foreground
