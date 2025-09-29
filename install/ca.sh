#!/bin/bash
source docker.env
FRONT_DOMAIN=$(echo $FRONTEND_HOSTNAME | cut -d/ -f 3)
KC_DOMAIN=$(echo $KC_HOSTNAME | cut -d/ -f 3)
mkdir -p ca
cd ca
[ -f "ca-key.pem" ] && echo "Found CA key" || openssl genrsa 2048 > ca-key.pem
[ -f "ca-crt.pem" ] && echo "Found CA crt" || openssl req -new -x509 -nodes -days 365000 -subj "/C=RU/O=mrtstg Inc." -key ca-key.pem -out ca-crt.pem
[ -f "keycloak.key" ] && echo "Found keycloak key" || openssl req -newkey rsa:2048 -nodes -days 365000 -subj "/CN=$KC_DOMAIN" -keyout keycloak.key -out keycloak-req.pem
[ -f "keycloak.crt" ] && echo "Found keycloak crt" || openssl x509 -req -days 365000 -set_serial "0x`openssl rand -hex 8`" -in keycloak-req.pem -out keycloak.crt -CA ca-crt.pem -CAkey ca-key.pem
[ -f "labforge.key" ] && echo "Found labforge key" || openssl req -newkey rsa:2048 -nodes -days 365000 -subj "/CN=$FRONT_DOMAIN" -keyout labforge.key -out labforge-req.pem
[ -f "labforge.crt" ] && echo "Found keycloak crt" || openssl x509 -req -days 365000 -set_serial "0x`openssl rand -hex 8`" -in labforge-req.pem -out labforge.crt -CA ca-crt.pem -CAkey ca-key.pem
