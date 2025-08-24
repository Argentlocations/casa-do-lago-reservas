FROM php:8.1-apache

# Forçando redeploy com PHP 8.1 - 24/08/2025

RUN apt-get update && apt-get install -y \
    libicu-dev \
    libzip-dev \
    libpng-dev \
    libjpeg62-turbo-dev \
    libonig-dev \
    libxml2-dev \
    unzip \
    git \
    curl \
    && docker-php-ext-configure gd --with-jpeg \
    && docker-php-ext-install intl zip gd mbstring pdo pdo_mysql xml soap \
    && a2enmod rewrite headers expires \
    && rm -rf /var/lib/apt/lists/*

COPY _infra/php.ini /usr/local/etc/php/conf.d/custom.ini

WORKDIR /var/www/html

COPY . /var/www/html

RUN chown -R www-data:www-data /var/www/html \
    && find /var/www/html -type d -exec chmod 755 {} \; \
    && find /var/www/html -type f -exec chmod 644 {} \;

RUN chmod -R 777 /var/www/html/cache \
    /var/www/html/img \
    /var/www/html/upload \
    /var/www/html/download \
    /var/www/html/translations \
    /var/www/html/mails \
    /var/www/html/modules \
    /var/www/html/themes

EXPOSE 80
