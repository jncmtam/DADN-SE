class Device {
  final String id;
  final String name;
  final String status;

  Device({
    required this.id,
    required this.name,
    required this.status,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'] as String,
      name: json['name'] as String,
      status: json['status'] as String,
    );
  }
}

class Sensor {
  final String id;
  final String type;
  final double value;
  final String unit;

  Sensor({
    required this.id,
    required this.type,
    required this.value,
    required this.unit,
  });

  factory Sensor.fromJson(Map<String, dynamic> json) {
    return Sensor(
      id: json['id'] as String,
      type: json['type'] as String,
      value: json['value'] as double,
      unit: json['unit'] as String,
    );
  }
}

class CageInit {
  final String id;
  final String name;
  int numDevice;
  String status;
  List<Device>? devices;
  List<Sensor>? sensors;

  CageInit({
    required this.id,
    required this.name,
    this.numDevice = 0,
    this.status = 'off',
    this.devices,
    this.sensors,
  });

  // Factory constructor to create a CageInit object from JSON
  factory CageInit.fromJson(Map<String, dynamic> json) {
    // For initial creation response that only includes id and name
    if (json.containsKey('message')) {
      return CageInit(
        id: json['id'] as String,
        name: json['name'] as String,
      );
    }
    
    // For regular cage data that includes all fields
    return CageInit(
      id: json['id'] as String,
      name: json['name'] as String,
      numDevice: json['num_device'] != null ? json['num_device'] as int : 0,
      status: json['status'] ?? 'off',
      devices: json['devices'] != null
          ? (json['devices'] as List).map((device) => Device.fromJson(device as Map<String, dynamic>)).toList()
          : null,
      sensors: json['sensors'] != null
          ? (json['sensors'] as List).map((sensor) => Sensor.fromJson(sensor as Map<String, dynamic>)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'num_device': numDevice,
      'status': status,
      'devices': devices?.map((device) => {
        'id': device.id,
        'name': device.name,
        'status': device.status,
      }).toList(),
      'sensors': sensors?.map((sensor) => {
        'id': sensor.id,
        'type': sensor.type,
        'value': sensor.value,
        'unit': sensor.unit,
      }).toList(),
    };
  }
}