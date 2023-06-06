#!/bin/bash
signal=

check() {
    # check if any kind of wireguard connection is active in NetworkManager
    if nmcli connection show --active | grep -q "wireguard"; then
        echo '{"percentage":100,"class":"active"}'
        signal="DeviceRemoved"
    else
        echo '{"percentage":0}'
        signal="DeviceAdded"
    fi
}

while true; do
    check
    # wait until next signal, then repeat.
    # it's a dirty approach, but probably the best one to get the job done
    
    dbus-monitor --system "type='signal',sender='org.freedesktop.NetworkManager',member='${signal}'" 2>/dev/null | \
    while read -r line; do
        echo "$line" | grep "$signal" && \
            break
    done
done
