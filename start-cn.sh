export RESTART_NGINX_CMD="docker exec -it nginx nginx -s reload"
bash renew.sh ${1}
