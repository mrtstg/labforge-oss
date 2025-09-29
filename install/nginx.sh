#!/bin/bash
source docker.env
FRONT_DOMAIN=$(echo $FRONTEND_HOSTNAME | cut -d/ -f 3)
KC_DOMAIN=$(echo $KC_HOSTNAME | cut -d/ -f 3)
sed -i "s|.*server_name .*;|    server_name $KC_DOMAIN;|g" deployment/nginx/conf.prod/keycloak.conf
sed -i "s|.*server_name .*;|    server_name $FRONT_DOMAIN;|g" deployment/nginx/conf.prod/labforge.conf
