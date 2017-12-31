# Cryptostorm Docker OpenVPN client
*This is not an official Cryptostorm client, it just supports Cryptostorm.*

## What does this do?
TLDR: Connects to Cryptostorm VPN and allows you to link other containers to it.

This container has everything necessary to connect to Cryptostorm. Pass it a username and (optionally) specify which node to use (by setting which config file to use), and it will connect to Cryptostorm. You can then connect other containers to it via `--net=container:vpn_container_name` or through [docker-compose](https://docs.docker.com/compose/compose-file/#network_mode).

## Usage
`docker-compose` is recommended (for ease of use and clarity) over `docker run` but examples of both are provided.

### Example with docker-compose
You can store the username and/or config file setting in a file and specify it with [env_file](https://docs.docker.com/compose/compose-file/#env_file), if you wish.

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

### Example with docker run
```bash
docker run -d \ 
    --cap-add NET_ADMIN \
    --env CRYPTOSTORM_USERNAME=your_long_sha512_hash \
    --env CRYPTOSTORM_CONFIG_FILE=cstorm_linux-balancer_udp.ovpn \
    --dns 5.101.137.251 --dns 46.165.222.246 \
    microbug/cryptostorm-client
```

### Checking that it works
Start the container as above. Do `docker ps` and copy the container ID. Do `docker exec -it [CONTAINER ID] sh` and run `curl api.ipify.org`. If the returned IP address is the same as that of the selected Cryptostorm node, your container is working as expected.

### Connecting other containers
With `docker run`, you can use `--net=container:vpn_container_name`. With `docker-compose` you can use `network_mode: "service:vpn_container_name"`.

This solution has been tested and works with macvlans.

## Details
### Authentication and Config Files
Cryptostorm uses a SHA512-based authentication system ([more on their website](https://cryptostorm.is)). The SHA512 hash of your token is used as the username, and the password is ignored. You must provide a valid SHA512 through `--env CRYPSTOSTORM_USERNAME=myhash` or [docker-compose](https://docs.docker.com/compose/compose-file/#environment) **and** set `CRYPTOSTORM_CONFIG_FILE` to a choice from [this list](https://github.com/cryptostorm/cryptostorm_client_configuration_files/tree/master/linux). **If you don't do this, the container won't be able to connect and will exit**.

### TCP vs UDP
Unless you know why you need TCP, you should use the UDP config files.

### Firewall
The container has a built in `iptables` firewall based off [this gist](https://gist.github.com/superjamie/ac55b6d2c080582a3e64). It blocks all non-vpn traffic on `eth0` **except OpenVPN, DNS, ICMP and local (LAN) traffic**. This should prevent any external communication except to establish a VPN connection. It also means that you can still access attached containers' services from within the network (e.g., if you're running Deluge you can still connect to the web interface). DNS *should* be forwarded over the VPN once it's up.

### NET_ADMIN required
**You must give the container NET_ADMIN or it won't be able to connect and will exit**. Running VPN clients in Docker **requires NET_ADMIN**. To give this, add `--cap-add NET_ADMIN` if running through `docker run` or use the [relevant docker-compose method](https://docs.docker.com/compose/compose-file/#cap_add-cap_drop).

### DNS
**You must specify at least one DNS server or the container won't be able to connect and will exit**. It is suggested that you use [Cryptostorm's deepDNS service](https://github.com/cryptostorm/cstorm_deepDNS). You should look through the [list of resolvers](https://github.com/cryptostorm/cstorm_deepDNS/blob/master/dnscrypt-resolvers.csv) and select the two that are closest (geographically) to **your chosen Cryptostorm node**, not your physical location. This is because DNS is accessed over the VPN once it has started.

### Timezone
Having the system clock correct is important for VPNs as the server may reject requests that have incorrect timestamps. The container uses the host's timekeeping so make sure you have NTP correctly set up on the host.

### IPv6
**[You should disable IPv6 on the host](https://twitter.com/cryptostorm_is/status/735068133308956672)**. IPv6 It isn't easily possible to do this within the container without making it privileged. There are [various](http://ask.xmodulo.com/disable-ipv6-linux.html) [guides](https://support.purevpn.com/how-to-disable-ipv6-linuxubuntu) [online](https://askubuntu.com/questions/309461/how-to-disable-ipv6-permanently) for this.
