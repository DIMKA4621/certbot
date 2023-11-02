#!/bin/bash
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
WHITE="\033[0m"

read -rp "Enter domain: " DOMAIN
if ! echo ${DOMAIN} | grep -qE "^[a-zA-Z0-9\-_\.]{4,}"; then
    echo -e "${RED}FAIL!${WHITE} Domain '$DOMAIN' is not valid"
    return 0
fi

DOCKER_RUN="docker run \
--name certbot-$DOMAIN \
-v $(pwd)/project/:/var/www/certbot/project/ \
-v $(pwd)/$DOMAIN/letsencrypt/:/etc/letsencrypt/ \
-v $(pwd)/$DOMAIN/letsencrypt/log/:/var/log/letsencrypt/ \
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
        root $(pwd)/project/;\n\
    }\n\
\n\
}" | sudo tee ${file_path} &>/dev/null
sudo nginx -t && sudo nginx -s reload

{
    if [ -d ${DOMAIN}/letsencrypt/live/${DOMAIN} ]; then
        echo -e "\nSsl keys for $DOMAIN already exist.\n${YELLOW}Try updating${WHITE} ssl keys..."
        sudo ${DOCKER_RUN} renew --force-renewal
    else
        echo -e "\n${GREEN}Creating${WHITE} ssl keys..."
        sudo ${DOCKER_RUN} certonly --webroot --webroot-path=/var/www/certbot/project/ --email mail@gmail.com --agree-tos --no-eff-email -d "$DOMAIN"
        sudo chmod -R 755 ${DOMAIN}
    fi
} &&
echo -e "\n${GREEN}Successfully${WHITE} creating ssl keys" ||
echo -e "\n${RED}Fail${WHITE} creating ssl keys"

sudo docker rm -f certbot-${DOMAIN} &>/dev/null
sudo rm ${file_path}
sudo nginx -t && sudo nginx -s reload
