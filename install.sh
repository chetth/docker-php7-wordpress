#!/bin/sh
echo "Download latest WordPress..."
wget -o /dev/null -O - https://wordpress.org/latest.tar.gz | tar zx
mv wordpress html

echo "Create a WordPress service."
docker-compose up -d
mypassword=$(grep MYSQL_ROOT_PASSWORD docker-compose.yml|awk -F\= '{print $2}')
docker exec db sh -c "mysql -p$mypassword -e 'create database wordpress;'"
docker exec web sh -c "chown -R www-data:www-data /var/www/html"

echo "Remove install.sh script."
rm -f ./install.sh

echo "====================="
echo "WordPress site: $(hostname -I|awk '{print "http://"$1":8888"}')"
echo "====================="
