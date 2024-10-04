export RESTART_NGINX_CMD="sudo nginx -s reload"
if [ "$(${RESTART_NGINX_CMD} 1> /dev/null ; echo $?)" == "1" ]; then
    echo -e "\n${RED}Error${WHITE} when execute nginx commands.\nRun and relogin '${USER}' user to host:\nsudo usermod -aG www-data ${USER}\nsudo visudo  # and paste at the end: %www-data ALL=(root) NOPASSWD: /usr/sbin/nginx -s reload"
	exit 2
fi
bash renew.sh ${1}
