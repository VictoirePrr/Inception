FROM debian:bookworm-slim

# Install PHP-FPM and dependencies
RUN apt-get update && apt-get install -y \
    php-fpm \
    php-mysql \
    php-curl \
    php-gd \
    php-mbstring \
    php-xml \
    mariadb-client \
    wget \
    curl \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

# Install WP-CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp

# Create PHP-FPM run directory
RUN mkdir -p /var/run/php-fpm \
    && chown -R www-data:www-data /var/run/php-fpm

# Configure PHP-FPM to listen on TCP port 9000
RUN sed -i 's|^listen = .*|listen = 0.0.0.0:9000|' /etc/php/8.2/fpm/pool.d/www.conf

# Create WordPress directory
RUN mkdir -p /var/www/html \
    && chown -R www-data:www-data /var/www/html

# Copy entrypoint script
COPY tools/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose PHP-FPM port (for Nginx communication)
EXPOSE 9000

# Run entrypoint as root for proper initialization
ENTRYPOINT ["/entrypoint.sh"]
