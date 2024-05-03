#!/bin/bash
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
WHITE="\033[0m"

export DOMAIN=${1}
export PWDIR=$(pwd)

if [ "${DOMAIN}" == "" ]; then
  echo -e "\n${RED}Error!${WHITE} Domain not specified"
else
    nginx_conf="0-certbot-${DOMAIN}.conf"
    echo -e "server {\n\
        listen 80;\n\
        listen [::]:80;\n\
    \n\
        server_name $DOMAIN;\n\
    \n\
        location ~ /.well-known/acme-challenge {\n\
            allow all;\n\
            root ${PWDIR}/project/;\n\
        }\n\
    \n\
    }" > ${nginx_conf}
    sudo mv ${nginx_conf} /etc/nginx/conf.d/
    sudo nginx -s reload

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
    else
        echo -e "\n${RED}Fail${WHITE} creating ssl keys"
        docker cp certbot-${DOMAIN}:/var/log/letsencrypt/letsencrypt.log ./letsencrypt.log
    fi

    docker rm -f certbot-${DOMAIN}
    sudo rm /etc/nginx/conf.d/${nginx_conf}
    sudo nginx -s reload
fi
