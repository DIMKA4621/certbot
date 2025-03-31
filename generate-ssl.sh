#!/bin/bash

RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
WHITE="\033[0m"

usage() {
    echo -e "\nUsage: $0 <domain> [--http|--dns|--renew]"
    echo "Default mode is --http if no flag is specified"
    exit 1
}

if [ -z "$1" ]; then
    echo -e "\n${RED}Error!${WHITE} Domain not specified"
    usage
fi

export DOMAIN="$1"
shift

MODE="--http"
if [ "$1" ]; then
    case "$1" in
        --http|--dns|--renew)
            MODE="$1"
            ;;
        *)
            echo -e "\n${RED}Error!${WHITE} Invalid mode: $1"
            usage
            ;;
    esac
fi

PWDIR=$(pwd)
mkdir -p ${DOMAIN}

case ${MODE} in
    --http)
        # HTTP validation checks
        if [ "$(bash restart-nginx.sh 1> /dev/null ; echo $?)" == "1" ]; then
            echo -e "\n${RED}Error${WHITE} when execute restart nginx commands"
            return 2 &> /dev/null
            exit 2
        fi
        if [ "$(touch /etc/nginx/conf.d/- && rm /etc/nginx/conf.d/- ; echo $?)" == "1" ]; then
            echo -e "\n${RED}Error!${WHITE} User not access write file to /etc/nginx/conf.d/ dir.\nRun and relogin '${USER}' user to host:\nsudo usermod -aG www-data ${USER}\nsudo chown root:www-data /etc/nginx/conf.d\nsudo chmod g+rw /etc/nginx/conf.d\n"
            return 2 &> /dev/null
            exit 2
        fi
        if [ "$(docker ps 1> /dev/null ; echo $?)" == "1" ]; then
            echo -e "\n${RED}Error!${WHITE} User not access to execute docker commands.\nRun and relogin '${USER}' user to host:\nsudo usermod -aG docker ${USER}\n"
            return 2 &> /dev/null
            exit 2
        fi

        # Configure nginx
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

        # Run certbot
        docker run \
          --name certbot-${DOMAIN} \
          -v ${PWDIR}/project:${PWDIR}/project \
          certbot/certbot \
          certonly --webroot --webroot-path=${PWDIR}/project --email mail@gmail.com --agree-tos --no-eff-email -d ${DOMAIN}

        # Cleanup nginx config
        rm /etc/nginx/conf.d/0-certbot-${DOMAIN}.conf
        bash restart-nginx.sh
        ;;

    --dns)
        # Run certbot with DNS validation
        docker run -it \
          --name certbot-${DOMAIN} \
          -v ./acme-dns-auth.py:/etc/letsencrypt/acme-dns-auth.py:ro \
          certbot/certbot \
          certonly --manual --manual-auth-hook /etc/letsencrypt/acme-dns-auth.py --email mail@gmail.com --agree-tos \
            --no-eff-email --preferred-challenges dns --debug-challenges -d ${DOMAIN}
        ;;

    --renew)
        # Run certbot with DNS validation for renewal
        docker run -it \
          --name certbot-${DOMAIN} \
          -v ./${DOMAIN}/letsencrypt:/etc/letsencrypt \
          certbot/certbot renew --force-renewal
        ;;

    *)
        echo -e "\n${RED}Error!${WHITE} Invalid mode: ${MODE}"
        usage
        ;;
esac

# Handle results
if [ $? -eq 0 ]; then
    echo -e "\n${GREEN}Successfully${WHITE} creating ssl keys"
    {
        sudo docker cp certbot-${DOMAIN}:/etc/letsencrypt ${DOMAIN}/ && \
        sudo cp ${DOMAIN}/letsencrypt/live/${DOMAIN}/fullchain.pem ${DOMAIN}/fullchain.pem && \
        sudo cp ${DOMAIN}/letsencrypt/live/${DOMAIN}/privkey.pem ${DOMAIN}/privkey.pem && \
        sudo chown -R www-data:www-data ${DOMAIN}
    } || {
        echo -e "\n${RED}Fail${WHITE} copying ssl keys"
    }
else
    echo -e "\n${RED}Fail${WHITE} creating ssl keys"
    docker cp certbot-${DOMAIN}:/var/log/letsencrypt/letsencrypt.log ${DOMAIN}/letsencrypt.log
fi

# Cleanup
docker rm -f certbot-${DOMAIN} &> /dev/null
