# REV 0.1
# AUTHOR:       David E
# DESCRIPTION:	Image with DokuWiki & lighttpd
# TO_BUILD:	docker build -t macus/dokuwikii
# TO_RUN:	docker run -d -p 80:80 --name my_wiki macus/rpi-dokuwikii
   
FROM balenalib/rpi-raspbian:latest
MAINTAINER Macus

ENV DOKUWIKI_VERSION 2023-04-04a
ENV DOKUWIKI_CSUM 8A68393E689BF6D1130BFE660A19FC6B

ENV LAST_REFRESHED 11. September 2023

# Update & install packages & cleanup afterwards
RUN 	apt-get update && \
	apt-get -y upgrade && \
	apt-get -y install wget lighttpd php8-cgi php8-gd php8-ldap && \
	apt-get clean autoclean && \
	apt-get autoremove && \
	rm -rf /var/lib/{apt,dpkg,cache,log}

# Download & check & deploy dokuwiki & cleanup
RUN wget -q -O /dokuwiki.tgz "http://download.dokuwiki.org/src/dokuwiki/dokuwiki-$DOKUWIKI_VERSION.tgz" && \
	if [ "$DOKUWIKI_CSUM" != "$(md5sum /dokuwiki.tgz | awk '{print($1)}')" ];then echo "Wrong md5sum of downloaded file!"; exit 1; fi && \
	mkdir /dokuwiki && \
	tar -zxf dokuwiki.tgz -C /dokuwiki --strip-components 1 && \
	rm dokuwiki.tgz

# Set up ownership
RUN chown -R www-data:www-data /dokuwiki

# Configure lighttpd
ADD dokuwiki.conf /etc/lighttpd/conf-available/20-dokuwiki.conf
RUN lighty-enable-mod dokuwiki fastcgi accesslog
RUN mkdir /var/run/lighttpd && chown www-data.www-data /var/run/lighttpd

EXPOSE 80

VOLUME ["/dokuwiki/data/","/dokuwiki/lib/plugins/","/dokuwiki/conf/","/dokuwiki/lib/tpl/","/var/log/"]
ENTRYPOINT ["/usr/sbin/lighttpd", "-D", "-f", "/etc/lighttpd/lighttpd.conf"]