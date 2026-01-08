#!/bin/bash

# Initialize MariaDB if not already done
if [ ! -d "/var/lib/mysql/mysql" ]; then
  echo "Initializing MariaDB database..."
  mysql_install_db --user=mysql --datadir=/var/lib/mysql --skip-test-db
fi

# Start MariaDB daemon
echo "Starting MariaDB..."
mysqld --user=mysql --bind-address=0.0.0.0 &
MYSQLD_PID=$!

# Wait for socket
until [[ -S /var/run/mysqld/mysqld.sock ]]; do
  echo "Waiting for socket..."
  sleep 1
done

# Give MariaDB a moment to fully initialize
sleep 2

# Create WordPress database and users
echo "Creating WordPress database..."
mysql -u root << EOF
CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\`;
CREATE USER IF NOT EXISTS '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';
GRANT ALL PRIVILEGES ON \`$MYSQL_DATABASE\`.* TO '$MYSQL_USER'@'%';
FLUSH PRIVILEGES;
EOF

echo "MariaDB ready!"

# Wait for the background process to ensure container stays alive
wait $MYSQLD_PID
