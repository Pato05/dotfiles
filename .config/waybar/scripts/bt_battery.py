#!/usr/bin/python3
# i hate python :)
from time import sleep
from dbus.mainloop.glib import DBusGMainLoop
from gi.repository import GLib
import dbus
import json
import sys

DBusGMainLoop(set_as_default=True)
bus = dbus.SystemBus()

INTERVAL = 30000 # 30 seconds
UPOWER_IFACE = 'org.freedesktop.UPower'
UPOWER_PATH = '/org/freedesktop/UPower'
UPOWER_DEVICE_IFACE = UPOWER_IFACE + '.Device'

__devices_check: list[str] = []
is_loop_running = False


def start_loop():
    global is_loop_running
    get_battery_infos()
    if is_loop_running:
        return
    is_loop_running = True
    GLib.timeout_add(INTERVAL, get_battery_infos)

def get_battery_infos():
    global is_loop_running
    if not __devices_check:
        is_loop_running = False
        return False # destroy timeout in event loop
    
    device_percentages = []
    device_msgs = []
    for device in __devices_check:
        device_obj = bus.get_object(UPOWER_IFACE, device)
        device_iface = dbus.Interface(device_obj, dbus.PROPERTIES_IFACE)
    
        device_name = device_iface.Get(UPOWER_DEVICE_IFACE, 'Model')
        if not device_name:
            device_name = device_iface.Get(UPOWER_DEVICE_IFACE, 'Serial')
        
        percentage = int(device_iface.Get(UPOWER_DEVICE_IFACE, 'Percentage'))
        device_percentages.append(percentage)
        device_msgs.append(f'{device_name}: {percentage}%')
        
    print(json.dumps({
        'percentage': min(device_percentages),
        'tooltip': '\n'.join(device_msgs)
    }), flush=True)
    return True # continue running



def __device_connected(device_name, call_timeout=True):
    global __devices_check
    device_obj = bus.get_object(UPOWER_IFACE, device_name)
    native_path: str = device_obj.Get(UPOWER_DEVICE_IFACE, 'NativePath', dbus_interface=dbus.PROPERTIES_IFACE)
    if not native_path.startswith('/org/bluez'):
        # we don't care about a non-bluetooth device
        return
    __devices_check.append(device_name)
    if len(__devices_check) == 1 and call_timeout:
        start_loop()



def __device_disconnected(device_name):
    global __devices_check
    try:
        __devices_check.remove(device_name)
        if not __devices_check:
            print('', flush=True)
    except ValueError:
        pass


def main():
    upower_obj = bus.get_object(UPOWER_IFACE, UPOWER_PATH)
    devices = upower_obj.EnumerateDevices(dbus_interface=UPOWER_IFACE)
    for device in devices:
        __device_connected(device, call_timeout=False)
    if devices:
        start_loop()

    bus.add_signal_receiver(__device_connected, bus_name='org.freedesktop.UPower',
                            signal_name='DeviceAdded')
    bus.add_signal_receiver(__device_disconnected, bus_name='org.freedesktop.UPower',
                        signal_name='DeviceRemoved')
    loop = GLib.MainLoop()

    loop.run()


if __name__ == '__main__':
    main()
