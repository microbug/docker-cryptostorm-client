# Cryptostorm Docker OpenVPN client
*This is not an official Cryptostorm client, it just supports Cryptostorm.*

## What does this do?
Connects to Cryptostorm VPN and allows you to link other containers to it. Image name: `microbug/cryptostorm-client`.

This image is designed to work with Cryptostorm's VPN service. Pass it a username and (optionally) specify which node to use (by setting which config file to use), and it will connect to Cryptostorm. You can then connect other containers to it via `--net=container:vpn_container_name` or through [docker-compose](https://docs.docker.com/compose/compose-file/#network_mode).

Since it's based on Alpine, the image is very lightweight at around [6MB compressed](https://hub.docker.com/r/microbug/cryptostorm-client/tags/).

If you don't have a Cryptostorm token, you can purchase them [here](https://cryptostorm.is). Note that different tokens have different numbers of maximum simultaneous connections; if you want to use the VPN on your phone/computer and in the container at the same time you'll [need to buy a 3 month or longer token](https://twitter.com/cryptostorm_is/status/852223442279579648).

## Usage
### Example with docker-compose, linking Deluge
For additional security you can store the username in a separate secrets file and specify it with [env_file](https://docs.docker.com/compose/compose-file/#env_file). Excluding the secrets file in your .gitignore allows you to push your config to a public repository without worrying about someone stealing your credentials.

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
Start the container as above. Run `docker ps` and copy the container ID. Run `docker logs -f [CONTAINER ID]` to inspect the logs and check if it's working. Wait `$KILLSWITCH_ACTIVATION_TIME` (30s by default) and you should see the killswitch script check the current IP against the initial (pre-VPN) IP.

### Connecting other containers
With `docker run`, you can use `--net=container:vpn_container_name`. With `docker-compose` you can use `network_mode: "service:vpn_container_name"`.

This works with [macvlan networks](https://docs.docker.com/engine/userguide/networking/get-started-macvlan/), which allow you to give your container its own IP address on your LAN.

### IPv6
#### **[You should disable IPv6 on the host](https://twitter.com/cryptostorm_is/status/735068133308956672)**.
It's not possible to do this within the container without making it privileged. There are [various (1)](http://ask.xmodulo.com/disable-ipv6-linux.html) [guides (2)](https://support.purevpn.com/how-to-disable-ipv6-linuxubuntu) [online (3)](https://askubuntu.com/questions/309461/how-to-disable-ipv6-permanently) for this.

## Details
### Environment variables
All environment variables:

- `CRYPTOSTORM_USERNAME`: the sha512 hash of your token
- `CRYPTOSTORM_CONFIG_FILE`: the name of the config file you want to use. There
  is a list of filenames [here](https://github.com/cryptostorm/cryptostorm_client_configuration_files/tree/master/ecc).
- `CONNECTION_PORT`: the port that OpenVPN will connect over. Defaults to 1194. Can be
  1-65535.
- `FORWARDING_PORT`: after the VPN is connected, this port will be requested to
  be forwarded to the container. Note that this does not guarantee success as
  the port may be unavailable.
- `KILLSWITCH_ACTIVATION_TIME`: the time to wait for OpenVPN to start before
  checking that the VPN's IP is presented to internet services. Defaults to 30s.
- `KILLSWITCH_CHECK_INTERVAL`: the time to wait between each killswitch check.
  Defaults to 5s.

### NET_ADMIN required
**You must give the image NET_ADMIN or it won't be able to connect and will exit**. Running VPN clients in Docker **requires NET_ADMIN**. To give this, add `--cap-add NET_ADMIN` if running through `docker run` or use the [relevant docker-compose method](https://docs.docker.com/compose/compose-file/#cap_add-cap_drop).

### Authentication and Config Files
Cryptostorm uses a SHA512-based authentication system. The SHA512 hash of your token is used as the username, and the password is ignored. You must provide a valid SHA512 through `--env CRYPSTOSTORM_USERNAME=your_long_sha512_hash` or [docker-compose](https://docs.docker.com/compose/compose-file/#environment). **If you don't do this, the container won't be able to connect and will exit**.

It is recommended to set `CRYPTOSTORM_CONFIG_FILE` to a choice from [this list](https://github.com/cryptostorm/cryptostorm_client_configuration_files/tree/master/ecc). If you don't do this the container will connect to a randomly chosen Cryptostorm node, which could decrease performance if that node is far away from you.

### Killswitch
The first file that runs in the container is `/init.sh`. This starts the VPN in
the background and sleeps

### Port forwarding
Cryptostorm [supports port forwarding](https://cryptostorm.is/portfwd) for ports between 30000 and 65535
(inclusive). To request a port to be forwarded, set the `FORWARDING_PORT`
environment variable to the port number you want to forward to the container.
Make sure you check the logs as this can fail if someone else is already using
the port.

### TCP vs UDP
Unless you know why you need TCP, you should use the UDP config files.

### Ports
Cryptostorm [supports port striping](https://cryptostorm.org/viewtopic.php?f=37&t=6034&p=8125&hilit=port+striping#p8125), so **you can connect to the VPN via any port**. By default port 1194 is used, you can change this by specifying `--env CONNECTION_PORT=your_port` or adding `CONNECTION_PORT: your_port` under `environment:` in docker-compose.

If your ISP/firewall blocks port 1194 (quite common), you should try port 80 or port 443. To change the port, set the environment variable `CONNECTION_PORT` to the port number you want to use (1-65535).

### Firewall
The image used to have a firewall, but eth0 appears to be blocked once the VPN
is running so this was removed. You can test this yourself by entering the
container and running `curl --interface eth0 api.ipify.org` (this should fail).
Compare this to `curl --interface tun0 api.ipify.org`. This should work,
indicating that traffic can only pass over tun0.


### DNS
Your network's default DNS will be used to look up the Cryptostorm node. Once
the VPN is connected, the Cryptostorm DNS resolver will be used (10.31.33.8 from
within the Cryptostorm network).

### Timezone
Having the system clock correct is important for VPNs as the server may reject requests that have incorrect timestamps. The container uses the host's timekeeping so make sure you have NTP correctly set up on the host.

## Contributing
Contributions, suggestions and bug reports are welcomed. Full guidelines are in `CONTRIBUTING.md`.

## License
The contents of this repository (except `update-resolv-conf`) are licensed under the MIT license, which can be found in the LICENSE file. `update-resolv-conf` is licensed under the GPL license, which can be found online.
