#!/bin/bash
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
WHITE="\033[0m"

DOMAIN=${1}
PWDIR=$(pwd)

if [ "${DOMAIN}" == "" ]; then
  echo -e "\n${RED}Error!${WHITE} Domain not specified"
  exit 2
fi
if [ "$(bash restart-nginx.sh 1> /dev/null ; echo $?)" == "1" ]; then
    echo -e "\n${RED}Error${WHITE} when execute restart nginx commands"
	exit 2
fi
if [ "$(touch /etc/nginx/conf.d/- && rm /etc/nginx/conf.d/- ; echo $?)" == "1" ]; then
	echo -e "\n${RED}Error!${WHITE} User not access write file to /etc/nginx/conf.d/ dir.\nRun and relogin '${USER}' user to host:\nsudo usermod -aG www-data ${USER}\nsudo chown root:www-data /etc/nginx/conf.d\nsudo chmod g+rw /etc/nginx/conf.d\n"
	exit 2
fi
if [ "$(docker ps 1> /dev/null ; echo $?)" == "1" ]; then
	echo -e "\n${RED}Error!${WHITE} User not access to execute docker commands.\nRun and relogin '${USER}' user to host:\nsudo usermod -aG docker ${USER}\n"
	exit 2
fi

CERTBOT_NGINX_CONF="
server {
    listen 80;
    listen [::]:80;

    server_name ${DOMAIN};

    location ~ /.well-known/acme-challenge {
        allow all;
        root ${PWDIR}/project/;
    }
}"
echo -e "${CERTBOT_NGINX_CONF}" > /etc/nginx/conf.d/0-certbot-${DOMAIN}.conf
bash restart-nginx.sh

mkdir -p project ${DOMAIN}
docker run \
  --name certbot-${DOMAIN} \
  -v ${PWDIR}/project:${PWDIR}/project \
  certbot/certbot \
  certonly --webroot --webroot-path=${PWDIR}/project --email mail@gmail.com --agree-tos --no-eff-email -d ${DOMAIN}

if [ $? -eq 0 ]; then
    echo -e "\n${GREEN}Successfully${WHITE} creating ssl keys"
    docker cp certbot-${DOMAIN}:/etc/letsencrypt/archive/${DOMAIN}/fullchain1.pem ${DOMAIN}/fullchain.pem
    docker cp certbot-${DOMAIN}:/etc/letsencrypt/archive/${DOMAIN}/privkey1.pem ${DOMAIN}/privkey.pem
    sudo chown -R www-data:www-data ${DOMAIN} &> /dev/null
    sudo chmod -R +r ${DOMAIN} &> /dev/null
else
    echo -e "\n${RED}Fail${WHITE} creating ssl keys"
    docker cp certbot-${DOMAIN}:/var/log/letsencrypt/letsencrypt.log ./letsencrypt.log
fi

docker rm -f certbot-${DOMAIN}
rm /etc/nginx/conf.d/0-certbot-${DOMAIN}.conf
bash restart-nginx.sh
