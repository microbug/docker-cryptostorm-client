# Cryptostorm OpenVPN client (unofficial)
*This is not an official Cryptostorm client, it just supports Cryptostorm.*

## What does this do?
This alpine-based container contains the [Cryptostorm .ovpn configuration files](https://github.com/cryptostorm/cryptostorm_client_configuration_files). Give it a username and (optionally) specify which config file to use, and it will connect to Cryptostorm. You can then connect other containers to it via `--net=container:vpn_container_name` or through [docker-compose](https://docs.docker.com/compose/compose-file/#network_mode).

## What you need to know
- This has a built in firewall running iptables and based off [this gist](https://gist.github.com/superjamie/ac55b6d2c080582a3e64). It blocks all non-vpn traffic on `eth0` **except OpenVPN, DNS, ICMP and local (LAN) traffic**. This means that you can still access attached containers' services from within the network (e.g., if you're running Deluge you can still connect to the web interface). DNS *should* be forwarded over the VPN once it's up.
- Running VPN clients in Docker **requires NET_ADMIN**. So that means you need to add `--cap-add NET_ADMIN` if running through `docker run` or use the [relevant docker-compose method](https://docs.docker.com/compose/compose-file/#cap_add-cap_drop).

