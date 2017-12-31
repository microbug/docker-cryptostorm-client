# Cryptostorm Docker OpenVPN client
*This is not an official Cryptostorm client, it just supports Cryptostorm.*

## What does this do?
TLDR: Connects to Cryptostorm VPN and allows you to link other containers to it.

This container has everything necessary to connect to Cryptostorm. Pass it a username and (optionally) specify which config file to use, and it will connect to Cryptostorm. You can then connect other containers to it via `--net=container:vpn_container_name` or through [docker-compose](https://docs.docker.com/compose/compose-file/#network_mode).

## Usage
`docker-compose` is recommended (for ease of use and clarity) over `docker run` but examples of both are provided.

### Sample with docker-compose
```yaml
version: '3'

services:
  vpn:
    image: microbug/cryptostorm-client
    environment:
      CRYPTOSTORM_USERNAME: your_long_sha512_hash
      CRYPTOSTORM_CONFIG_FILE: cstorm_linux-balancer_udp.ovpn
    cap_add:
      - NET_ADMIN
    dns:
      - 5.101.137.251
      - 46.165.222.246
```

### Sample with docker run
```bash
docker run --cap-add NET_ADMIN \
    --env CRYPTOSTORM_USERNAME=your_long_sha512_hash \
    --env CRYPTOSTORM_CONFIG_FILE=cstorm_linux-balancer_udp.ovpn \
    --dns 5.101.137.251 --dns 46.165.222.246 \


```

## Details
### Authentication
Cryptostorm uses a SHA512-based authentication system ([more on their website](https://cryptostorm.is)). The SHA512 hash of your token is used as the username, and the password is ignored. You must provide a valid SHA512 through `--env CRYPSTOSTORM_USERNAME=myhash` or [docker-compose](https://docs.docker.com/compose/compose-file/#environment) **and** set `CRYPTOSTORM_CONFIG_FILE` to a choice from [this list](https://github.com/cryptostorm/cryptostorm_client_configuration_files/tree/master/linux). **If you don't do this, the container won't be able to connect and will exit**.

### Firewall
The container has a built in `iptables` firewall based off [this gist](https://gist.github.com/superjamie/ac55b6d2c080582a3e64). It blocks all non-vpn traffic on `eth0` **except OpenVPN, DNS, ICMP and local (LAN) traffic**. This should prevent any external communication except to establish a VPN connection. It also means that you can still access attached containers' services from within the network (e.g., if you're running Deluge you can still connect to the web interface). DNS *should* be forwarded over the VPN once it's up.

### NET_ADMIN required
Running VPN clients in Docker **requires NET_ADMIN**. That means you need to add `--cap-add NET_ADMIN` if running through `docker run` or use the [relevant docker-compose method](https://docs.docker.com/compose/compose-file/#cap_add-cap_drop). **If you don't do this, the container won't be able to connect and will exit**.

### DNS
**You must specify at least one DNS server or the container won't be able to connect and will exit**. It is suggested that you use [Cryptostorm's deepDNS service](https://github.com/cryptostorm/cstorm_deepDNS). You should look through the [list of resolvers](https://github.com/cryptostorm/cstorm_deepDNS/blob/master/dnscrypt-resolvers.csv) and select the two that are closest (geographically) to **your chosen Cryptostorm node**, not your physical location. This is because DNS is accessed over the VPN once it has started.
