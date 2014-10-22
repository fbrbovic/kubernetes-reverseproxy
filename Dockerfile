#
# Reverse proxy for kubernetes
#
FROM ubuntu:latest

ENV DEBIAN_FRONTEND noninteractive

# Prepare requirements 
RUN apt-get update -qy && \
    apt-get install --no-install-recommends -qy software-properties-common

# setup confd
ADD https://github.com/kelseyhightower/confd/releases/download/v0.6.3/confd-0.6.3-linux-amd64 /usr/local/bin/confd
RUN chmod u+x /usr/local/bin/confd && \
	mkdir -p /etc/confd/conf.d && \
	mkdir -p /etc/confd/templates

ADD ./src/confd/conf.d/myconfig.toml /etc/confd/conf.d/myconfig.toml
ADD ./src/confd/templates/nginx.tmpl /etc/confd/templates/nginx.tmpl
ADD ./src/confd/confd.toml /etc/confd/confd.toml

# Install Nginx.
RUN add-apt-repository -y ppa:nginx/stable && \
    apt-get update -q && \
    apt-get install --no-install-recommends -qy nginx && \
    chown -R www-data:www-data /var/lib/nginx && \
    rm -f /etc/nginx/sites-available/default

ADD ./src/boot.sh /opt/boot.sh
RUN chmod +x /opt/boot.sh

EXPOSE 80 443

# Run the boot script
CMD /opt/boot.sh
