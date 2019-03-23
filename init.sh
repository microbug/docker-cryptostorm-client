#!/usr/bin/env bash

# Create credentials file
# Cryptostorm doesn't care what password you use so we use 'foo'
printf '%s\nfoo' "$CRYPTOSTORM_USERNAME" > /config/credentials

# Remove group and other permissions (prevents an openvpn log warning)
chmod go-wrx /config/credentials

# Check that $PORT is set and it is a number less than 65536
case $PORT in
    ''|*[!0-9]*)
        echo "Specified port $PORT is invalid, exiting"
        exit 1
        ;;
    *) ;;
esac

if [ "$PORT" -gt "65535" ]; then
    echo "Specified port $PORT is greater than the maximum (65535), exiting"
    exit 2
fi

# Add three lines to each config file. Makes /etc/openvpn/update-resolv-conf
# run after and before connecting. Details: https://cryptostorm.is/nix#terminal
for conf in /ovpn-configs/*.ovpn; do
	echo 'script-security 2' >> $conf;
 	echo 'up /etc/openvpn/update-resolv-conf' >> $conf;
 	echo 'down /etc/openvpn/update-resolv-conf' >> $conf;
done


# Change all configs to use the specified port
find ovpn-configs -type f -exec sed -i "s/443/$PORT/g" {} \;

# Create /dev/net/tun
mkdir -p /dev/net
mknod /dev/net/tun c 10 200
chmod 600 /dev/net/tun

# Start openvpn (requires NET_ADMIN)
openvpn --client --auth-user-pass /config/credentials --config "/ovpn-configs/$CRYPTOSTORM_CONFIG_FILE"

