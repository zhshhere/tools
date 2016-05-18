#!/usr/bin/env bash

# Update Package List
su root

apt-get update

apt-get upgrade -y

# Install Some PPAs

apt-get install -y software-properties-common

apt-add-repository ppa:nginx/stable -y
apt-add-repository ppa:ondrej/php5-5.6 -y

# Update Package Lists

apt-get update

# Install Some Basic Packages

apt-get install -y build-essential curl dos2unix gcc git libmcrypt4 libpcre3-dev \
make python2.7-dev python-pip re2c supervisor unattended-upgrades whois vim git-flow git-core language-pack-zh*

# Useradd www and Groupadd www

groupadd www
useradd www -g www -m

# Install PHP Stuffs

apt-get install -y php5-cli php5-dev php-pear \
php5-mysqlnd \
php5-apcu php5-json php5-curl php5-gd \
php5-gmp php5-imap php5-mcrypt php5-xdebug \
php5-memcached php5-redis php5-imagick

echo "extension=mcrypt.so" > /etc/php5/mods-available/mcrypt.ini
ln -s /etc/php5/mods-available/mcrypt.ini /etc/php5/cli/conf.d/20-mcrypt.ini

# Install Composer

curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

# Add Composer Global Bin To Path

printf "\nPATH=\"/root/.composer/vendor/bin:\$PATH\"\n" | tee -a /root/.profile

# Install Laravel Envoy

sudo su root <<'EOF'
/usr/local/bin/composer global require "laravel/envoy=~1.0"
EOF

# Set Some PHP CLI Settings

sudo sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php5/cli/php.ini
sudo sed -i "s/display_errors = .*/display_errors = On/" /etc/php5/cli/php.ini
sudo sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php5/cli/php.ini
sudo sed -i "s/post_max_size = .*/post_max_size = 10M/" /etc/php5/cli/php.ini
sudo sed -i "s/upload_max_filesize = .*/upload_max_filesize = 10M/" /etc/php5/cli/php.ini

# Install Nginx & PHP-FPM

apt-get install -y nginx php5-fpm

rm /etc/nginx/sites-enabled/default
rm /etc/nginx/sites-available/default
service nginx restart

# Setup Some PHP-FPM Options
ln -s /etc/php5/mods-available/mcrypt.ini /etc/php5/fpm/conf.d/20-mcrypt.ini

sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php5/fpm/php.ini
sed -i "s/display_errors = .*/display_errors = On/" /etc/php5/fpm/php.ini
sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php5/fpm/php.ini
sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php5/fpm/php.ini
sed -i "s/post_max_size = .*/post_max_size = 10M/" /etc/php5/fpm/php.ini
sed -i "s/upload_max_filesize = .*/upload_max_filesize = 10M/" /etc/php5/fpm/php.ini

# Copy fastcgi_params to Nginx because they broke it on the PPA

cat > /etc/nginx/fastcgi_params << EOF
fastcgi_param   QUERY_STRING        \$query_string;
fastcgi_param   REQUEST_METHOD      \$request_method;
fastcgi_param   CONTENT_TYPE        \$content_type;
fastcgi_param   CONTENT_LENGTH      \$content_length;
fastcgi_param   SCRIPT_FILENAME     \$request_filename;
fastcgi_param   SCRIPT_NAME     \$fastcgi_script_name;
fastcgi_param   REQUEST_URI     \$request_uri;
fastcgi_param   DOCUMENT_URI        \$document_uri;
fastcgi_param   DOCUMENT_ROOT       \$document_root;
fastcgi_param   SERVER_PROTOCOL     \$server_protocol;
fastcgi_param   GATEWAY_INTERFACE   CGI/1.1;
fastcgi_param   SERVER_SOFTWARE     nginx/\$nginx_version;
fastcgi_param   REMOTE_ADDR     \$remote_addr;
fastcgi_param   REMOTE_PORT     \$remote_port;
fastcgi_param   SERVER_ADDR     \$server_addr;
fastcgi_param   SERVER_PORT     \$server_port;
fastcgi_param   SERVER_NAME     \$server_name;
fastcgi_param   HTTPS           \$https if_not_empty;
fastcgi_param   REDIRECT_STATUS     200;
EOF

# Set The Nginx & PHP-FPM User

sed -i "s/user www-data;/user www;/" /etc/nginx/nginx.conf
sed -i "s/# server_names_hash_bucket_size.*/server_names_hash_bucket_size 64;/" /etc/nginx/nginx.conf

sed -i "s/user = www-data/user = www/" /etc/php5/fpm/pool.d/www.conf
sed -i "s/group = www-data/group = www/" /etc/php5/fpm/pool.d/www.conf

sed -i "s/;listen\.owner.*/listen.owner = www/" /etc/php5/fpm/pool.d/www.conf
sed -i "s/;listen\.group.*/listen.group = www/" /etc/php5/fpm/pool.d/www.conf
sed -i "s/;listen\.mode.*/listen.mode = 0666/" /etc/php5/fpm/pool.d/www.conf

service nginx restart
service php5-fpm restart
