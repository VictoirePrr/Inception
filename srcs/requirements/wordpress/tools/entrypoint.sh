#!/bin/sh

cd /var/www/html

    i=1
    while [ $i -le 30 ]; do
        if nc -z mariadb 3306; then
            sleep 2
            break
        fi
        sleep 2
        i=$((i + 1))
    done

    i=1
    while [ $i -le 30 ]; do
        if nc -z redis 6379; then
            break
        fi
        sleep 2
        i=$((i + 1))
    done

if [ ! -f wp-config.php ]; then

    wp core download --allow-root

    sleep 10



    wp config create --allow-root \
        --dbname=$DB_NAME \
        --dbuser=$DB_USER \
        --dbpass=$DB_PASSWORD \
        --dbhost=$DB_HOST

    wp core install --allow-root \
        --url=$DOMAIN_NAME \
        --title="$WP_TITLE" \
        --admin_user=$WP_ADMIN_USER \
        --admin_password=$WP_ADMIN_PASSWORD \
        --admin_email=$WP_ADMIN_EMAIL

    wp user create --allow-root \
        --role=author \
        $WP_USER \
        $WP_USER_EMAIL \
        --user_pass=$WP_USER_PASSWORD

    wp plugin install redis-cache --activate --allow-root
    wp config set WP_REDIS_HOST redis --allow-root
    wp config set WP_REDIS_PORT 6379 --raw --allow-root
    wp redis enable --allow-root
fi

chown -R www:www-data /var/www/html

exec /usr/sbin/php-fpm82 -F