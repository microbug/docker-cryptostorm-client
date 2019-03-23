# Cryptostorm Docker OpenVPN client
*This is not an official Cryptostorm client, it just supports Cryptostorm.*

## What does this do?
Connects to Cryptostorm VPN and allows you to link other containers to it. Image name: `microbug/cryptstorm-client`.

This image is designed to work with Cryptostorm's VPN service. Pass it a username and (optionally) specify which node to use (by setting which config file to use), and it will connect to Cryptostorm. You can then connect other containers to it via `--net=container:vpn_container_name` or through [docker-compose](https://docs.docker.com/compose/compose-file/#network_mode).

Since it's based on Alpine, the image is very lightweight at around [5MB compressed](https://hub.docker.com/r/microbug/cryptostorm-client/tags/).

If you don't have a Cryptostorm token, you can purchase them [here](https://cryptostorm.is). You can purchase a 1 week token for $1 (at the time of writing) so it's cheap to try out. Note that different token lengths have different numbers of maximum simultaneous connections; if you want to use the VPN on your phone/computer and in the container at the same time you'll [need to buy a 3 month or longer token](https://twitter.com/cryptostorm_is/status/852223442279579648).

## Usage
`docker-compose` is recommended (for ease of use and clarity) over `docker run` but examples of both are provided.

### Example with docker-compose, linking Deluge
You can store the username and/or config file setting in a file and specify it with [env_file](https://docs.docker.com/compose/compose-file/#env_file), if you wish.

```yaml
version: '3'

services:
  vpn:
    image: microbug/cryptostorm-client:latest
    environment:
      CRYPTOSTORM_USERNAME: your_long_sha512_hash
      CRYPTOSTORM_CONFIG_FILE: Balancer_UDP.ovpn
    cap_add:
      - NET_ADMIN

  deluge:
    image: linuxserver/deluge:latest
    depends-on:
      - vpn
    environment:
      TZ: Europe/London
      PGID: 1000
      PUID: 1000
    network_mode: "service:vpn"
    volumes:
      - /your/config/folder:/config:rw
      - /your/downloads/folder:/downloads:rw
```

### Example with docker run, linking Deluge
```bash
docker run -d \ 
    --cap-add NET_ADMIN \
    --env CRYPTOSTORM_USERNAME=your_long_sha512_hash \
    --env CRYPTOSTORM_CONFIG_FILE=Balancer_UDP.ovpn \
    --name vpn \
    microbug/cryptostorm-client:latest

docker run -d \
    --env TZ=Europe/London --env PGID=1000 --env PUID=1000 \
    --net container:vpn \
    -v /your/config/folder:/config:rw \
    -v /your/downloads/folder:/downloads:rw \
    linuxserver/deluge:latest
```

### Checking that it works
Start the container as above. Do `docker ps` and copy the container ID. Do `docker exec -it [CONTAINER ID] sh` and run `curl api.ipify.org`. If the returned IP address is the same as that of the selected Cryptostorm node, your container is working as expected.

### Connecting other containers
With `docker run`, you can use `--net=container:vpn_container_name`. With `docker-compose` you can use `network_mode: "service:vpn_container_name"`.

This solution has been tested and works with [macvlan networks](https://docs.docker.com/engine/userguide/networking/get-started-macvlan/).

### IPv6
#### **[You should disable IPv6 on the host](https://twitter.com/cryptostorm_is/status/735068133308956672)**.
It's not possible to do this within the container without making it privileged. There are [various](http://ask.xmodulo.com/disable-ipv6-linux.html) [guides](https://support.purevpn.com/how-to-disable-ipv6-linuxubuntu) [online](https://askubuntu.com/questions/309461/how-to-disable-ipv6-permanently) for this.

## Details
### Authentication and Config Files
Cryptostorm uses a SHA512-based authentication system ([more on their website](https://cryptostorm.is)). The SHA512 hash of your token is used as the username, and the password is ignored. You must provide a valid SHA512 through `--env CRYPSTOSTORM_USERNAME=your_long_sha512_hash` or [docker-compose](https://docs.docker.com/compose/compose-file/#environment) **and** set `CRYPTOSTORM_CONFIG_FILE` to a choice from [this list](https://github.com/cryptostorm/cryptostorm_client_configuration_files/tree/master/linux). **If you don't do this, the container won't be able to connect and will exit**.

### TCP vs UDP
Unless you know why you need TCP, you should use the UDP config files.

### Ports
Cryptostorm [supports port striping](https://cryptostorm.org/viewtopic.php?f=37&t=6034&p=8125&hilit=port+striping#p8125), so **you can connect to the VPN via any port**. By default port 1194 is used, you can change this by specifying `--env PORT=your_port` or adding `PORT: your_port` under `environment:` in docker-compose.

If your ISP/firewall blocks port 1194, you should try port 80 or port 443. These are not used by default as the container's firewall allows non-VPN traffic using the chosen port, and allowing ports 80 or 443 could allow traffic to leak through the firewall without passing through the VPN.

### Firewall
The image has a built in `iptables` firewall based off [this gist](https://gist.github.com/superjamie/ac55b6d2c080582a3e64). It blocks all non-vpn traffic on `eth0` **except OpenVPN, DNS, ICMP and local (LAN) traffic**. This should prevent any external communication except to establish a VPN connection. It also means that you can still access attached containers' services from within the network (e.g., if you're running Deluge you can still connect to the web interface). DNS *should* be forwarded over the VPN once it's up.

### NET_ADMIN required
**You must give the image NET_ADMIN or it won't be able to connect and will exit**. Running VPN clients in Docker **requires NET_ADMIN**. To give this, add `--cap-add NET_ADMIN` if running through `docker run` or use the [relevant docker-compose method](https://docs.docker.com/compose/compose-file/#cap_add-cap_drop).

### DNS
**You must specify at least one DNS server or the container won't be able to connect and will exit**. It is suggested that you use [Cryptostorm's deepDNS service](https://github.com/cryptostorm/cstorm_deepDNS). You should look through the [list of resolvers](https://github.com/cryptostorm/cstorm_deepDNS/blob/master/dnscrypt-resolvers.csv) and select the two that are closest (geographically) to **your chosen Cryptostorm node**, not your physical location. This is because DNS is accessed over the VPN once it has started.

### Timezone
Having the system clock correct is important for VPNs as the server may reject requests that have incorrect timestamps. The container uses the host's timekeeping so make sure you have NTP correctly set up on the host.

## Contributing
Contributions, suggestions and bug reports are welcomed. Full guidelines are in `CONTRIBUTING.md`.

## License
The contents of this repository are licensed under the MIT license, which can be found in the LICENSE file.
