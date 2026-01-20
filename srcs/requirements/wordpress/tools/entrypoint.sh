#!/bin/sh

cd /var/www/html

# Wait for MariaDB to be ready
i=1
while [ $i -le 30 ]; do
    if nc -z mariadb 3306; then
        sleep 2
        break
    fi
    sleep 2
    i=$((i + 1))
done

# Check if WordPress is already installed by looking for wp_users table
TABLE_EXISTS=$(mysql -h mariadb -u $MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE -e "SHOW TABLES LIKE 'wp_users';" 2>/dev/null | grep -c "wp_users")

if [ "$TABLE_EXISTS" -eq 0 ]; then
    # WordPress not installed yet
    
    # Clean up old files if they exist
    rm -rf wp-admin wp-content wp-includes *.php
    
    # Download WordPress
    wp core download --allow-root
    
    sleep 3
    
    # Create wp-config.php
    wp config create --allow-root \
        --dbname=$MYSQL_DATABASE \
        --dbuser=$MYSQL_USER \
        --dbpass=$MYSQL_PASSWORD \
        --dbhost=$DB_HOST \
        --skip-check
    
    sleep 3
    
    # Install WordPress in the database
    wp core install --allow-root \
        --url=$DOMAIN_NAME \
        --title="$WP_TITLE" \
        --admin_user=$WP_ADMIN_USER \
        --admin_password=$WP_ADMIN_PASSWORD \
        --admin_email=$WP_ADMIN_EMAIL
    
    # Create additional WordPress user
    wp user create --allow-root \
        --role=author \
        $WP_USER \
        $WP_USER_EMAIL \
        --user_pass=$WP_USER_PASSWORD
fi

# Fix permissions
chown -R www-data:www-data /var/www/html

# Start PHP-FPM in foreground
exec /usr/sbin/php-fpm8.2 -F