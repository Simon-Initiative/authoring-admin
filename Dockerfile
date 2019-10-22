FROM node:carbon

RUN mkdir -p /app
WORKDIR /app

ENV NPM_CONFIG_PREFIX=/home/node/.npm-global

RUN wget "https://github.com/elm/compiler/releases/download/0.19.0/binaries-for-linux.tar.gz" && \
    tar xzf binaries-for-linux.tar.gz && \
    mv elm /usr/local/bin/

USER node

RUN mkdir ~/.npm-global && npm install -g elm@latest-0.19.0
ENV PATH="/home/node/.npm-global/bin:${PATH}"

RUN npm install -g uglify-js

USER root 

COPY package.json /app
RUN npm install

COPY dist.sh /app
RUN chmod +x /app/dist.sh

CMD ["/app/dist.sh"]