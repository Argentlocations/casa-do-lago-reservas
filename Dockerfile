FROM php:8.1-apache

# Configuração definitiva baseada no sistema funcional
# Data: 30/08/2024

RUN apt-get update && apt-get install -y \
    libicu-dev libzip-dev libpng-dev libjpeg62-turbo-dev \
    libonig-dev libxml2-dev unzip git curl \
    && docker-php-ext-configure gd --with-jpeg \
    && docker-php-ext-install intl zip gd mbstring pdo pdo_mysql xml soap \
    && a2enmod rewrite headers expires \
    && rm -rf /var/lib/apt/lists/*

COPY _infra/php.ini /usr/local/etc/php/conf.d/custom.ini
WORKDIR /var/www/html
COPY . /var/www/html/

# Remover pasta install por segurança

# Criar estrutura necessária
RUN mkdir -p /var/www/html/var/cache \
    && mkdir -p /var/www/html/var/sessions \
    && mkdir -p /var/www/html/var/logs

# Configurar permissões
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 775 /var/www/html/var \
    && chmod -R 775 /var/www/html/cache

COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

EXPOSE 80
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["apache2-foreground"]
