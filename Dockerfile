#!/bin/bash
echo "Files in /var/www/html:"
ls -la /var/www/html/
echo "Apache config:"
cat /etc/apache2/sites-available/000-default.conf
echo "Testing direct access:"
cat /var/www/html/index.php | head -5
exec apache2-foreground
