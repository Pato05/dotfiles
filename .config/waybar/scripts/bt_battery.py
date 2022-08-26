#!/usr/bin/python3
# i hate python :)
from time import sleep
import dbus
import json
import sys
# dbus-send --print-reply=literal --system --dest=org.bluez /org/bluez/hci0/dev_<MAC> org.freedesktop.DBus.Properties string:"org.bluez.Battery1" string:"Percentage"
bus = dbus.SystemBus()

INTERVAL = 30


def get_device_list(manager):
    # try to get the entire list of connected devices
    # https://raspberrypi.stackexchange.com/a/114173
    managed_objs = manager.GetManagedObjects(
        dbus_interface='org.freedesktop.DBus.ObjectManager')
    devices = []
    for path in managed_objs:
        uuids = managed_objs[path].get(
            'org.bluez.Device1', {}).get('UUIDs', [])
        # print(path, uuids)
        for uuid in uuids:
            # Service discovery UUIDs
            # https://www.bluetooth.com/specifications/assigned-numbers/service-discovery/
            # AudioSink - 0x110B - Advanced Audio Distribution Profile (A2DP)
            if uuid.startswith('0000110b'):
                connected = managed_objs[path].get(
                    'org.bluez.Device1', {}).get('Connected', False)
                if connected:
                    devices.append({
                        'name': managed_objs[path].get('org.bluez.Device1', {}).get('Name'),
                        'address': managed_objs[path].get('org.bluez.Device1', {}).get('Address')
                    })
    return devices


def get_info(devices, adapterPath='/org/bluez/hci0'):
    device_percentages = []
    device_msgs = []
    for device in devices:
        try:
            dev = bus.get_object(
                "org.bluez", f"{adapterPath}/dev_{device['address'].replace(':', '_')}")
            perc_ = dev.Get("org.bluez.Battery1", "Percentage",
                            dbus_interface='org.freedesktop.DBus.Properties')

            percentage = int(perc_)
            device_percentages.append(percentage)
            device_msgs.append(f'{device["name"]}: {percentage}%')
        except Exception as e:
            print(e)
            pass
    return device_msgs, device_percentages


def wait_for_device(manager, poll_interval=15):
    devices = []
    while len(devices) == 0:
        devices = get_device_list(manager)
        if len(devices) == 0:
            sys.stdout.write('\n')
            sys.stdout.flush()
        else:
            return devices
        sleep(poll_interval)
    return devices


def main():
    manager = bus.get_object("org.bluez", "/")
    while True:
        devices = wait_for_device(manager)
        device_msgs, device_percentages = get_info(devices)
        avg_percentage = int(sum(device_percentages) / len(device_percentages))
        sys.stdout.write(json.dumps({
            'tooltip': '\n'.join(device_msgs),
            'percentage': avg_percentage
        }) + '\n')
        sys.stdout.flush()
        sleep(INTERVAL)


if __name__ == '__main__':
    main()
