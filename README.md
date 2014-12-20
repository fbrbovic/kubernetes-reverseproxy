kubernetes-reverseproxy Docker file
=======================


This repository contains **Dockerfile** that acts as reverse proxy for [Kubernetes](https://github.com/GoogleCloudPlatform/kubernetes) allowing you to route http traffic to kubernetes pods which are sharing the same host port. Requests are proxied based on the hostname.

This is useful in situations where you might want to run numerous websites on the same node ( with same public ip ).

This docker image (Dockerfile) uses [nginx](http://nginx.org/) as reverse proxy and [confd](https://github.com/kelseyhightower/confd) as a way to pull the kubernetes 'service' settings and build nginx configuration.

### Requirements
* This Dockerfile requires the latest kubernetes code which provides support for annotations and ip-per-service capabilities.
* Docker container must have access to the same Etcd cluster on which kubernetes is installed

### Base Docker Image

* [ubuntu](https://registry.hub.docker.com/_/ubuntu/)


### Installation

1. Install [Docker](https://www.docker.com/).

2. Download [automated build](https://registry.hub.docker.com/u/darkgaro/kubernetes-reverseproxy/) from public [Docker Hub Registry](https://registry.hub.docker.com/):

	```docker pull darkgaro/kubernetes-reverseproxy```

   	(alternatively, you can build an image from Dockerfile:

   	`docker build -t="darkgaro/kubernetes-reverseproxy" github.com/darkgaro/kubernetes-reverseproxy`)


### Usage

    docker run -d -e CONFD_ETCD_NODE=<ETCD-IP>:<ETCD-PORT> -t -p 80:80 darkgaro/kubernetes-reverseproxy

**ETCD-IP** = IP/hostname of the etcd server, this is the IP that is accessible from wihtin the container

**ETCD-PORT** = Etcd port, usually : 4001

Example:

	docker run -d -e CONFD_ETCD_NODE=172.17.8.101:4001 -t -p 80:80 darkgaro/kubernetes-reverseproxy

#### Configure kubernetes service

This dockerfile is using kubernetes "Annotations" property to provide instructions to the proxy on how to setup the routing.

The key used is kubernetesReverseproxy containing a json representation of the reverseProxy configuration.
A full configuration can looks like :
```json
{
	"hosts": [
		{"host": "sub1.example.com", "port": 80, "path": ["/test1", "/test2"], "defaultPath": "test1"},
		{"host": "sub2.example.com", "port": 443, "ssl": 1, "sslCrt": "cert.crt", "sslKey": "key.key", "path": ["/test3"], "defaultPath": "test3"},
		{"host": "sub3.example.com", "port": 80, "webSocket": 1},
	]
}	
```
Then it must be converted to string and set into the kubernetesReverseproxy parameter in the annotation section of your service:

```json
"annotations":{
	"kubernetesReverseproxy":"{\"hosts\": [{\"host\": \"some.host.name\", \"port\": \"port number\"}]}"
    }
```
**host** =  This is the hostname for which proxy will listen to and forward traffic to the kubernetes service/
It is used to fill in the nginx "server_name" property.

**port** =  This is the port number for which proxy will listen to.

**webSocket** =  1 | 0  [default 0] This enables websocket support in nginx, it adds to nginx :
```
                proxy_http_version 1.1;
                proxy_set_header Upgrade $http_upgrade;
                proxy_set_header Connection "upgrade";
```

**ssl** = 1 | 0 [default 0] This enables ssl support in nginx
**sslCrt** = The SSL certificate file for this service (must be located in /etc/nginx/ssl)
**sslKey** = The SSL private key file for this service (must be located in /etc/nginx/ssl)

Theses 3 properties adds to nginx :

```
								ssl_certificate           /etc/nginx/ssl/cert.crt;
								ssl_certificate_key       /etc/nginx/ssl/key.key;

								ssl on;
								ssl_session_cache  builtin:1000  shared:SSL:10m;
								ssl_protocols  TLSv1 TLSv1.1 TLSv1.2;
								ssl_ciphers HIGH:!aNULL:!eNULL:!EXPORT:!CAMELLIA:!DES:!MD5:!PSK:!RC4;
								ssl_prefer_server_ciphers on;
```

**path** = The path(s) to expose to proxy (ex: /frontend, /backend)
**defaultPath** = The default path to redirect to

Example kubernetes service:

```json
{
  "id": "wordpress-site",
  "kind": "Service",
  "apiVersion": "v1beta1",
  "port": 80,
  "containerPort": 80,
  "selector": {
    "name": "app-instance"
  },
  "annotations": {
	"kubernetesReverseproxy":"{\"hosts\": [{\"host\": \"some.host.name\", \"port\": \"port number\"}]}"
  }
}
```
