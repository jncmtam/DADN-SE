import 'package:flutter/material.dart';
import 'package:hamsFE/models/cage.dart';
import 'package:hamsFE/models/device.dart';
import 'package:hamsFE/models/rule.dart';
import 'package:hamsFE/models/sensor.dart';

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
  deviceCount: 5,
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
