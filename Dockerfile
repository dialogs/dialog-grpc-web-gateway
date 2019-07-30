FROM node:10.11-alpine

ARG NPM_TOKEN
ARG NPM_REGISTRY

WORKDIR /opt/dialog-grpc-gateway

COPY src/ src/
COPY package.json package.json

RUN npm install

ENTRYPOINT ["node", "src/index.js"]
