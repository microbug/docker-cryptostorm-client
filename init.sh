#!/usr/bin/env bash

# Create credentials file
# Cryptostorm doesn't care what password you use so we use 'foo'
printf "$CRYPTOSTORM_USERNAME\nfoo" > /config/credentials
# Remove group and other permissions to remove an openvpn log warning
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

# Change all configs to use the specified port
find ovpn-configs -type f -exec sed -i "s/443/$PORT/g" {} \;

# Create /dev/net/tun
mkdir -p /dev/net
mknod /dev/net/tun c 10 200
chmod 600 /dev/net/tun

# Set up firewall to block all traffic except VPN, DNS and ICMP (ping)
# Note: if you run the VPN on 443 or 80 TCP, HTTP or HTTPS traffic may
#       be able to leak through the firewall if specifically directed to eth0
iptables -A OUTPUT -o tun0 -j ACCEPT # Permit everything from tun0
iptables -A OUTPUT -o eth0 -p icmp -j ACCEPT # Permit all ICMP from eth0
iptables -A OUTPUT -d 192.168.0.0/16 -o eth0 -j ACCEPT # Permit all to LAN from eth0
iptables -A OUTPUT -d 172.16.0.0/12 -o eth0 -j ACCEPT # Permit all to LAN from eth0
iptables -A OUTPUT -d 10.0.0.0/8 -o eth0 -j ACCEPT # Permit all to LAN from eth0

# Permit elected UDP port if UDP config file is elected, else permit elected TCP port
if [[ $CRYPTOSTORM_CONFIG_FILE =~ "udp.ovpn" ]]; then
    iptables -A OUTPUT -o eth0 -p udp -m udp --dport $PORT -j ACCEPT #permit VPN traffic out of eth0
else
    iptables -A OUTPUT -o eth0 -p tcp -m tcp --dport $PORT -j ACCEPT #permit VPN traffic out of eth0
fi

iptables -A OUTPUT -o eth0 -p udp -m udp --dport 53 -j ACCEPT # Permit UDP DNS from eth0 
iptables -A OUTPUT -o eth0 -p tcp -m tcp --dport 53 -j ACCEPT # Permit TCP DNS from eth0 
iptables -A OUTPUT -o eth0 -j DROP # Drop everything else

# Start openvpn (requires NET_ADMIN)
openvpn --client --auth-user-pass /config/credentials --config /ovpn-configs/$CRYPTOSTORM_CONFIG_FILE
