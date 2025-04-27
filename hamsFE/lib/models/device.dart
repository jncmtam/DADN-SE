import 'package:hamsFE/models/rule.dart';

enum DeviceStatus { off, auto, on }

enum DeviceType { refill, on_off }

////////// User Device Models //////////

class UDevice {
  final String id;
  final String name;
  DeviceStatus status;
  final DeviceType type;

  UDevice({
    required this.id,
    required this.name,
    required this.status,
    required this.type,
  });

  factory UDevice.fromJson(Map<String, dynamic> json) {
    return UDevice(
      id: json['id'], // required
      name: json['name'] ?? 'N/A',
      status: DeviceStatus.values.firstWhere(
        (e) => e.toString() == 'DeviceStatus.${json['status']}',
        orElse: () => DeviceStatus.off,
      ),
      type: DeviceType.values.firstWhere(
        (e) => e.toString() == 'DeviceType.${json['action_type']}',
        orElse: () => DeviceType.on_off,
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
  final DeviceType type;

  UDetailedDevice({
    required this.id,
    required this.name,
    required this.status,
    required this.condRules,
    required this.schedRules,
    required this.type,
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
      // schedRules: (json['schedule_rule'] as List)
      //     .map((rule) => ScheduledRule.fromJson(rule))
      //     .toList(),
      schedRules: [],
      type: DeviceType.values.firstWhere(
        (e) => e.toString() == 'DeviceType.${json['action_type']}',
        orElse: () => DeviceType.on_off,
      ),
    );
  }
}

////////// User Device Models //////////
