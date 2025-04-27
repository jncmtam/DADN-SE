import 'package:hamsFE/models/device.dart';
import 'package:hamsFE/models/sensor.dart';

////////// User Cage Models //////////

class UCage {
  final String id;
  final String name;
  final int deviceCount;
  bool isEnabled;

  UCage({
    required this.id,
    required this.name,
    required this.deviceCount,
    required this.isEnabled,
  });

  factory UCage.fromJson(Map<String, dynamic> json) {
    return UCage(
      id: json['id'] ?? 'N/A',
      name: json['name'] ?? 'N/A',
      deviceCount: json['num_device'] ?? -1,
      isEnabled: json['status'] == 'on' ? true : false,
    );
  }
}

class UDetailedCage {
  final String id;
  final String name;
  // final int deviceCount;
  final bool isEnabled;

  final List<UDevice> devices;
  final List<USensor> sensors;

  UDetailedCage({
    required this.id,
    required this.name,
    // required this.deviceCount,
    required this.isEnabled,
    required this.devices,
    required this.sensors,
  });

  factory UDetailedCage.fromJson(Map<String, dynamic> json) {
    return UDetailedCage(
      id: json['id'] ?? 'N/A',
      name: json['name'] ?? 'N/A',
      // deviceCount: json['num_device'] ?? -1,
      isEnabled: json['status'] == 'on' ? true : false,
      devices: (json['devices'] as List)
          .map((device) => UDevice.fromJson(device))
          .toList(),
      sensors: (json['sensors'] as List)
          .map((sensor) => USensor.fromJson(sensor))
          .toList(),
    );
  }
}

////////// User Cage Models //////////
