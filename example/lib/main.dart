import 'package:flutter/material.dart';
import 'package:simpleble_flutter/model/ble_device.dart';
import 'package:simpleble_flutter/simpleble_flutter.dart';

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  SimpleBleFlutter simpleBleFlutter = SimpleBleFlutter();
  List<BleDevice> devices = [];

  @override
  void initState() {
    simpleBleFlutter.initialize();
    simpleBleFlutter.scanStreamController.stream.listen((event) {
      if (!devices.any((element) => element.address == event.address)) {
        setState(() {
          devices.add(event);
        });
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("SimpleBle flutter"),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                      onPressed: () {
                        simpleBleFlutter.scanDevices();
                      },
                      child: const Text("Start Scan")),
                  ElevatedButton(
                      onPressed: () {
                        simpleBleFlutter.stopScan();
                      },
                      child: const Text("Stop Scan"))
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: devices.length,
                itemBuilder: (BuildContext context, int index) {
                  BleDevice device = devices[index];
                  return BleDeviceWidget(
                    device: device,
                    onTap: () {
                      simpleBleFlutter.connect(device);
                    },
                  );
                },
              ),
            )
          ],
        ));
  }
}

class BleDeviceWidget extends StatelessWidget {
  final BleDevice device;
  final VoidCallback? onTap;
  const BleDeviceWidget({super.key, required this.device, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Text(device.name ?? "NA"),
      subtitle: Text(device.address ?? "Na"),
      trailing: Text(device.rssi?.toString() ?? ""),
      onTap: onTap,
    );
  }
}
