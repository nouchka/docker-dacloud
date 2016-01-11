FROM debian:wheezy
MAINTAINER Jean-Avit Promis "docker@katagena.com"

##https://github.com/jbogatay/docker-piavpn
##https://github.com/kylemanna/docker-openvpn
##https://github.com/n1nj4sec/pr0cks
##https://blog.jessfraz.com/post/tor-socks-proxy-and-privoxy-containers/

ENV OVPN_LOGIN ""
ENV OVPN_PASSWORD ""
ENV OVPN_FILE       "Italy - Milano.ovpn"
ENV OPENVPN /etc/openvpn

## Jessie build to have dante server
#ENV DANTE_VER 1.4.1
#ENV DANTE_URL https://www.inet.no/dante/files/dante-$DANTE_VER.tar.gz
#ENV DANTE_MD5 68c2ce12119e12cea11a90c7a80efa8f
#ENV DANTE_FILE dante.tar.gz
#ENV DANTE_TEMP dante
#ENV DANTE_DEPS build-essential curl
#RUN apt-get update \
#    && apt-get install -y $DANTE_DEPS \
#    && mkdir $DANTE_TEMP \
#        && cd $DANTE_TEMP \
#        && curl -sSL $DANTE_URL -o $DANTE_FILE \
#        && echo "$DANTE_MD5 $DANTE_FILE" | md5sum -c \
#        && tar xzf $DANTE_FILE --strip 1 \
#        && ./configure \
#        && make install \
#        && cd .. \
#        && rm -rf $DANTE_TEMP \
#    && apt-get purge -y --auto-remove $DANTE_DEPS \
#    && rm -rf /var/lib/apt/lists/*

RUN echo "APT::Install-Recommends 0;" >> /etc/apt/apt.conf.d/01norecommends &&\
    echo "APT::Install-Suggests 0;" >> /etc/apt/apt.conf.d/01norecommends &&\
    apt-get update &&\
    apt-get install -qy openvpn runit curl ca-certificates iptables procps dante-server git privoxy &&\
    apt-get clean &&\
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

##ADD local config
ADD https://raw.githubusercontent.com/jfrazelle/dockerfiles/master/privoxy/privoxy.conf /etc/privoxy/config
RUN chown privoxy: /etc/privoxy/config
RUN sed -i 's/forward-socks5 \/ torproxy:9050 ./forward-socks5 \/ localhost:1080 ./' /etc/privoxy/config

COPY service/ /etc/service/
COPY sockd.conf /etc/

COPY ovpn_env.sh /etc/openvpn/
RUN chmod +x /etc/openvpn/ovpn_env.sh

COPY start.sh /start.sh
RUN chmod +x /start.sh

RUN chmod +x /etc/service/openvpn/run
RUN chmod +x /etc/service/sockd/run
RUN chmod +x /etc/service/privoxy/run

VOLUME /ovpn/
WORKDIR /ovpn

EXPOSE 8118 1080

CMD /start.sh
