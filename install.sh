#!/bin/sh
## check if docker-compose exist?
compose=$(which docker-compose)
if [ -z "$compose" ]; then
  echo "docker-compose not installed,"
  echo "follow this https://docs.docker.com/compose/install/ to install it first."
  exit 1
else
  if [ ! -x "$compose" ]; then
     echo "$compose is not executable,"
     echo "follow this https://docs.docker.com/compose/install/ to complete an installation"
     exit 1
  fi
fi
echo "Download latest WordPress..."
wget -O - https://wordpress.org/latest.tar.gz | tar zxv
mv wordpress html

echo "Create a WordPress service."
docker-compose up -d
mypassword=$(grep MYSQL_ROOT_PASSWORD docker-compose.yml|awk -F\= '{print $2}')
docker exec web sh -c "chown -R www-data:www-data /var/www/html"
docker exec db sh -c "mysql -p$mypassword -e 'create database wordpress;'" >/dev/null 2>&1
while [ $? -ne 0 ]; do
  echo "Initilize DB... (This might take a minute)"
  sleep 20
  docker exec db sh -c "mysql -p$mypassword -e 'create database wordpress;'" >/dev/null 2>&1
done
echo "done..."

echo "====================="
echo "WordPress site: $(hostname -I|awk '{print "http://"$1":8888"}')"
echo "[Database info]"
echo "db:   wordpress"
echo "host: db"
echo "user: root"
echo "pass: $mypassword"
echo "====================="

echo "Remove install.sh script."
#rm -f ./install.sh
