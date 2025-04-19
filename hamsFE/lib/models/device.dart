import 'package:hamsFE/models/rule.dart';

enum DeviceStatus { off, auto, on }

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
      id: json['id'], // required
      name: json['name'] ?? 'N/A',
      status: DeviceStatus.values.firstWhere(
        (e) => e.toString() == 'DeviceStatus.${json['status']}',
        orElse: () => DeviceStatus.off,
      ),
    );
  }
}

class UDetailedDevice {
  final String id;
  final String name;
  DeviceStatus status;
  List<ConditionalRule> condRules;
  List<ScheduledRule> schedRules;

  UDetailedDevice({
    required this.id,
    required this.name,
    required this.status,
    required this.condRules,
    required this.schedRules,
  });

  factory UDetailedDevice.fromJson(Map<String, dynamic> json) {
    return UDetailedDevice(
      id: json['id'], // required
      name: json['name'] ?? 'N/A',
      status: DeviceStatus.values.firstWhere(
        (e) => e.toString() == 'DeviceStatus.${json['status']}',
        orElse: () => DeviceStatus.off,
      ),
      condRules: (json['automation_rule'] as List)
          .map((rule) => ConditionalRule.fromJson(rule))
          .toList(),
      schedRules: (json['schedule_rule'] as List)
          .map((rule) => ScheduledRule.fromJson(rule))
          .toList(),
    );
  }
}

////////// User Device Models //////////