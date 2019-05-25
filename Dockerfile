FROM alpine:3.9

RUN wget https://github.com/just-containers/s6-overlay/releases/download/v1.22.1.0/s6-overlay-amd64.tar.gz \
    && tar xzf /s6-overlay-amd64.tar.gz \
    && rm -f s6-overlay-amd64.tar.gz

# Download cryptostorm ovpn files, process them to allow using an auth file and custom CA cert location
RUN wget https://github.com/cryptostorm/cryptostorm_client_configuration_files/archive/master.zip \
    && mkdir -p ovpn-configs \
    && unzip -q master.zip \
    && mv cryptostorm_client_configuration_files-master/ecc/* ovpn-configs \
    && rm -rf cryptostorm_client_configuration_files-master master.zip ovpn-configs/README.md ovpn-configs/ed25519 ovpn-configs/ed448 \
    && find ovpn-configs -type f -exec sed -i 's/auth-user-pass/#auth-user-pass/g' {} \; \
    && find ovpn-configs -type f -exec sed -i 's/#auth-nocache/auth-nocache/g' {} \; \
    && for conf in /ovpn-configs/*.ovpn; do \
	    echo 'script-security 2' >> $conf; \
 	    echo 'up /etc/openvpn/update-resolv-conf-up' >> $conf; \
 	    echo 'down /etc/openvpn/update-resolv-conf' >> $conf; \
    done

RUN apk --no-cache add openvpn bash curl openresolv

ENV CRYPTOSTORM_USERNAME=nobody
ENV CRYPTOSTORM_CONFIG_FILE=Balancer_UDP.ovpn
ENV CONNECTION_PORT=1194
# FORWARDING_PORT=0 disables port forwarding
ENV FORWARDING_PORT=0

ENV KILLSWITCH_CHECK_INTERVAL=30

HEALTHCHECK --interval=60s --timeout=20s --start-period=120s \
             CMD curl -L 'https://api.ipify.org' 

#ADD init.sh /init.sh
#ADD start-vpn.sh /start-vpn.sh
#ADD update-resolv-conf /etc/openvpn/update-resolv-conf

COPY root/ /

ENTRYPOINT ["/init"]
#CMD ["/init.sh"]
