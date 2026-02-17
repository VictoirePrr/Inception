#!/bin/bash

# Generate self-signed SSL certificate if it doesn't exist
if [ ! -f /etc/nginx/ssl/nginx.crt ] || [ ! -f /etc/nginx/ssl/nginx.key ]; then
  echo "Generating SSL certificate..."
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/nginx/ssl/nginx.key \
  -out /etc/nginx/ssl/nginx.crt \
  -subj "/C=FR/ST=IDF/L=Paris/O=42/CN=vicperri.42.fr"
  chmod 600 /etc/nginx/ssl/nginx.key
  chmod 644 /etc/nginx/ssl/nginx.crt
  echo "SSL certificate created!"
fi


# Wait for WordPress to be ready
echo "Waiting for WordPress to be ready..."
MAX_TRIES=30
TRIES=0

# Wait for wp-load.php to exist
until [ -f /var/www/html/wp-load.php ]; do
  TRIES=$((TRIES + 1))
  if [ $TRIES -ge $MAX_TRIES ]; then
    echo "WARNING: WordPress files not ready after $MAX_TRIES attempts, continuing anyway..."
    break
  fi
  echo "WordPress files unavailable (attempt $TRIES/$MAX_TRIES) - sleeping..."
  sleep 1
done

# Wait for PHP-FPM to be ready on port 9000
echo "Waiting for PHP-FPM to be ready..."
MAX_TRIES=180
TRIES=0
until nc -z wordpress 9000 2>/dev/null; do
  TRIES=$((TRIES + 1))
  if [ $TRIES -ge $MAX_TRIES ]; then
    echo "WARNING: PHP-FPM not ready after $MAX_TRIES attempts, continuing anyway..."
    break
  fi
  echo "PHP-FPM unavailable (attempt $TRIES/$MAX_TRIES) - sleeping..."
  sleep 1
done

echo "WordPress is ready!"


echo "Starting Nginx..."
# Start Nginx in foreground
exec nginx -g "daemon off;"