/*
 * Copyright 2017 dialog LLC <info@dlg.im>
 */

require("dotenv").config();

const fs = require("fs");
const path = require("path");
const express = require("express");
const http = require("http");
const bodyParser = require("body-parser");
const cors = require("cors");

const { createServer: createGrpcGateway } = require("@dlghq/grpc-web-gateway");

const jsonParser = bodyParser.json();

function parseEnv(name, parse, validate) {
  const value = parse(process.env[name]);
  const error = validate(value);
  if (error) {
    console.error(error);
    process.exit(1);
    throw new Error(error);
  }

  return value;
}

const config = {
  listen: {
    host: parseEnv("HOST", value => value || "0.0.0.0", () => null),
    port: parseEnv("PORT", value => parseInt(value, 10) || 8080, () => null)
  },
  api: {
    host: parseEnv(
      "API_HOST",
      value => value || "localhost:3000",
      value => (value ? null : "API_HOST not defined")
    ),
    secure: parseEnv("API_SECURE", value => Boolean(value), () => null)
  },
  origin: parseEnv(
    "CORS_ORIGIN",
    value =>
      (value || "")
        .split(",")
        .map(url => url.trim())
        .filter(url => url.length),
    () => null
  )
};

const origin = parseEnv(
  "CORS_ORIGIN",
  value =>
    (value || "")
      .split(",")
      .map(url => url.trim())
      .filter(url => url.length),
  () => null
);

console.log("CORS origins: ", origin);

const app = express();
const corsOptions = { origin: true };
app.use(cors(corsOptions));
app.get("/info", jsonParser, (req, res) => {
  const pkg = require("../package.json");
  const data = {
    name: pkg.name,
    version: pkg.version
  };
  res.json({ status: "OK", data });
});
const server = http.createServer(app);
const gatewayHost = 8081;
createGrpcGateway({
  server,
  api: config.api.host,
  cors: {
    origin: config.origin.length ? config.origin : true
  },
  protoFiles: [
    path.resolve(__dirname, "../node_modules/@dlghq/dialog-api/js/api.proto"),
    path.resolve(__dirname, "../node_modules/@dlghq/server-api-calls-sdk/server.proto")
    // path.resolve(
    //   __dirname,
    //   "../node_modules/@dlghq/grpc-web-gateway/example/proto/api.proto"
    // )
  ],
  filterHeaders(header) {
    switch (header) {
      case "dn":
      case "serial":
      case "verified":
      case "fingerprint":
      case "client_cert":
        return true;

      default:
        if (header.startsWith("x-")) {
          return true;
        }

        return false;
    }
  }
});

server.listen(config.listen, error => {
  if (error) {
    console.error(error);
    process.exit(1);
  } else {
    const listening = `http://${config.listen.host}:${config.listen.port}`;
    const proxying = `http${config.api.secure ? "s" : ""}://${config.api.host}`;
    console.info(
      `Gateway started. Listening ${listening}. Proxying ${proxying}.`
    );
  }
});
