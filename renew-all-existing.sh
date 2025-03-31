#!/bin/bash

count=0

for dir in "$(pwd)"/*; do
  if [ -d ${dir} ] && [ "$(basename ${dir})" != "project" ]; then
    bash generate-ssl.sh "$(basename "$dir")" --renew
    count=$((count + 1))

    if [ ${count} -eq 9 ]; then
      sleep $((185 * 60))
      count=0
    fi
  fi
done

bash restart-nginx.sh
