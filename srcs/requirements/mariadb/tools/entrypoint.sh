#!/bin/sh

# Validate required environment variables
if [ -z "$MYSQL_USER" ] || [ -z "$MYSQL_PASSWORD" ] || [ -z "$MYSQL_DATABASE" ] || [ -z "$MYSQL_ROOT_PASSWORD" ]; then
    echo "Error: Missing required environment variables"
    echo "Required: MYSQL_USER, MYSQL_PASSWORD, MYSQL_DATABASE, MYSQL_ROOT_PASSWORD"
    exit 1
fi

# Prepare directories and permissions
mkdir -p /run/mysqld
chown mysql:mysql /run/mysqld
chown mysql:mysql /var/lib/mysql

# Initialize MariaDB if not already done
if [ ! -d "/var/lib/mysql/mysql" ]; then
  echo "Initializing MariaDB database..."
  mysql_install_db --user=mysql --datadir=/var/lib/mysql --basedir=/usr
fi

# Start MariaDB daemon (background process)
echo "Starting MariaDB daemon..."
mariadbd-safe --user=mysql --datadir=/var/lib/mysql &
MARIADB_PID=$!

# Wait for MariaDB to be ready
echo "Waiting for MariaDB to be ready..."
i=1
while [ $i -le 30 ]; do
    if mariadb -u root -e "SELECT 1;" > /dev/null 2>&1; then
        break
    fi
    sleep 1
    i=$((i + 1))
done

# Create WordPress database and users
echo "Setting up databases and users..."
mariadb -u root << EOF
CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
ALTER USER 'root'@'localhost' IDENTIFIED VIA mysql_native_password USING PASSWORD('$MYSQL_ROOT_PASSWORD');
CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\`;
CREATE USER IF NOT EXISTS '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';
GRANT ALL PRIVILEGES ON \`$MYSQL_DATABASE\`.* TO '$MYSQL_USER'@'%';
DELETE FROM mysql.user WHERE User='';
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db LIKE 'test_%';
FLUSH PRIVILEGES;
EOF

# Gracefully shutdown the background process
echo "Shutting down initial daemon..."
mariadb-admin -u root -p"$MYSQL_ROOT_PASSWORD" shutdown
wait $MARIADB_PID

# Start MariaDB as the main process (PID 1 replacement)
echo "Starting MariaDB server..."
exec mariadbd --user=mysql --datadir=/var/lib/mysql --bind-address=0.0.0.0 --port=3306
