#!/bin/bash

set -e

WORDPRESS_PATH="/var/www/html"
WP_CONFIG="${WORDPRESS_PATH}/wp-config.php"

echo "[INFO] Starting WordPress setup..."

# Wait for MariaDB to be ready
echo "[INFO] Waiting for MariaDB to be ready..."
until mysql -h"${MYSQL_HOST}" -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -e "SELECT 1;" "${MYSQL_DATABASE}" >/dev/null 2>&1; do
    echo "[INFO] MariaDB not ready yet, waiting..."
    sleep 3
done
echo "[INFO] MariaDB is ready!"

# Create WordPress directory if it doesn't exist
mkdir -p "${WORDPRESS_PATH}"

# Download WordPress if not present
if [ ! -f "${WORDPRESS_PATH}/wp-load.php" ]; then
    echo "[INFO] Downloading WordPress..."
    wget -q -O /tmp/latest.tar.gz https://wordpress.org/latest.tar.gz
    tar -xzf /tmp/latest.tar.gz -C /tmp
    cp -r /tmp/wordpress/* "${WORDPRESS_PATH}/"
    rm -rf /tmp/latest.tar.gz /tmp/wordpress
fi

# Remove any corrupted wp-config.php and recreate it
rm -f "${WP_CONFIG}"

echo "[INFO] Creating wp-config.php..."
cat > "${WP_CONFIG}" << EOF
<?php
define( 'DB_NAME', '${MYSQL_DATABASE}' );
define( 'DB_USER', '${MYSQL_USER}' );
define( 'DB_PASSWORD', '${MYSQL_PASSWORD}' );
define( 'DB_HOST', '${MYSQL_HOST}' );
define( 'DB_CHARSET', 'utf8' );
define( 'DB_COLLATE', '' );

define( 'AUTH_KEY',         'unique-auth-key-here' );
define( 'SECURE_AUTH_KEY',  'unique-secure-auth-key-here' );
define( 'LOGGED_IN_KEY',    'unique-logged-in-key-here' );
define( 'NONCE_KEY',        'unique-nonce-key-here' );
define( 'AUTH_SALT',        'unique-auth-salt-here' );
define( 'SECURE_AUTH_SALT', 'unique-secure-auth-salt-here' );
define( 'LOGGED_IN_SALT',   'unique-logged-in-salt-here' );
define( 'NONCE_SALT',       'unique-nonce-salt-here' );

\$table_prefix = 'wp_';

define( 'WP_DEBUG', false );

if ( ! defined( 'ABSPATH' ) ) {
    define( 'ABSPATH', __DIR__ . '/' );
}

require_once ABSPATH . 'wp-settings.php';
EOF

# Download and install WP-CLI if not present
if [ ! -f "/usr/local/bin/wp" ]; then
    echo "[INFO] Installing WP-CLI..."
    wget -q -O /tmp/wp-cli.phar https://github.com/wp-cli/wp-cli/releases/download/v2.8.1/wp-cli-2.8.1.phar
    chmod +x /tmp/wp-cli.phar
    mv /tmp/wp-cli.phar /usr/local/bin/wp
fi

# Install WordPress and create users if not installed
if ! wp core is-installed --path="${WORDPRESS_PATH}" --allow-root 2>/dev/null; then
    echo "[INFO] Installing WordPress..."
    wp core install \
        --url="https://${DOMAIN_NAME}" \
        --title="Inception WordPress Site" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --path="${WORDPRESS_PATH}" \
        --allow-root

    echo "[INFO] Creating second user (editor)..."
    wp user create "${WP_EDITOR_USER}" "${WP_EDITOR_EMAIL}" \
        --role=editor \
        --user_pass="${WP_EDITOR_PASSWORD}" \
        --path="${WORDPRESS_PATH}" \
        --allow-root
    
    echo "[INFO] WordPress installation completed!"
else
    echo "[INFO] WordPress already installed"
fi

# Set proper permissions
chown -R www-data:www-data "${WORDPRESS_PATH}"
chmod -R 755 "${WORDPRESS_PATH}"

# Create php-fpm run directory
mkdir -p /run/php
chown www-data:www-data /run/php

echo "[INFO] Starting php-fpm..."
exec php-fpm7.4 -F