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

# Configurar permissões corretas
RUN chown -R www-data:www-data /var/www/html \
    && find /var/www/html -type d -exec chmod 755 {} \; \
    && find /var/www/html -type f -exec chmod 644 {} \; \
    && chmod -R 777 /var/www/html/var \
    && chmod -R 777 /var/www/html/img \
    && chmod -R 777 /var/www/html/upload \
    && chmod -R 777 /var/www/html/download \
    && chmod -R 777 /var/www/html/cache \
    && chmod -R 777 /var/www/html/config

# Criar diretórios necessários se não existirem
RUN mkdir -p /var/www/html/var/cache \
    && mkdir -p /var/www/html/var/logs \
    && chown -R www-data:www-data /var/www/html/var

# Configuração Apache para produção
RUN echo '<Directory /var/www/html/>' > /etc/apache2/conf-available/qloapps.conf \
    && echo '    Options -Indexes +FollowSymLinks' >> /etc/apache2/conf-available/qloapps.conf \
    && echo '    AllowOverride All' >> /etc/apache2/conf-available/qloapps.conf \
    && echo '    Require all granted' >> /etc/apache2/conf-available/qloapps.conf \
    && echo '</Directory>' >> /etc/apache2/conf-available/qloapps.conf \
    && a2enconf qloapps

# IMPORTANTE: Remover ou renomear pasta install
RUN if [ -d "/var/www/html/install" ]; then \
      mv /var/www/html/install /var/www/html/install_BACKUP_$(date +%Y%m%d) 2>/dev/null || \
      rm -rf /var/www/html/install 2>/dev/null || \
      echo "Install folder will be handled by .htaccess"; \
    fi

# Expor porta 80
EXPOSE 80

# Comando para iniciar Apache
CMD ["apache2-foreground"]
