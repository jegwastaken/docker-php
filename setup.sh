#!/bin/bash

. .env

devport=''
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
else
devport="$(
cat <<EOF

    ports:
      '${DEV_PORT-8282}:80'
EOF
)"
fi

cat > docker-compose.yml <<EOF
version: '3.3'

services:
  ${COMPOSE_PROJECT_DOMAIN}:
    image: nginx:alpine
    restart: unless-stopped
    container_name: ${COMPOSE_PROJECT_NAME}_nginx
    depends_on:
      - ${COMPOSE_PROJECT_NAME}_php
    volumes:
      - ./www:/var/www/html
      - ./nginx/logs:/var/log/nginx
      - ./nginx/default.conf:/etc/nginx/default.template
      - ./nginx/extras:/etc/nginx/extras
    environment:
      PHP_HOST: ${COMPOSE_PROJECT_NAME}_php:9000
      VIRTUAL_HOST: ${COMPOSE_PROJECT_DOMAIN}
    command: >
      /bin/sh -c "envsubst '\$\$PHP_HOST'
      < /etc/nginx/default.template >
      /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'"
  ${COMPOSE_PROJECT_NAME}_php:
    build: php
    restart: unless-stopped
    container_name: ${COMPOSE_PROJECT_NAME}_php${devport}
    volumes:
      - ./www:/var/www/html
      - ./default.conf:/etc/nginx/conf.d/${network}
EOF
