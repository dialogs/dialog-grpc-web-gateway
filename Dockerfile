FROM node:10.11-alpine

ARG NPM_TOKEN
ARG NPM_REGISTRY

WORKDIR /opt/dialog-grpc-gateway

COPY src/ src/
COPY package.json package.json

RUN echo "//registry.npmjs.org/:_authToken=$NPM_TOKEN" > ~/.npmrc
RUN npm install
RUN rm ~/.npmrc

ENTRYPOINT ["node", "src/index.js"]
