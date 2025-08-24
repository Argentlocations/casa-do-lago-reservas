#!/bin/bash
set -e

echo "=== QloApps Casa do Lago - Iniciando ==="

# Definir diretório de trabalho
WEBROOT="/var/www/html"

# Aguardar banco de dados (se necessário)
if [ -n "$DB_HOST" ]; then
    echo "Aguardando conexão com banco..."
    while ! nc -z "$DB_HOST" 3306 2>/dev/null; do
        sleep 1
    done
    echo "✅ Banco conectado"
fi

# Verificar se sistema já foi instalado
if [ -f "$WEBROOT/config/settings.inc.php" ]; then
    echo "✅ Sistema instalado - aplicando configurações de produção"
    
    # Remover pasta install por segurança
    if [ -d "$WEBROOT/install" ]; then
        rm -rf "$WEBROOT/install"
        echo "✅ Pasta install removida"
    fi
    
    # Renomear pasta admin para segurança (se ainda não foi)
    if [ -d "$WEBROOT/admin" ]; then
        ADMIN_NEW="admin$(date +%s | tail -c 6)"
        mv "$WEBROOT/admin" "$WEBROOT/$ADMIN_NEW"
        echo "✅ Admin renomeado para: $ADMIN_NEW"
        echo "💡 Acesse: https://seu-dominio.railway.app/$ADMIN_NEW"
    fi
else
    echo "⚠️  Primeira execução - mantendo pasta install para configuração"
fi

# Configurar permissões
echo "Configurando permissões..."
chown -R www-data:www-data "$WEBROOT"
find "$WEBROOT" -type d -exec chmod 755 {} \;
find "$WEBROOT" -type f -exec chmod 644 {} \;

# Configurações específicas do QloApps
chmod -R 777 "$WEBROOT/cache" 2>/dev/null || true
chmod -R 777 "$WEBROOT/log" 2>/dev/null || true
chmod -R 777 "$WEBROOT/img" 2>/dev/null || true
chmod -R 777 "$WEBROOT/download" 2>/dev/null || true
chmod -R 777 "$WEBROOT/upload" 2>/dev/null || true

echo "✅ Permissões configuradas"

# Iniciar Apache
echo "🚀 Iniciando servidor Apache..."
exec apache2-foreground
