#!/usr/bin/env bash


# Check that $PORT is set and it is a number less than 65536
case $CONNECTION_PORT in
    ''|*[!0-9]*)
        echo "Specified connection port $CONNECTION_PORT is not a number, exiting"
        exit 1
        ;;
    *) ;;
esac

if [ "$CONNECTION_PORT" -gt "65535" ]; then
    echo "Specified connection port $CONNECTION_PORT is greater than the maximum (65535), exiting"
    exit 2
fi


case $FORWARDING_PORT in
    ''|*[!0-9]*)
        echo "Specified forwarding port $FORWARDING_PORT is not a number, exiting"
        exit 1
        ;;
    *) ;;
esac


if [[ "$FORWARDING_PORT" != "0" ]] ; then
    if [[ "$FORWARDING_PORT" -lt "30000" || "$FORWARDING_PORT" -gt "65535" ]] ; then
        echo "Specified forwarding port $FORWARDING_PORT is outside the allowed range of 30000-65535, exiting"
        exit 3
    fi
fi


initial_ip=$(curl -s api.ipify.org)

# Start the VPN in the background
/start-vpn.sh &

echo "KILLSWITCH: captured initial IP ($initial_ip), now sleeping for $KILLSWITCH_ACTIVATION_TIME seconds."

sleep $KILLSWITCH_ACTIVATION_TIME

if [[ "$FORWARDING_PORT" != "0" ]] ; then
    echo "FORWARDING: Attempting port forwarding for port $FORWARDING_PORT"
    curl -X POST -s -d port="$FORWARDING_PORT" http://10.31.33.7/fwd
fi

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

