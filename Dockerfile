FROM node:lts-alpine

WORKDIR /app
COPY . /app

RUN npm install -g appcenter-cli \
    && apk update \
    && apk add git \
    && apk add bash \
    && apk add jq

RUN chmod +x /app/main.sh

ENTRYPOINT [ "/app/main.sh" ]