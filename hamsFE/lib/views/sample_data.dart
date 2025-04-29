import 'package:flutter/material.dart';
import 'package:hamsFE/models/cage.dart';
import 'package:hamsFE/models/device.dart';
import 'package:hamsFE/models/noti.dart';
import 'package:hamsFE/models/rule.dart';
import 'package:hamsFE/models/sensor.dart';
import 'package:hamsFE/models/chartdata.dart';

List<UCage> sampleCages = [
  UCage(
    id: '5ca7747f-2e0d-4eb5-9b62-3d17e9a77c2b',
    name: 'Cage 1',
    deviceCount: 5,
    isEnabled: true,
  ),
  UCage(
    id: '5ca7747f-2e0d-4eb5-9b62-3d17e9a77c23',
    name: 'Cage 2',
    deviceCount: 3,
    isEnabled: false,
  ),
  UCage(
    id: '5ca7747f-2e0d-4eb5-9b62-3d17e9a77c25',
    name: 'Cage 3',
    deviceCount: 8,
    isEnabled: true,
  ),
];

int sampleActiveDeviceCount = 3;

List<UDevice> sampleDevices = [
  UDevice(
    id: '5ca7747f-2e0d-4eb5-9b62-3d17e9a77c43',
    name: 'Device 1',
    status: DeviceStatus.on,
    type: DeviceType.on_off,
  ),
  UDevice(
    id: '5ca7747f-2e0d-4eb5-9b62-3d17e9a77ce3',
    name: 'Device 2',
    status: DeviceStatus.off,
    type: DeviceType.refill,
  ),
  UDevice(
    id: '5ca7747f-2e0d-4eb5-9b62-3d17e9a773f4',
    name: 'Device 3',
    status: DeviceStatus.auto,
    type: DeviceType.on_off,
  ),
];

List<USensor> sampleSensors = [
  USensor(
    id: '5ca7747f-2e0d-4eb5-9b62-3d17e9a77c34',
    type: SensorType.temperature,
    value: 22.5,
    unit: '°C',
  ),
  USensor(
    id: '5ca7747f-2e0d-4eb5-9b62-3d17e9a77c32',
    type: SensorType.humidity,
    value: 45.0,
    unit: '%',
  ),
  USensor(
    id: '5ca7747f-2e0d-4eb5-9b62-3d17e9a7732b',
    type: SensorType.light,
    value: 300.0,
    unit: 'lux',
  ),
  USensor(
    id: '5ca7747f-2e0d-4eb5-9b62-3d17e9457c2b',
    type: SensorType.water,
    value: 1.5,
    unit: 'L',
  ),
];

UDetailedCage sampleDetailedCage = UDetailedCage(
  id: '5ca7747f-2e0d-4eb5-9b62-3d17e937332b',
  name: 'Cage 1',
  // deviceCount: 5,
  isEnabled: true,
  devices: sampleDevices,
  sensors: sampleSensors,
);

String sampleWebSocketUrl =
    'wss://demo.piesocket.com/v3/channel_123?api_key=VCXCEuvhGcBDP7XhiJJUDvR1e1D3eiVjgZ9VRiaV&notify_self';

UDetailedDevice sampleDetailedDevice = UDetailedDevice(
  id: '3d142e2a-8d48-4bc8-8ff1-eadf2a9211bf',
  name: 'Device 1',
  status: DeviceStatus.on,
  type: DeviceType.on_off,
  condRules: [
    ConditionalRule(
      id: '5ca7747f-2e0d-4eb5-9b62-3d17e9a77c2b',
      sensorId: '5ca7747f-2e0d-4eb5-9b62-3d17e9a77c2b',
      sensorType: SensorType.temperature,
      operator: ConditionalOperator.greaterThan,
      threshold: 25.0,
      unit: '°C',
      action: ActionType.turn_on,
    ),
  ],
  schedRules: [
    ScheduledRule(
      id: '5ca7747f-2e0d-4eb5-9b62-3d17e9a77c2b',
      days: [DayOfWeek.mon, DayOfWeek.tue],
      time: TimeOfDay(hour: 8, minute: 0),
      action: ActionType.turn_off,
    ),
  ],
);

List<MyNotification> sampleNotifications = [
  MyNotification(
    id: '1',
    title: 'Device 1: Fan turned on',
    type: NotificationType.info,
    timestamp: DateTime.now(),
    read: false,
  ),
  MyNotification(
    id: '2',
    title: 'Device 2: Temperature is high',
    type: NotificationType.warning,
    timestamp: DateTime.now().subtract(const Duration(hours: 1)),
    read: false,
  ),
  MyNotification(
    id: '3',
    title: 'Device 3: Failed to open light',
    type: NotificationType.error,
    timestamp: DateTime.now().subtract(const Duration(days: 1)),
    read: true,
  ),
  MyNotification(
    id: '4',
    title: 'Device 4: Light turned off',
    type: NotificationType.info,
    timestamp: DateTime.now().subtract(const Duration(days: 2)),
    read: false,
  ),
];

ChartResponse sampleChartResponse = ChartResponse.fromJson({
      "statistics": [
        {"day": "2025-04-28", "value": 35}, // Monday (this week)
        {"day": "2025-04-29", "value": 28}, // Tuesday
        {"day": "2025-04-30", "value": 34}, // Wednesday
        {"day": "2025-05-01", "value": 32}, // Thursday
        {"day": "2025-05-02", "value": 40}, // Friday
        {"day": "2025-05-03", "value": 25}, // Saturday
        {"day": "2025-05-04", "value": 30}, // Sunday
      ],
      "summary": {
        "average": 32.0,
        "highest": 40.0,
        "lowest": 25.0
      }
});
