#!/bin/bash
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
WHITE="\033[0m"

export DOMAIN=${1}

if [ "${DOMAIN}" == "" ]; then
  echo -e "\n${RED}Error!${WHITE} Domain not specified"
else
    docker run -it \
      --name certbot-${DOMAIN} \
      -v ./${DOMAIN}/letsencrypt:/etc/letsencrypt \
      certbot/certbot renew --force-renewal

    if [ $? -eq 0 ]; then
        echo -e "\n${GREEN}Successfully${WHITE} creating ssl keys"
        mkdir -p ${DOMAIN}
        docker cp certbot-${DOMAIN}:/etc/letsencrypt/archive/${DOMAIN}/fullchain1.pem ${DOMAIN}/fullchain.pem
        docker cp certbot-${DOMAIN}:/etc/letsencrypt/archive/${DOMAIN}/privkey1.pem ${DOMAIN}/privkey.pem
        docker cp certbot-${DOMAIN}:/etc/letsencrypt ${DOMAIN}/
    else
        echo -e "\n${RED}Fail${WHITE} creating ssl keys"
        docker cp certbot-${DOMAIN}:/var/log/letsencrypt/letsencrypt.log ./letsencrypt.log
    fi
    docker rm -f certbot-${DOMAIN}
fi