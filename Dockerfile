FROM php:8.1-apache

# Instalar dependências do sistema
RUN apt-get update && apt-get install -y \
    libicu-dev \
    libzip-dev \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libonig-dev \
    libxml2-dev \
    unzip \
    git \
    && rm -rf /var/lib/apt/lists/*

# Configurar e instalar extensões PHP
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
        intl \
        zip \
        gd \
        mbstring \
        pdo \
        pdo_mysql \
        xml \
        opcache \
        bcmath

# Habilitar módulos Apache necessários
RUN a2enmod rewrite headers expires deflate

# Configurar ServerName para evitar avisos
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Copiar configuração PHP personalizada
COPY _infra/php.ini /usr/local/etc/php/conf.d/custom.ini

# Definir diretório de trabalho
WORKDIR /var/www/html

# Copiar arquivos do projeto
COPY . /var/www/html/

# Configurar permissões (SIMPLIFICADO)
RUN chown -R www-data:www-data /var/www/html

# Dar permissões de escrita nas pastas necessárias
RUN chmod -R 777 /var/www/html/var || true \
    && chmod -R 777 /var/www/html/img || true \
    && chmod -R 777 /var/www/html/upload || true \
    && chmod -R 777 /var/www/html/download || true \
    && chmod -R 777 /var/www/html/cache || true \
    && chmod -R 777 /var/www/html/config || true

# Criar diretórios necessários se não existirem
RUN mkdir -p /var/www/html/var/cache \
    && mkdir -p /var/www/html/var/logs \
    && chown -R www-data:www-data /var/www/html/var

# REMOVER PASTA INSTALL
RUN rm -rf /var/www/html/install

# Configuração Apache para produção
RUN echo '<Directory /var/www/html/>' > /etc/apache2/conf-available/qloapps.conf \
    && echo '    Options -Indexes +FollowSymLinks' >> /etc/apache2/conf-available/qloapps.conf \
    && echo '    AllowOverride All' >> /etc/apache2/conf-available/qloapps.conf \
    && echo '    Require all granted' >> /etc/apache2/conf-available/qloapps.conf \
    && echo '</Directory>' >> /etc/apache2/conf-available/qloapps.conf \
    && a2enconf qloapps

# Expor porta 80
EXPOSE 80

# Comando para iniciar Apache
CMD ["apache2-foreground"]
