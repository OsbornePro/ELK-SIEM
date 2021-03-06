# Elastic (ELK) static v7.13.4
### WORK IN PROGRESS
This directory contains code to run an Elasticsearch stack. It is not yet complete and should not be assumed for use in a production environment. As of right now the ```docker-compose build``` command does not work on MacOS. It returns "File Not Found" errors when run. This is because the MacOS has a file structure that is different than other Open-Source Linux based distros the tool was written for.

**Update-Elasticsearch.ps1** is a PowerShell script I am working on to automatically update Elasticsearch when a new version is available.

## Updated
This repo has been updated on 9/1/2021

## Generate a CA Certificate
```bash
openssl genrsa -out ca.key 2048
openssl req -x509 -new -nodes -key ca.key -sha256 -days 1825 -out ca.crt
```

## First Download the Git repo
```bash
# Create directory for your docker images (Only root user should ever have permissions to run docker)
sudo -i
# Enter Password:
mkdir -p /root/docker/images
cd /root/docker/images
git clone https://github.com/OsbornePro/ELK-SIEM.git
cd ELK-SIEM/
```

## Then Generate Your own OpenSSL certs
```
# Create a CSR for your domains CA. If you do this be sure to replace the SSL certificates in the containers
openssl req -new -newkey rsa:2048 -nodes -out request.csr -keyout private.key

# Generate your Diffie-Hellman key
openssl dhparam -out conf/ssl/dhparam.pem 2048

# Use a self signed certificate for nginx and elasticsearch
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout conf/ssl/docker.key -out conf/ssl/docker.crt

# Use a self signed certificate for kibana
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout conf/ssl/kibana.key -out conf/ssl/kibana.crt

# Use a self signed certificate for logstash
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout conf/ssl/logstash.key -out conf/ssl/logstash.crt
```

## Run your docker image
```bash
# Download docker images
docker-compose build

# Start the docker images
docker-compose up -d

# View info on running images
docker-compose ps
docker stats
```

## System Minimum Requirements
- 4 CPU cores
- 4 GBs of RAM
- 60 GB of HDD


## References
- [DockerHub - Nginx](https://hub.docker.com/_/nginx?tab=tags)
- [Dockerhub - Logstash](https://hub.docker.com/_/logstash)
- [Dockerhub - Kibana](https://hub.docker.com/_/kibana)
- [Dockerhub - Elasticsearch](https://hub.docker.com/_/elasticsearch)
