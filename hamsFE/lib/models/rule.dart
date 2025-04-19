import 'package:flutter/material.dart';
import 'package:hamsFE/models/sensor.dart';

abstract class AutomationRule {
  final String id;
  ActionType action;

  AutomationRule({
    required this.id,
    required this.action,
  });

  String toRuleString();
}

enum ConditionalOperator {
  equals,
  // notEquals,
  greaterThan,
  lessThan,
  // greaterThanOrEquals,
  // lessThanOrEquals,
}

String conditionalOperatorToString(ConditionalOperator operator) {
  switch (operator) {
    case ConditionalOperator.equals:
      return '=';
    case ConditionalOperator.greaterThan:
      return '>';
    case ConditionalOperator.lessThan:
      return '<';
  }
}

ConditionalOperator stringToConditionalOperator(String operator) {
  switch (operator) {
    case '=':
      return ConditionalOperator.equals;
    case '>':
      return ConditionalOperator.greaterThan;
    case '<':
      return ConditionalOperator.lessThan;
    default:
      return ConditionalOperator.equals;
  }
}

enum ActionType { on, off, refill }

String actionTypeToString(ActionType action) {
  switch (action) {
    case ActionType.on:
      return 'Turn on';
    case ActionType.off:
      return 'Turn off';
    case ActionType.refill:
      return 'Refill';
  }
}

class ConditionalRule extends AutomationRule {
  // final String name;
  final String sensorId;
  final SensorType sensorType;
  ConditionalOperator operator;
  double threshold;
  final String unit;

  ConditionalRule({
    required super.id,
    required this.sensorId,
    required this.sensorType,
    required this.operator,
    required this.threshold,
    required this.unit,
    required super.action,
  });

  factory ConditionalRule.fromJson(Map<String, dynamic> json) {
    return ConditionalRule(
      id: json['id'], // required
      sensorId: json['sensor_id'] ?? 'N/A',
      sensorType: SensorType.values.firstWhere(
        (e) => e.toString() == 'SensorType.${json['sensor_type']}',
        orElse: () => SensorType.temperature,
      ),
      operator: stringToConditionalOperator(json['condition']),
      threshold: json['threshold']?.toDouble() ?? -1.0,
      unit: json['unit'] ?? 'N/A',
      action: ActionType.values.firstWhere(
        (e) => e.toString() == 'ActionType.${json['action']}',
        orElse: () => ActionType.off,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sensor_id': sensorId,
      'condition': conditionalOperatorToString(operator),
      'threshold': threshold,
      // 'unit': unit,
      'action': action.toString().split('.').last,
    };
  }

  @override
  String toRuleString() {
    // temperature > 30 C => ON
    final sensor = USensor(
      id: sensorId,
      type: sensorType,
      value: 0,
      unit: unit,
    );
    final name = sensor.getSensorName();
    final op = conditionalOperatorToString(operator);
    final value = threshold.toStringAsFixed(1);
    final action = this.action.toString().split('.').last.toUpperCase();
    return '$name $op $value $unit => $action';
  }
}

enum DayOfWeek { sun, mon, tue, wed, thu, fri, sat }

class ScheduledRule extends AutomationRule {
  // final String name;
  List<DayOfWeek> days;
  TimeOfDay time;

  ScheduledRule({
    required super.id,
    required this.days,
    required this.time,
    required super.action,
  });

  factory ScheduledRule.fromJson(Map<String, dynamic> json) {
    return ScheduledRule(
      id: json['id'], // required
      days: (json['days'] as List)
          .map((day) => DayOfWeek.values.firstWhere(
                (e) => e.toString() == 'DayOfWeek.$day',
                orElse: () => DayOfWeek.sun,
              ))
          .toList(),
      time: TimeOfDay(
        hour: int.parse(json['execution_time'].split(':')[0]),
        minute: int.parse(json['execution_time'].split(':')[1]),
      ),
      action: ActionType.values.firstWhere(
        (e) => e.toString() == 'ActionType.${json['action']}',
        orElse: () => ActionType.off,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'days': days.map((day) => day.toString().split('.').last).toList(),
      'execution_time': time,
      'action': action.toString().split('.').last,
    };
  }

  @override
  String toRuleString() {
    // 08:00 mon,tue => ON
    final timeStr =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    final daysStr = days.map((day) => day.toString().split('.').last).join(',');
    final actionStr = action.toString().split('.').last.toUpperCase();
    return '$timeStr $daysStr => $actionStr';
  }
}
