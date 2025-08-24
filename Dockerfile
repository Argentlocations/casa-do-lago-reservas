!/bin/bash
FROM php:8.1-apache

RUN chmod +x /usr/local/bin/docker-entrypoint.sh && \
    sed -i 's/\r$//' /usr/local/bin/docker-entrypoint.sh

RUN chown -R www-data:www-data /var/www/html

EXPOSE 80
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["apache2-foreground"]

RUN printf '<Directory /var/www/html/>\n\
   Options Indexes FollowSymLinks\n\
   AllowOverride All\n\
   Require all granted\n\
</Directory>\n' > /etc/apache2/conf-available/qloapps.conf \
&& a2enconf qloapps

WORKDIR /var/www/html
COPY . /var/www/html/

COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
RUN chown -R www-data:www-data /var/www/html

EXPOSE 80

# Não use ENTRYPOINT nem CMD, use direto o apache
CMD ["apache2-foreground"]
CMD ["/bin/bash", "-c", "chmod +x /usr/local/bin/docker-entrypoint.sh && /usr/local/bin/docker-entrypoint.sh"]
