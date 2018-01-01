#!/usr/bin/env bash

# Create credentials file
# Cryptostorm doesn't care what password you use so we use 'foo'
printf "$CRYPTOSTORM_USERNAME\nfoo" > /config/credentials

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

# Change all configs to use the specified port
find ovpn-configs -type f -exec sed -i "s/443/$PORT/g" {} \;

# Create /dev/net/tun
mkdir -p /dev/net
mknod /dev/net/tun c 10 200
chmod 600 /dev/net/tun

# Set up firewall to block all non-vpn traffic except DNS and ICMP (ping)
# Since Cryptostorm runs on port 443 this won't block everything
iptables -A OUTPUT -o tun0 -m comment --comment "vpn" -j ACCEPT
iptables -A OUTPUT -o eth0 -p icmp -m comment --comment "icmp" -j ACCEPT
iptables -A OUTPUT -d 192.168.0.0/16 -o eth0 -m comment --comment "lan /16" -j ACCEPT
iptables -A OUTPUT -d 172.16.0.0/12 -o eth0 -m comment --comment "lan /12" -j ACCEPT
iptables -A OUTPUT -d 10.0.0.0/8 -o eth0 -m comment --comment "lan /8" -j ACCEPT
iptables -A OUTPUT -o eth0 -p udp -m udp --dport $PORT -m comment --comment "openvpn" -j ACCEPT
iptables -A OUTPUT -o eth0 -p tcp -m tcp --dport $PORT -m comment --comment "openvpn" -j ACCEPT
iptables -A OUTPUT -o eth0 -p udp -m udp --dport 53 -m comment --comment "dns" -j ACCEPT
iptables -A OUTPUT -o eth0 -p tcp -m tcp --dport 53 -m comment --comment "dns" -j ACCEPT
iptables -A OUTPUT -o eth0 -j DROP


# Start openvpn (requires cap_add=NET_ADMIN)
openvpn --client --auth-user-pass /config/credentials --config /ovpn-configs/$CRYPTOSTORM_CONFIG_FILE
