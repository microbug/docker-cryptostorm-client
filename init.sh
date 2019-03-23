#!/usr/bin/env bash

initial_ip=$(curl -s api.ipify.org)

# Start the VPN in the background
/start-vpn.sh &

echo "KILLSWITCH: captured initial IP ($initial_ip), now sleeping for $KILLSWITCH_ACTIVATION_TIME seconds."

sleep $KILLSWITCH_ACTIVATION_TIME

while true; do
    current_ip=$(curl -s api.ipify.org)

    if [ "$current_ip" == "$initial_ip" ]; then
        echo "KILLSWITCH: !!! current IP ($current_ip) matches initial IP! Terminating container."
        killall openvpn &
        sleep 2  # Give openvpn a little time to inform the server it is disconnecting
        exit 1
    else
        echo "KILLSWITCH: current IP ($current_ip) different from initial IP ($initial_ip). Everything is OK."
    fi

    sleep $KILLSWITCH_CHECK_INTERVAL
done

