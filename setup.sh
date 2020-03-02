#!/bin/bash

. ./.env

network=''

if [ ! -z ${NETWORKS_DEFAULT_EXTERNAL_NAME} ]
then
network="$(
cat <<EOF


networks:
  default:
    external:
      name: ${NETWORKS_DEFAULT_EXTERNAL_NAME}
EOF
)"
fi

cat > docker-compose.yml <<EOF
version: '3.3'

services:
  ${PHP_DOMAIN}:
    image: nginx:alpine
    restart: unless-stopped
    container_name: ${PHP_DOMAIN}
    depends_on:
      - ${PHP_ID}_php
    volumes:
      - ./ncache:/ncache
      - ./www:/var/www/html
      - ./nginx/logs:/var/log/nginx
      - ./nginx/default.conf:/etc/nginx/default.template
      - ./nginx/extras:/etc/nginx/extras
    environment:
      PHP_HOST: ${PHP_ID}_php:9000
      VIRTUAL_HOST: ${PHP_DOMAIN}
      LETSENCRYPT_HOST: ${PHP_DOMAIN}
    command: >
      /bin/sh -c "envsubst '\$\$PHP_HOST'
      < /etc/nginx/default.template >
      /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'"
  ${PHP_ID}_php:
    build: php
    restart: unless-stopped
    container_name: ${PHP_ID}_php
    volumes:
      - ./ncache:/ncache
      - ./www:/var/www/html
      - ./default.conf:/etc/nginx/conf.d/${network}
EOF
