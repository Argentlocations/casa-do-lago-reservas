#!/bin/bash
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] QloApps: $1"
}
log "Iniciando configuracao do QloApps..."

# VERIFICAR SE QLOAPPS JÁ ESTÁ INSTALADO
if [ -f "/var/www/html/config/settings.inc.php" ]; then
    # QloApps está instalado - podemos remover install com segurança
    if [ -d "/var/www/html/install" ]; then
        log "QloApps já instalado. Removendo pasta install por seguranca..."
        rm -rf /var/www/html/install
        log "Pasta install removida com sucesso"
    fi
else
    # QloApps NÃO está instalado - precisamos manter a pasta install
    log "Primeira instalacao detectada - mantendo pasta install..."
    if [ ! -d "/var/www/html/install" ]; then
        log "AVISO: Pasta install necessaria mas nao encontrada!"
    fi
fi

# Renomear pasta admin para admin_140350
ADMIN_CONFIGURED=false
for dir in /var/www/html/admin* /var/www/html/admim*; do
    if [ -d "$dir" ]; then
        BASENAME=$(basename "$dir")
        if [ "$BASENAME" != "admin_140350" ]; then
            if [ ! -d "/var/www/html/admin_140350" ]; then
                log "Renomeando $BASENAME para admin_140350..."
                mv "$dir" "/var/www/html/admin_140350"
                ADMIN_CONFIGURED=true
                break
            else
                log "Removendo $BASENAME duplicado..."
                rm -rf "$dir"
            fi
        else
            ADMIN_CONFIGURED=true
        fi
    fi
done

# Criar diretorios necessarios
if [ ! -d "/var/www/html/var/sessions" ]; then
    log "Criando diretorio de sessoes..."
    mkdir -p /var/www/html/var/sessions
    chown www-data:www-data /var/www/html/var/sessions
    chmod 775 /var/www/html/var/sessions
fi

# Configurar PHP
if [ ! -f "/usr/local/etc/php/conf.d/sessions.ini" ]; then
    log "Configurando sessoes PHP..."
    echo 'session.save_path = "/var/www/html/var/sessions"' > /usr/local/etc/php/conf.d/sessions.ini
fi

log "Iniciando Apache..."
exec apache2-foreground
