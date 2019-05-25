#!/usr/bin/with-contenv bash

initial_ip=$(cat /initial-ip)
current_ip=initial_ip

function update_ip {
    current_ip=$(curl -s api.ipify.org)
}
export -f update_ip

if [[ "$FORWARDING_PORT" != "0" ]] ; then
    echo "$(date): FORWARDING: attempting to enable port forwarding for port $FORWARDING_PORT"
    curl -X POST -s -d port="$FORWARDING_PORT" http://10.31.33.7/fwd
fi

# Killswitch
echo "$(date): KILLSWITCH: captured initial IP ($initial_ip)"

while true; do
    # workaround for timeout command's requirement for an external process
    # see https://stackoverflow.com/questions/9954794
    timeout -t 10 bash -c update_ip
    exit_status=$?

    if [[ ! exit_status -eq 0 ]]; then
        echo "$(date): KILLSWITCH: WARNING heartbeat failed, forcing an openvpn reconnect"
        killall openvpn
        exit 1
    fi

    if [ "$current_ip" == "$initial_ip" ]; then
        echo "$(date): KILLSWITCH: WARNING current IP ($current_ip) matches initial IP! Terminating container."
        killall openvpn
        exit 2
    else
        echo "$(date): KILLSWITCH: everything ok, current IP ($current_ip) different from initial IP ($initial_ip)"
    fi

    sleep $KILLSWITCH_CHECK_INTERVAL
done

