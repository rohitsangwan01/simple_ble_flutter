class BleDevice {
  BleDevice({
    required this.address,
    required this.name,
    required this.rssi,
    this.isConnected,
  });

  final String? address;
  final String? name;
  final String? rssi;
  final bool? isConnected;

  factory BleDevice.fromJson(Map<String, dynamic> json) {
    return BleDevice(
      address: json["address"],
      name: json["name"],
      rssi: json["rssi"],
    );
  }
}
