#!/usr/bin/env sh

# Create credentials file
# Note: Cryptostorm doesn't care what password you use as auth is done via the username
printf "$CRYPTOSTORM_USERNAME\nfoo" > /config/credentials

# Create /dev/net/tun
mkdir -p /dev/net
mknod /dev/net/tun c 10 200
chmod 600 /dev/net/tun

# Set up firewall to block all non-vpn traffic except DNS and ICMP (ping)
# Sicne Cryptostorm runs on port 443 this won't block everything
iptables -A OUTPUT -o tun0 -m comment --comment "vpn" -j ACCEPT
iptables -A OUTPUT -o eth0 -p icmp -m comment --comment "icmp" -j ACCEPT
iptables -A OUTPUT -d 192.168.0.0/16 -o eth0 -m comment --comment "lan /16" -j ACCEPT
iptables -A OUTPUT -d 172.16.0.0/12 -o eth0 -m comment --comment "lan /12" -j ACCEPT
iptables -A OUTPUT -d 10.0.0.0/8 -o eth0 -m comment --comment "lan /8" -j ACCEPT
iptables -A OUTPUT -o eth0 -p udp -m udp --dport 443 -m comment --comment "openvpn" -j ACCEPT
iptables -A OUTPUT -o eth0 -p tcp -m tcp --dport 443 -m comment --comment "openvpn" -j ACCEPT
iptables -A OUTPUT -o eth0 -p udp -m udp --dport 53 -m comment --comment "dns" -j ACCEPT
iptables -A OUTPUT -o eth0 -p tcp -m tcp --dport 53 -m comment --comment "dns" -j ACCEPT
iptables -A OUTPUT -o eth0 -j DROP


# Start openvpn (requires cap_add=NET_ADMIN)
openvpn --client --auth-user-pass /config/credentials --config /ovpn-configs/$CRYPTOSTORM_CONFIG_FILE
