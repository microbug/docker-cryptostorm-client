#!/usr/bin/env bash

# Create credentials file
# Cryptostorm doesn't care what password you use so we use 'foo'
printf '%s\nfoo' "$CRYPTOSTORM_USERNAME" > /ovpn-credentials

# Remove group and other permissions (prevents an openvpn log warning)
chmod go-wrx /ovpn-credentials

# Add three lines to each config file. Makes /etc/openvpn/update-resolv-conf
# run after and before connecting. Details: https://cryptostorm.is/nix#terminal
for conf in /ovpn-configs/*.ovpn; do
	echo 'script-security 2' >> $conf;
 	echo 'up /etc/openvpn/update-resolv-conf' >> $conf;
 	echo 'down /etc/openvpn/update-resolv-conf' >> $conf;
done


# Change all configs to use the specified port
find ovpn-configs -type f -exec sed -i "s/443/$CONNECTION_PORT/g" {} \;

# Create /dev/net/tun
mkdir -p /dev/net
mknod /dev/net/tun c 10 200
chmod 600 /dev/net/tun

# Start openvpn (requires NET_ADMIN)
openvpn --client --auth-user-pass /ovpn-credentials --config "/ovpn-configs/$CRYPTOSTORM_CONFIG_FILE"

