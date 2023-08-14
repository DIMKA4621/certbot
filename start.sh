#!/bin/bash
CUR_PATH="/var/www/certbot"
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
WHITE="\033[0m"

cd ${CUR_PATH} || return 2
read -p "Enter domain: " DOMAIN
if ! echo "$DOMAIN" | grep -qE "^[a-zA-Z0-9\-_\.]{4,}"; then
  echo "FAIL! Domain is not valid"
  return 0;
fi

DOCKER_RUN="docker run \
--name $DOMAIN-certbot \
-v $CUR_PATH/project/:/var/www/certbot/project/ \
-v $CUR_PATH/$DOMAIN/letsencrypt/:/etc/letsencrypt/ \
-v $CUR_PATH/$DOMAIN/letsencrypt/log/:/var/log/letsencrypt/ \
certbot/certbot"

file_path="/etc/nginx/conf.d/certbot-$DOMAIN.conf"
echo -e "server {\n\
    listen 80;\n\
    listen [::]:80;\n\
\n\
    server_name $DOMAIN;\n\
\n\
    location ~ /.well-known/acme-challenge {\n\
        allow all;\n\
        root /var/www/certbot/project/;\n\
    }\n\
\n\
    location / {\n\
        rewrite ^ https://\$host\$request_uri? permanent;\n\
    }\n\
}" | sudo tee ${file_path} &>/dev/null

if [ -d ./${DOMAIN}/letsencrypt/live/${DOMAIN} ]; then
    echo -e "Ssl keys for $DOMAIN already exist.\n${YELLOW}Updating${WHITE} ssl keys..."
    sudo ${DOCKER_RUN} renew --force-renewal --force-interactive &&
    sudo docker rm -f "$DOMAIN-certbot" &> /dev/null
else
    mkdir -p ./${DOMAIN}/letsencrypt/log
    sudo nginx -t && sudo nginx -s reload
    echo -e "${GREEN}Creating${WHITE} ssl keys..."
    sudo ${DOCKER_RUN} certonly --webroot --webroot-path=/var/www/certbot/project/ --email mail@gmail.com --agree-tos --no-eff-email -d ${DOMAIN} &&
    sudo docker rm -f "$DOMAIN-certbot" &> /dev/null
fi

sudo rm "${file_path}"

if [ $? -eq 0 ]; then
    echo -e "\n${GREEN}Successfully${WHITE} creating ssl keys"
    sudo nginx -t && sudo nginx -s reload &> /dev/null
else
    echo -e "\n${RED}Fail${WHITE} creating ssl keys"
    sudo docker rm -f "$DOMAIN-certbot" &> /dev/null
fi
