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
      -v ./acme-dns-auth.py:/etc/letsencrypt/acme-dns-auth.py:ro \
      certbot/certbot \
      certonly --manual --manual-auth-hook /etc/letsencrypt/acme-dns-auth.py --email mail@gmail.com --agree-tos \
        --no-eff-email --preferred-challenges dns --debug-challenges -d ${DOMAIN}

    if [ $? -eq 0 ]; then
        echo -e "\n${GREEN}Successfully${WHITE} creating ssl keys"
        mkdir -p ${DOMAIN}
        docker cp certbot-${DOMAIN}:/etc/letsencrypt ${DOMAIN}/
        cp ${DOMAIN}/letsencrypt/live/${DOMAIN}/fullchain.pem ${DOMAIN}/fullchain.pem
        cp ${DOMAIN}/letsencrypt/live/${DOMAIN}/privkey.pem ${DOMAIN}/privkey.pem
    else
        echo -e "\n${RED}Fail${WHITE} creating ssl keys"
        docker cp certbot-${DOMAIN}:/var/log/letsencrypt/letsencrypt.log ${DOMAIN}/letsencrypt.log
    fi
    docker rm -f certbot-${DOMAIN}
fi
