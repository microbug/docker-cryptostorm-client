FROM alpine:3.9

# Download cryptostorm ovpn files, process them to allow using an auth file and custom CA cert location
RUN wget https://github.com/cryptostorm/cryptostorm_client_configuration_files/archive/master.zip \
    && mkdir -p ovpn-configs \
    && unzip -q master.zip \
    && mv cryptostorm_client_configuration_files-master/ecc/* ovpn-configs \
    && rm -rf cryptostorm_client_configuration_files-master master.zip ovpn-configs/README.md ovpn-configs/ed25519 ovpn-configs/ed448 \
    && find ovpn-configs -type f -exec sed -i 's/auth-user-pass/#auth-user-pass/g' {} \; \
    && find ovpn-configs -type f -exec sed -i 's/#auth-nocache/auth-nocache/g' {} \;

RUN apk --no-cache add openvpn bash curl

ENV CRYPTOSTORM_USERNAME=nobody
ENV CRYPTOSTORM_CONFIG_FILE=Balancer_UDP.ovpn
ENV PORT=1194

HEALTHCHECK --interval=60s --timeout=15s --start-period=120s \
             CMD curl -L 'https://api.ipify.org' 

ADD init.sh /config/init.sh
ADD update-resolv-conf /etc/openvpn/update-resolv-conf

CMD ["/config/init.sh"]
