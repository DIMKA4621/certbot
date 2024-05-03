#!/bin/bash

days_left=$(./check-ssl-days.sh $1)
if [ ${days_left} -ne -1 ]; then
  ./start.sh $1
fi
