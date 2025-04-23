enum SensorType {
  temperature,
  humidity,
  light,
  water,
}

////////// User Sensor Models //////////

class USensor {
  final String id;
  final SensorType type;
  double value;
  final String unit;

  USensor({
    required this.id,
    required this.type,
    required this.value,
    required this.unit,
  });

  factory USensor.fromJson(Map<String, dynamic> json) {
    return USensor(
      id: json['id'] ?? 'N/A',
      type: SensorType.values.firstWhere(
        (e) => e.toString() == 'SensorType.${json['type']}',
        orElse: () => SensorType.temperature,
      ),
      value: json['value'] ?? -1.0,
      unit: json['unit'] ?? 'N/A',
    );
  }

  String getSensorName() {
    // concat first 4 char of sensor type + last 3 digits of sensorId
    final typeName = type.toString().split('.').last.substring(0, 4);
    final idSuffix = id.substring(id.length - 3);
    return '$typeName$idSuffix';
  }
}

////////// User Sensor Models //////////