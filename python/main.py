import asyncio
import simplepyble
from flutter_channel.host import Host
from flutter_channel.exceptions import PythonChannelMethodException
from flutter_channel.channels import MethodChannel, JsonChannel

bleAdapter = None
jsonChannel = JsonChannel("jsonChannel")
channel = MethodChannel('methodChannel')
devicesMap = {}
devicesCallbackMap = {}


def setupAdapter():
    global bleAdapter
    adapters = simplepyble.Adapter.get_adapters()
    if len(adapters) == 0:
        print("No adapters found")
        sendJsonEvent("no bluetooth adapters found")
    else:
        bleAdapter = adapters[0]
        bleAdapter.set_callback_on_scan_start(
            lambda: sendJsonEvent("scanStarted"))
        bleAdapter.set_callback_on_scan_stop(
            lambda: sendJsonEvent("scanStopped"))
        bleAdapter.set_callback_on_scan_found(
            lambda peripheral: scanCallback(peripheral))
        bleAdapter.set_callback_on_scan_updated(
            lambda peripheral: scanCallback(peripheral))


def methodChannelHandler(msg, reply):
    if msg.method == 'startScan':
        bleAdapter.scan_start()
        reply.reply(None)
    elif msg.method == 'stopScan':
        bleAdapter.scan_stop()
        reply.reply(None)
    elif msg.method == 'bleEnabled':
        reply.reply(simplepyble.Adapter.bluetooth_enabled())
    elif msg.method == 'is_connectable':
        reply.reply(is_connectable(msg.args['address']))
    elif msg.method == 'isConnected':
        connected = isConnected(msg.args['address'])
        print(connected)
        reply.reply(connected)
    elif msg.method == "connect":
        connect(msg.args["address"])
        reply.reply(None)
    elif msg.method == "disconnect":
        disconnect(msg.args["address"])
        reply.reply(None)
    else:
        raise PythonChannelMethodException(
            404, 'method not found', 'method not found')


def scanCallback(peripheral):
    try:
        jsonChannel.send({"type": "scanResult", "data":
                          {
                              "address": f"{peripheral.address()}",
                              "name": f"{peripheral.identifier()}",
                              "rssi": f"{peripheral.rssi()}",
                          }, }
                         )
        devicesMap[peripheral.address()] = peripheral
    except Exception as e:
        print(e)


def is_connectable(address):
    try:
        peripheral = devicesMap[address]
        is_connectable = peripheral.is_connectable()
        return is_connectable
    except Exception as e:
        print(e)
        return False


def isConnected(address):
    try:
        peripheral = devicesMap[address]
        is_connected = peripheral.is_connected()
        return is_connected
    except Exception as e:
        print(e)
        return False


def connect(address):
    try:
        sendJsonEvent(f"TryingToConnect {address}")
        peripheral = devicesMap[address]
        peripheral.connect()
        peripheral.set_callback_on_connected(
            lambda: onConnected(address))
        peripheral.set_callback_on_disconnected(
            lambda: onDisconnected(address))
    except Exception as e:
        print(e)
        sendJsonEvent(f"ErrorConnecting {address} : {e}")


def disconnect(address):
    try:
        peripheral = devicesMap[address]
        peripheral.disconnect()
        peripheral.set_callback_on_connected(
            lambda: onConnected(address))
        peripheral.set_callback_on_disconnected(
            lambda: onDisconnected(address))
    except Exception as e:
        print(e)


def onConnected(address):
    sendJsonEvent(f"Connected: {address}")
    jsonChannel.send({"type": "onConnected", "data": address})


def onDisconnected(address):
    sendJsonEvent(f"Disconnected: {address}")
    jsonChannel.send({"type": "onDisconnected", "data": address})


def sendJsonEvent(data):
    jsonChannel.send({"type": "event", "data": data})


if __name__ == '__main__':
    host = Host()
    channel.setHandler(methodChannelHandler)
    host.bindChannel(channel)
    host.bindChannel(jsonChannel)
    setupAdapter()
