#!/usr/bin/env bash
set -euo pipefail

DOCROOT="/var/www/html"
DATADIR="/data"
ADMIN_DIR="${ADMIN_DIR:-admin_lago2024}"

echo "Iniciando QloApps"

mkdir -p "$DATADIR"/{img,upload,download,modules,themes,var,cache}

create_symlink() {
    local source=$1
    local target=$2
    
    if [ ! -L "$target" ]; then
        if [ -d "$target" ] && [ ! -d "$source" ]; then
            mkdir -p "$source"
            cp -a "$target/." "$source/" 2>/dev/null || true
        fi
        rm -rf "$target"
        ln -s "$source" "$target"
    fi
}

for dir in img upload download modules themes var cache; do
    create_symlink "$DATADIR/$dir" "$DOCROOT/$dir"
done

CONFIG_FILE=""
if [ -f "$DOCROOT/app/config/parameters.php" ]; then
    CONFIG_FILE="$DOCROOT/app/config/parameters.php"
elif [ -f "$DOCROOT/config/settings.inc.php" ]; then
    CONFIG_FILE="$DOCROOT/config/settings.inc.php"
fi

if [ -z "$CONFIG_FILE" ] && [ -f "$DOCROOT/install/index_cli.php" ]; then
    if [ -n "${DB_HOST:-}" ] && [ -n "${DB_NAME:-}" ] && [ -n "${DB_USER:-}" ]; then
        
        if [ -z "${APP_DOMAIN:-}" ]; then
            if [ -n "${RAILWAY_STATIC_URL:-}" ]; then
                APP_DOMAIN="${RAILWAY_STATIC_URL#https://}"
                APP_DOMAIN="${APP_DOMAIN#http://}"
            else
                APP_DOMAIN="localhost"
            fi
        fi
        
        php "$DOCROOT/install/index_cli.php" \
            --domain="$APP_DOMAIN" \
            --db_server="${DB_HOST}" \
            --db_name="${DB_NAME}" \
            --db_user="${DB_USER}" \
            --db_password="${DB_PASS:-}" \
            --prefix="${DB_PREFIX:-qlo_}" \
            --email="${ADMIN_EMAIL:-admin@casadolago.com.br}" \
            --password="${ADMIN_PASSWORD:-Admin123!}" \
            --firstname="${ADMIN_FIRSTNAME:-Admin}" \
            --lastname="${ADMIN_LASTNAME:-Sistema}" \
            --name="${SITE_NAME:-Casa do Lago}" \
            --country="${COUNTRY:-br}" \
            --language="${LANGUAGE:-pt}" \
            --db_create=0 \
            --newsletter=0 || true
    fi
fi

if [ -f "$DOCROOT/app/config/parameters.php" ] || [ -f "$DOCROOT/config/settings.inc.php" ]; then
    if [ -d "$DOCROOT/install" ]; then
        rm -rf "$DOCROOT/install"
    fi
fi

if [ -d "$DOCROOT/admin" ] && [ "$ADMIN_DIR" != "admin" ]; then
    if [ ! -d "$DOCROOT/$ADMIN_DIR" ]; then
        mv "$DOCROOT/admin" "$DOCROOT/$ADMIN_DIR"
    fi
fi

chown -R www-data:www-data "$DATADIR" 2>/dev/null || true
chown -R www-data:www-data "$DOCROOT" 2>/dev/null || true

if [ -n "${PORT:-}" ]; then
    sed -i "s/^Listen 80/Listen ${PORT}/" /etc/apache2/ports.conf 2>/dev/null || true
    sed -i "s#<VirtualHost \*:80>#<VirtualHost *:${PORT}>#" \
        /etc/apache2/sites-available/000-default.conf 2>/dev/null || true
fi

exec apache2-foreground
