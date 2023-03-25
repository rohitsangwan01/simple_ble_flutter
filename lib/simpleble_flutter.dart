library simpleble_flutter;

import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart' as fs;
import 'package:path_provider/path_provider.dart';
import 'package:python_channel/python_channel.dart';
import 'model/ble_device.dart';

class SimpleBleFlutter {
  MethodChannel? methodChannel;
  JsonChannel? jsonChannel;

  StreamController<BleDevice> scanStreamController =
      StreamController.broadcast();

  void initialize() async {
    methodChannel = MethodChannel(name: 'methodChannel');
    jsonChannel = JsonChannel(name: "jsonChannel");
    jsonChannel?.setHandler(_channelHandler);
    methodChannel?.setHandler(_channelHandler);
    String bleServerExe = "packages/simpleble_flutter/assets/BLEServer.exe";
    File bleFile = await getFilePath(bleServerExe);
    PythonChannelPlugin.bindHost(
      name: 'host',
      debugPyPath: '..\\python\\main.py',
      releasePath: bleFile.path,
    );
    PythonChannelPlugin.bindChannel('host', methodChannel!);
    PythonChannelPlugin.bindChannel('host', jsonChannel!);
  }

  Future<File> getFilePath(String path) async {
    final byteData = await fs.rootBundle.load(path);
    final buffer = byteData.buffer;
    Directory tempDir = await getTemporaryDirectory();
    String tempPath = tempDir.path;
    var filePath = '$tempPath/belServer.exe';
    return File(filePath).writeAsBytes(
        buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
  }

  void _channelHandler(message, reply) {
    if (message["type"] == null) return;
    String type = message["type"];
    var data = message["data"];
    switch (type) {
      case "event":
        _printLog("Event: $data");
        break;
      case "scanResult":
        scanStreamController.add(BleDevice.fromJson(data));
        break;
      case "onDisconnected":
        _printLog("onDisconnected: $message");
        break;
      case "onConnected":
        _printLog("onConnected: $message");
        break;
      default:
        _printLog(message.toString());
    }
  }

  void scanDevices() async {
    try {
      await methodChannel?.invokeMethod("startScan", {"": ""});
    } catch (e) {
      _printLog(e.toString());
    }
  }

  void stopScan() async {
    try {
      await methodChannel?.invokeMethod("stopScan", {"": ""});
    } catch (e) {
      _printLog(e.toString());
    }
  }

  void connect(BleDevice device) {
    methodChannel?.invokeMethod("connect", {"address": device.address});
  }

  void disconnect(BleDevice device) {
    methodChannel?.invokeMethod("disconnect", {"address": device.address});
  }

  isConnectable(BleDevice device) => methodChannel
      ?.invokeMethod("is_connectable", {"address": device.address});

  isConnected(BleDevice device) =>
      methodChannel?.invokeMethod("isConnected", {"address": device.address});

  void _printLog(log) {
    // ignore: avoid_print
    print(log);
  }
}
