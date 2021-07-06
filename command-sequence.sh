##########################################################
##             		Intall Firewalld                    ##
##########################################################

# Actualizar Centos
sudo dnf update


# Intalar Firewalld
dnf install firewalld -y


# Abilitamos firewalld para que inicie con el servidor
systemctl enable firewalld


# Iniciar el servicio de firewalld
systemctl start firewalld


# Verificar el estado del servicio de firewalld
systemctl status firewalld


# fix firewalld 
 nano /etc/firewalld/firewalld.conf 
 Change => AllowZoneDrifting=yes to AllowZoneDrifting=no


# reiniciar firewalld
systemctl restart firewalld


##########################################################
##             Instalation nginx, php-fpm               ##
##########################################################

# Intalar nginx 
dnf install nginx


# Abilitamos el servicio de nginx para que arranque junto con el servidor
systemctl enable nginx


# Iniciar servicio nginx 
systemctl start nginx


# Instalamos el repositorio que tiene las ultimas versiones de php para centos 8 
dnf install dnf-utils http://rpms.remirepo.net/enterprise/remi-release-8.rpm


# Reseteamos cualquier version de php que este en los repositorios
dnf module reset php


# Permitimos que el repositorio carge la version de php que necesitamos
dnf module enable php:remi-7.4


# Actualizamos los repositorios
dnf update


# Intalamos el servicio de php y los modulos que necesitaremos
dnf install php php-fpm php-mysqlnd php-common php-curl php-dom php-json php-devel php-mbstring php-memcached php-redis php-pdo php-bcmath php-xml php-gd php-gmp php-igbinary php-imagick php-pdo_mysql php-posix php-simplexml php-opcache php-xsl php-xmlwriter php-xmlreader php-swoole php-zip php-yaml php-uuid


# abilitamos el servicio de php-fpm para que arranque junto con el servidor
systemctl enable php-fpm


# Iniciamos el servicio de php-fpm  
systemctl start php-fpm


##########################################################
##       Coniguration nignix, php-fpm & laravel         ##
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


# Intalamos composer para getionar los repositorios para laravel  
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer
chmod +x /usr/local/bin/composer


# Create laravel directorio an configure permision  
mkdir /var/www/html/nginx-laravel.com


# Copy files laravel proyect in /var/www/html/nginx-laravel.com
git clone https://github.com/lotous/nginx-laravel.git


# Install dependencias
composer install


# Change permision & group for laravel/storage and laravel/bootstrap/cache
chgrp -R nginx /var/www/html/nginx-laravel.com/storage/ /var/www/html/nginx-laravel.com/bootstrap/cache
chmod -R ug+rwx /var/www/html/nginx-laravel.com/storage /var/www/html/nginx-laravel.com/bootstrap/cache

semanage fcontext -a -t httpd_sys_rw_content_t '/var/www/html/nginx-laravel.com/storage(/.*)?'
semanage fcontext -a -t httpd_sys_rw_content_t '/var/www/html/nginx-laravel.com/bootstrap/cache(/.*)?'
restorecon -Rv '/var/www/html/nginx-laravel.com'


# Comment demo server in /etc/nginx/nginx.conf
sed -i '37,58 s/^/#/' /etc/nginx/nginx.conf


# Create configuration virtual server for nginx 
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
##               Intalacion SSL srever                  ##
##########################################################

# Intalar epel repository
dnf install epel-release


# Intalar certbot 
dnf install certbot python3-certbot-nginx


#Generate certification ssl for web site
certbot --nginx -d nginx-laravel.com -d www.nginx-laravel.com



##########################################################
##              OPEN HTTP'S SERVICE PORT                ##
##########################################################

# Abilitar el servicio http y https para nginx 
sudo firewall-cmd --zone=public --permanent --add-service=http
sudo firewall-cmd --zone=public --permanent --add-service=https


# Verificamos que el servicio http este activo 
firewall-cmd --permanent --list-all


# reinicimos el firewalld para que los cambio sufran efecto
systemctl restart firewalld

