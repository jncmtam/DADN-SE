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
      value: double.parse(json['value'].toString()),
      unit: json['unit'] ?? 'N/A',
    );
  }
}

// sample data stream from websocket
// {
//   'sensorId1': 'value',
//   'sensorId2': 'value',
// }

////////// User Sensor Models //////////