#!/bin/bash

# For host Nginx (default):
sudo nginx -s reload

# For Docker-based Nginx:
# docker exec -it nginx nginx -s reload

# For Docker Swarm Nginx:
# docker service update --force nginx_nginx
