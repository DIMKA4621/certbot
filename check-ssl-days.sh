#!/bin/bash

response=$(curl -s --head -w %{http_code} "https://$1" -o /dev/null)
if [ ${response} -ne 000 ]; then
    data=`echo | openssl s_client -servername $1 -connect $1:${2:-443} 2>/dev/null | openssl x509 -noout -enddate | sed -e 's#notAfter=##'`
    ssldate=`date -d "${data}" '+%s'`
    nowdate=`date '+%s'`
    diff="$((${ssldate}-${nowdate}))"
    days_left=$((${diff}/86400))
    echo $days_left
else
    echo "-1"
fi
