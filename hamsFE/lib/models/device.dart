enum DeviceStatus {
  on,
  off,
  auto,
}

////////// User Device Models //////////

class UDevice {
  final String id;
  final String name;
  DeviceStatus status;

  UDevice({
    required this.id,
    required this.name,
    required this.status,
  });

  factory UDevice.fromJson(Map<String, dynamic> json) {
    return UDevice(
      id: json['id'] ?? 'N/A',
      name: json['name'] ?? 'N/A',
      status: DeviceStatus.values.firstWhere(
        (e) => e.toString() == 'DeviceStatus.${json['status']}',
        orElse: () => DeviceStatus.off,
      ),
    );
  }
}

////////// User Device Models //////////