Dialog gRCP Gateway
===================

Dialog API gRPC web gateway.

Build
-----

```
docker build -t quay.io/dlgim/dialog-grpc-web-gateway:<version> .
docker push quay.io/dlgim/dialog-grpc-web-gateway
```

Usage
-----

```
docker run -p 8080:8080 -e API_HOST=api.dlg.im:443 quay.io/dlgim/dialog-grpc-web-gateway
```

| name        | default | description                 |
|-------------|---------|-----------------------------|
| HOST        | 0.0.0.0 | Listen port                 |
| PORT        | 8080    | Listen host                 |
| API_HOST    | null    | Dialog API `<host>:<port>`  |
| CORS_ORIGIN | true    | Comma separated origins     |
