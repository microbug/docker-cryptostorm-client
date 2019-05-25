#!/usr/bin/with-contenv bash

initial_ip=$(cat /initial-ip)

if [[ "$FORWARDING_PORT" != "0" ]] ; then
    echo "$(date) Attempting to enable port forwarding for port $FORWARDING_PORT"
    curl -X POST -s -d port="$FORWARDING_PORT" http://10.31.33.7/fwd
fi

# Killswitch
echo "KILLSWITCH: captured initial IP ($initial_ip), now sleeping for $KILLSWITCH_ACTIVATION_TIME seconds."
#sleep $KILLSWITCH_ACTIVATION_TIME

while true; do
    current_ip=$(curl -s api.ipify.org)

    if [ "$current_ip" == "$initial_ip" ]; then
        echo "$(date) !!! current IP ($current_ip) matches initial IP! Terminating container."
        killall openvpn &
        sleep 2  # Give openvpn a little time to inform the server it is disconnecting
        exit 1
    else
        echo "$(date) current IP ($current_ip) different from initial IP ($initial_ip). Everything is OK."
    fi

    sleep $KILLSWITCH_CHECK_INTERVAL
done

