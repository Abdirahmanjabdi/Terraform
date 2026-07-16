#!/bin/bash

# 1. Prevent interactive prompts from halting the script
export DEBIAN_FRONTEND=noninteractive

# 2. Wait for the background apt processes to finish
while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do 
    echo "Waiting for apt lock..."
    sleep 5
done

# Update and install the LAMP stack
sudo apt update
sudo apt install -y apache2 mysql-server php php-mysql libapache2-mod-php php-cli curl tar

# Start and enable services
sudo systemctl start apache2
sudo systemctl enable apache2
sudo systemctl start mysql
sudo systemctl enable mysql

# Generate the DB password on the instance so no secret ever lives in this repo
DB_PASS=$(openssl rand -hex 16)

# Set up the WordPress Database
sudo mysql -u root -e "CREATE DATABASE wordpress;"
sudo mysql -u root -e "CREATE USER 'wp_user'@'localhost' IDENTIFIED BY '${DB_PASS}';"
sudo mysql -u root -e "GRANT ALL PRIVILEGES ON wordpress.* TO 'wp_user'@'localhost';"
sudo mysql -u root -e "FLUSH PRIVILEGES;"

# Download and extract WordPress
cd /tmp
curl -O https://wordpress.org/latest.tar.gz
tar xzvf latest.tar.gz

# Ensure the web directory exists before copying
sudo mkdir -p /var/www/html
sudo cp -a /tmp/wordpress/. /var/www/html
sudo chown -R www-data:www-data /var/www/html

# Clean up default Apache page
sudo rm -f /var/www/html/index.html

# Configure wp-config.php
sudo cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
sudo sed -i "s/database_name_here/wordpress/" /var/www/html/wp-config.php
sudo sed -i "s/username_here/wp_user/" /var/www/html/wp-config.php
sudo sed -i "s/password_here/${DB_PASS}/" /var/www/html/wp-config.php

# Restart Apache to apply PHP configurations
sudo systemctl restart apache2