# Elastic (ELK) static v7.12
This directory contains code to run an Elastic stack

## Updated
This repo has been updated on 4/14/2021

## Generate a CA Certificate
```bash
openssl genrsa -out ca.key 2048
openssl req -x509 -new -nodes -key ca.key -sha256 -days 1825 -out ca.crt
```

## Generate Your own OpenSSL certs
1. ```
# Create a CSR for your domains CA. If you do this be sure to replace the SSL certificates in the containers
openssl req -new -newkey rsa:2048 -nodes -out request.csr -keyout private.key

# Use a self signed certificate for nginx and elasticsearch
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout conf/ssl/docker.key -out conf/ssl/docker.crt
openssl dhparam -out conf/ssl/dhparam.pem 2048

# Use a self signed certificate for kibana
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout conf/ssl/kibana.key -out conf/ssl/kibana.crt

# Use a self signed certificate for logstash
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout conf/ssl/logstash.key -out conf/ssl/logstash.crt
```

## Spin up an ELK stack
1. `docker-compose build`
2. `docker-compose up -d`
3. `docker-compose ps`
4. `docker stats`

## System requirements
* 4 CPU cores
* 4 GBs of RAM
* 60 GB of HDD


## References
* [DockerHub - Nginx](https://hub.docker.com/_/nginx?tab=tags)
* [Dockerhub - Logstash](https://hub.docker.com/_/logstash)
* [Dockerhub - Kibana](https://hub.docker.com/_/kibana)
* [Dockerhub - Elasticsearch](https://hub.docker.com/_/elasticsearch)
