# Hopla docker
# https://cli.vuejs.org/guide/deployment.html#docker-nginx

FROM node:16 as build
LABEL maintainer="jan.vandenschilden@ugent.be"

WORKDIR /usr/src/app
COPY package.json .
RUN yarn install
COPY ./ .
RUN yarn build --prod


from nginx:alpine as web
RUN mkdir /app
COPY --from=build /usr/src/app/dist /app
COPY docker/nginx.conf /etc/nginx/nginx.conf