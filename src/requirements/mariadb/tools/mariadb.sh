#!/bin/bash

# Only initialize database if it’s not already initialized
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "[INFO] Initializing MariaDB database..."

    # Initialize MariaDB without a root password temporarily
    mysqld --initialize-insecure --user=mysql

    # Start MariaDB in the background
    mysqld_safe --skip-networking &
    sleep 5

    # Create database and user from environment variables
    mysql -u root <<EOF
        CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
        CREATE USER IF NOT EXISTS \`${MYSQL_USER}\`@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
        GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO \`${MYSQL_USER}\`@'%';
        ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
        FLUSH PRIVILEGES;
EOF

    # Shutdown the temporary MariaDB instance
    mysqladmin -u root -p"${MYSQL_ROOT_PASSWORD}" shutdown
fi

echo "[INFO] Starting MariaDB normally..."
exec mysqld_safe
