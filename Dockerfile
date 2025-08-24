FROM php:8.1-apache

# Instalar todas as dependências necessárias para QloApps
RUN apt-get update && apt-get install -y \
    libzip-dev \
    libicu-dev \
    libxml2-dev \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libcurl4-openssl-dev \
    libonig-dev \
    unzip \
    git \
 && docker-php-ext-configure gd --with-jpeg --with-freetype \
 && docker-php-ext-install \
    pdo_mysql \
    gd \
    soap \
    intl \
    zip \
    opcache \
    curl \
    mbstring \
 && a2enmod rewrite headers expires \
 && rm -rf /var/lib/apt/lists/*

# Configurações PHP otimizadas para QloApps
RUN { \
    echo 'memory_limit = 512M'; \
    echo 'upload_max_filesize = 32M'; \
    echo 'post_max_size = 32M'; \
    echo 'max_execution_time = 500'; \
    echo 'max_input_time = 500'; \
    echo 'allow_url_fopen = On'; \
    echo 'date.timezone = America/Sao_Paulo'; \
    echo 'opcache.enable = 1'; \
    echo 'opcache.memory_consumption = 128'; \
} > /usr/local/etc/php/conf.d/qloapps.ini

# Permitir .htaccess funcionar
RUN printf '<Directory /var/www/html/>\n\
    Options Indexes FollowSymLinks\n\
    AllowOverride All\n\
    Require all granted\n\
</Directory>\n' > /etc/apache2/conf-available/qloapps.conf \
 && a2enconf qloapps

# Copiar código
WORKDIR /var/www/html
COPY . /var/www/html/

# Copiar e preparar o entrypoint
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Ajustar permissões
RUN chown -R www-data:www-data /var/www/html

EXPOSE 80
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]
