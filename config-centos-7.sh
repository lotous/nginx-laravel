##########################################################
##             	   Install Firewalld                    ##
##########################################################

# Update Centos Repository
yum  update

# Install Firewalld
yum install firewalld -y

# Enable service firewalld 
systemctl enable firewalld


# Start service firewalld
systemctl start firewalld


# Firewalld verify status service
systemctl status firewalld


# fix firewalld AllowZoneDrifting
sed -ie 's/AllowZoneDrifting=yes/AllowZoneDrifting=no/g' /etc/firewalld/firewalld.conf 


# restart firewalld
systemctl restart firewalld


##########################################################
##               Installs nginx, php-fpm                ##
##########################################################

# Install nginx service 
yum install nginx


# Enable nginx service
systemctl enable nginx


# Start nginx service 
systemctl start nginx


# Install repo remi-release-7.rpm and utils packages
sudo yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
sudo yum -y install https://rpms.remirepo.net/enterprise/remi-release-7.rpm
sudo yum -y install yum-utils


# Reset php module in repo
sudo yum-config-manager --disable 'remi-php*'


# Enable php version 8.1 in repo 
sudo yum-config-manager --enable remi-php81
sudo yum repolist


# Update Centos Repository
yum update


# Install php and php-fpm service
yum -y install php php-fpm php-mysqlnd php-common php-curl php-dom php-json php-devel php-mbstring php-memcached php-redis php-pdo php-bcmath php-xml php-gd php-gmp php-igbinary php-imagick php-pdo_mysql php-posix php-simplexml php-opcache php-xsl php-xmlwriter php-xmlreader php-swoole php-zip php-yaml php-uuid


# Enable php-fpm service 
systemctl enable php-fpm


# Start php-fpm service  
systemctl start php-fpm


##########################################################
##           Config nignix, php-fpm & laravel           ##
##########################################################

# Change time zone
sed -ie 's/;date.timezone\ =/date.timezone\ =\ America\/Bogota/g' /etc/php.ini 


# change security option php
sed -ie 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php.ini 
sed -ie 's/;security.limit_extensions\ =\ .php\ .php3\ .php4\ .php5\ .php7/security.limit_extensions\ =\ .php\ .php3\ .php4\ .php5\ .php7/g' /etc/php-fpm.d/www.conf


# Change user & group listen script files 
sed -ie 's/user\ =\ apache/user\ =\ nginx/g' /etc/php-fpm.d/www.conf
sed -ie 's/group\ =\ apache/group\ =\ nginx/g' /etc/php-fpm.d/www.conf
sed -ie 's/;listen.owner\ =\ nobody/listen.owner\ =\ nginx/g' /etc/php-fpm.d/www.conf
sed -ie 's/;listen.group\ =\ nobody/listen.group\ =\ nginx/g' /etc/php-fpm.d/www.conf
sed -ie 's/;listen.mode\ =\ 0660/listen.mode\ =\ 0660/g' /etc/php-fpm.d/www.conf


# Install composer  
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer
chmod +x /usr/local/bin/composer

# Create domain directory 
mkdir -p /var/www/html/nginx-laravel.com

# Copy files laravel proyect in /var/www/html/nginx-laravel.com
# Replace git repository to you git laravel proyect 
git clone https://github.com/lotous/nginx-laravel.git


# Install packages required for you proyect
composer install


# Change permision & group for laravel/storage and laravel/bootstrap/cache
chgrp -R nginx /var/www/html/nginx-laravel.com/storage/ /var/www/html/nginx-laravel.com/bootstrap/cache
chmod -R ug+rwx /var/www/html/nginx-laravel.com/storage /var/www/html/nginx-laravel.com/bootstrap/cache

semanage fcontext -a -t httpd_sys_rw_content_t '/var/www/html/nginx-laravel.com/storage(/.*)?'
semanage fcontext -a -t httpd_sys_rw_content_t '/var/www/html/nginx-laravel.com/bootstrap/cache(/.*)?'
restorecon -Rv '/var/www/html/nginx-laravel.com'


# Comment demo server in /etc/nginx/nginx.conf
sed -i '37,58 s/^/#/' /etc/nginx/nginx.conf


# Create config file server for nginx 
echo "server {
   listen      80;
   server_name nginx-laravel.com www.nginx-laravel.com;
   root        /var/www/html/nginx-laravel.com/public;
   index       index.php;
   charset utf-8;
   gzip on;
   gzip_types text/css application/javascript text/javascript application/x-javascript  image/svg+xml text/plain text/xsd text/xsl text/xml image/x-icon;
   location / {
         try_files \$uri \$uri/ /index.php?\$query_string;
   }
   location ~ \.php {
         include /etc/nginx/fastcgi.conf;
         fastcgi_split_path_info ^(.+\.php)(/.+)\$;
         fastcgi_pass php-fpm;
   }
       
   location ~ /\.ht {
         deny all;
   }
}" > /etc/nginx/conf.d/nginx-laravel.com.conf



##########################################################
##                 Install SSL srever                   ##
##########################################################

# Intalar epel repository
dnf install epel-release


# Intalar certbot 
yum install certbot python3-certbot-nginx


#Generate certification ssl for web site
certbot --nginx -d nginx-laravel.com -d www.nginx-laravel.com


##########################################################
##              Open port http & https                  ##
##########################################################

# Abilitar el servicio http y https para nginx 
firewall-cmd --zone=public --permanent --add-service=http
firewall-cmd --zone=public --permanent --add-service=https


# Verificamos que el servicio http este activo 
firewall-cmd --permanent --list-all


# reinicimos el firewalld para que los cambio sufran efecto
systemctl restart firewalld


##########################################################
##       Install NPM for Larvel Mix Dependencies        ##
##########################################################

# Install npm
dnf npm install 

# Clear Cache npm 
npm cache clean -f

# Update npm version
npm install -g n

# Use stable version
n stable
