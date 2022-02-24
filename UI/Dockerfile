# Hopla docker
FROM node:16
LABEL maintainer="jan.vandenschilden@gmail.com"

# Download Github repository 
WORKDIR /home/node
ADD ./ /home/node/Hopla/

# Switch to node user, go inside Hopla/UI dir and install packages
WORKDIR /home/node/Hopla/UI
RUN yarn install
EXPOSE 8080


# docker run hopla
CMD ["yarn", "serve"]
