# Contributing Guidelines

Contributions, suggestions and bug reports are welcomed.

## Style
Bash scripts (`init.sh`) should produce no warnings or errors in [shellcheck](https://github.com/koalaman/shellcheck). To shellcheck can be installed via your package manager of choice or used without installation on [shellcheck.net](https://www.shellcheck.net). I like using [SublimeLinter](http://www.sublimelinter.com/en/latest/about.html) with [SublimeLinter-shellcheck](https://github.com/SublimeLinter/SublimeLinter-shellcheck) to get feedback on-the-fly.

If you need to break a shellcheck guideline, please justify this briefly in a comment, then use `# shellcheck disable=ERRORCODE` to suppress messages. Example below:

```bash
...
# Shellcheck thinks that "udp.ovpn" is regex and throws an error
# shellcheck disable=SC2076
if [[ $CRYPTOSTORM_CONFIG_FILE =~ "udp.ovpn" ]]; then
    iptables -A OUTPUT -o eth0 -p udp -m udp --dport "$PORT" -j ACCEPT
...
```

## Builds
You can build the container locally with `docker build -t vpn_test .` (`cd` into the root directory of the project first), and run with `docker run (...) vpn_test`. Once your pull request is merged, Docker Hub will build it automatically within a few minutes. You can check the build progress [here](https://hub.docker.com/r/microbug/cryptostorm-client/builds/).

### Testing
Please make sure your pull request doesn't break things by:

- checking that the container can still connect to Cryptostorm (start it and follow the logs with `docker logs -f container_name_or_id`);
- checking that traffic is still routed through the VPN by entering the container's shell and doing `curl api.ipify.org`
    - unless you are running on port 443 or 80, doing `curl --interface eth0 api.ipify.org` should time out, if works then traffic may leak out of eth0 instead of going via the VPN
    - note that eth0 isn't blocked until after connection to the VPN, so doing `docker run microbug/cryptostorm-client sh` won't give accurate results unless you first run `init.sh`

## Forks
At the moment there isn't much need for a versioning system, but if any significant features / bugs need their own branch, [get in touch with me](https://keybase.io/microbug) and I can sort out the branch and automatic builds via the above system. The Docker Hub automatic build system is free by the way!