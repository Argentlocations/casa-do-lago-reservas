#!/usr/bin/env bash
set -euo pipefail

# Configurações
DOCROOT="${DOCROOT:-/var/www/html}"
DATADIR="${DATADIR:-/data}"
ADMIN_DIR="${ADMIN_DIR:-admin_casadolago}"

echo "========================================="
echo "🏨 QloApps - Casa do Lago - Inicializando"
echo "========================================="

# PARTE 1: Preparar diretórios persistentes
echo ""
echo "📁 Preparando diretórios persistentes..."
mkdir -p "$DATADIR"/{img,upload,download,modules,themes,var,config,cache}

# Função para criar symlinks seguros
create_symlink() {
    local source=$1
    local target=$2
    
    if [ ! -L "$target" ]; then
        if [ -d "$target" ] && [ ! -d "$source" ]; then
            echo "  → Salvando $target no volume..."
            mkdir -p "$source"
            cp -a "$target/." "$source/" 2>/dev/null || true
        fi
        rm -rf "$target"
        ln -s "$source" "$target"
        echo "  ✓ Link criado: $target → $source"
    fi
}

# Criar links para diretórios importantes
for dir in img upload download modules themes var cache; do
    create_symlink "$DATADIR/$dir" "$DOCROOT/$dir"
done

# Config pode estar em lugares diferentes
if [ -d "$DOCROOT/app" ]; then
    mkdir -p "$DATADIR/app_config"
    create_symlink "$DATADIR/app_config" "$DOCROOT/app/config"
else
    create_symlink "$DATADIR/config" "$DOCROOT/config"
fi

# PARTE 2: Verificar instalação
echo ""
echo "🔍 Verificando status da instalação..."
CONFIG_FILE=""
if [ -f "$DOCROOT/app/config/parameters.php" ]; then
    CONFIG_FILE="$DOCROOT/app/config/parameters.php"
    echo "  ✓ QloApps 1.7.x instalado"
elif [ -f "$DOCROOT/config/settings.inc.php" ]; then
    CONFIG_FILE="$DOCROOT/config/settings.inc.php"
    echo "  ✓ QloApps 1.6.x instalado"
else
    echo "  ⚠ QloApps não instalado"
fi

# PARTE 3: Instalar se necessário
if [ -z "$CONFIG_FILE" ] && [ -f "$DOCROOT/install/index_cli.php" ]; then
    echo ""
    echo "🚀 Instalação automática..."
    
    if [ -z "${DB_HOST:-}" ] || [ -z "${DB_NAME:-}" ] || [ -z "${DB_USER:-}" ]; then
        echo "  ❌ Configure DB_HOST, DB_NAME, DB_USER no Railway!"
    else
        # Pegar domínio do Railway
        if [ -z "${APP_DOMAIN:-}" ]; then
            if [ -n "${RAILWAY_STATIC_URL:-}" ]; then
                APP_DOMAIN="${RAILWAY_STATIC_URL#https://}"
                APP_DOMAIN="${APP_DOMAIN#http://}"
            else
                APP_DOMAIN="localhost"
            fi
        fi
        
        echo "  📝 Instalando para: $APP_DOMAIN"
        
        php "$DOCROOT/install/index_cli.php" \
            --domain="$APP_DOMAIN" \
            --db_server="${DB_HOST}" \
            --db_name="${DB_NAME}" \
            --db_user="${DB_USER}" \
            --db_password="${DB_PASS:-}" \
            --prefix="${DB_PREFIX:-qlo_}" \
            --email="${ADMIN_EMAIL:-admin@casadolago.com.br}" \
            --password="${ADMIN_PASSWORD:-CasaDoLago2025!}" \
            --firstname="${ADMIN_FIRSTNAME:-Admin}" \
            --lastname="${ADMIN_LASTNAME:-Casa do Lago}" \
            --name="${SITE_NAME:-Casa do Lago}" \
            --country="${COUNTRY:-br}" \
            --language="${LANGUAGE:-pt}" \
            --db_create=0 \
            --newsletter=0 \
            && echo "  ✓ Instalação concluída!" \
            || echo "  ⚠ Falha - acesse /install manualmente"
    fi
fi

# PARTE 4: Limpeza de segurança (SEMPRE!)
echo ""
echo "🧹 Limpeza de segurança..."
if [ -d "$DOCROOT/install" ]; then
    rm -rf "$DOCROOT/install"
    echo "  ✓ Pasta install removida"
fi

if [ -d "$DOCROOT/admin" ] && [ "$ADMIN_DIR" != "admin" ]; then
    if [ ! -d "$DOCROOT/$ADMIN_DIR" ]; then
        mv "$DOCROOT/admin" "$DOCROOT/$ADMIN_DIR"
        echo "  ✓ Admin renomeado para: $ADMIN_DIR"
    fi
fi

# PARTE 5: Permissões
echo ""
echo "🔐 Ajustando permissões..."
chown -R www-data:www-data "$DATADIR" 2>/dev/null || true
chown -R www-data:www-data "$DOCROOT" 2>/dev/null || true
echo "  ✓ Permissões OK"

# PARTE 6: Configurar porta do Railway
echo ""
echo "🌐 Configurando Apache..."
if [ -n "${PORT:-}" ]; then
    echo "  → Porta Railway: $PORT"
    sed -i "s/^Listen 80/Listen ${PORT}/" /etc/apache2/ports.conf 2>/dev/null || true
    sed -i "s#<VirtualHost \*:80>#<VirtualHost *:${PORT}>#" \
        /etc/apache2/sites-available/000-default.conf 2>/dev/null || true
    echo "  ✓ Apache configurado"
else
    echo "  ✓ Porta padrão 80"
fi

# PARTE 7: Informações finais
echo ""
echo "========================================="
echo "✅ QloApps pronto!"
echo "========================================="
echo "📌 Site: https://${APP_DOMAIN:-seu-app.railway.app}"
echo "📌 Admin: https://${APP_DOMAIN:-seu-app.railway.app}/${ADMIN_DIR}"
echo "👤 Email: ${ADMIN_EMAIL:-admin@casadolago.com.br}"
echo "========================================="

# Iniciar Apache
echo "→ Iniciando Apache..."
exec apache2-foreground
