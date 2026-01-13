#!/bin/bash

# Wait for MariaDB to be ready
echo "Waiting for MariaDB to be ready..."
MAX_TRIES=30
TRIES=0

until mysql -h mariadb -P 3306 -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" -e "SELECT 1;" > /dev/null 2>&1; do
  TRIES=$((TRIES + 1))
  if [ $TRIES -ge $MAX_TRIES ]; then
    echo "ERROR: Could not connect to MariaDB after $MAX_TRIES attempts"
    exit 1
  fi
  echo "MariaDB is unavailable (attempt $TRIES/$MAX_TRIES) - sleeping..."
  sleep 2
done
echo "MariaDB is up!"

# Download WordPress if not already present
if [ ! -f "/var/www/html/wp-load.php" ]; then
  echo "Downloading WordPress..."
  cd /tmp
  wget -q https://wordpress.org/latest.tar.gz
  tar -xzf latest.tar.gz
  cp -r wordpress/* /var/www/html/
  rm -rf wordpress latest.tar.gz
  echo "WordPress downloaded!"
fi

# Create wp-config.php if it doesn't exist
if [ ! -f "/var/www/html/wp-config.php" ]; then
  echo "Creating wp-config.php..."
  
  cat > /var/www/html/wp-config.php << 'EOF'
<?php

// ** MySQL settings ** //
define('DB_NAME', getenv('MYSQL_DATABASE'));
define('DB_USER', getenv('MYSQL_USER'));
define('DB_PASSWORD', getenv('MYSQL_PASSWORD'));
define('DB_HOST', 'mariadb:3306');
define('DB_CHARSET', 'utf8mb4');
define('DB_COLLATE', '');


// Force HTTPS
define('FORCE_SSL_ADMIN', true);
if (strpos($_SERVER['HTTP_X_FORWARDED_PROTO'], 'https') !== false)
  $_SERVER['HTTPS'] = 'on';

/* That's all, stop editing! */
if ( ! defined( 'ABSPATH' ) )
  define( 'ABSPATH', __DIR__ . '/' );

require_once( ABSPATH . 'wp-settings.php' );

?>
EOF
  
  echo "wp-config.php created!"
fi

# Set proper permissions
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html
chmod 644 /var/www/html/wp-config.php

echo "Starting PHP-FPM..."
# Start PHP-FPM in foreground
exec /usr/sbin/php-fpm8.2 -F
