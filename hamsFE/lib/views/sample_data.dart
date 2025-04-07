import 'package:hamsFE/models/cage.dart';
import 'package:hamsFE/models/device.dart';
import 'package:hamsFE/models/sensor.dart';

List<UCage> sampleCages = [
  UCage(
    id: '1',
    name: 'Cage 1',
    deviceCount: 5,
    isEnabled: true,
  ),
  UCage(
    id: '2',
    name: 'Cage 2',
    deviceCount: 3,
    isEnabled: false,
  ),
  UCage(
    id: '3',
    name: 'Cage 3',
    deviceCount: 8,
    isEnabled: true,
  ),
];

int sampleActiveDeviceCount = 3;

List<UDevice> sampleDevices = [
  UDevice(
    id: '1',
    name: 'Device 1',
    status: DeviceStatus.on,
  ),
  UDevice(
    id: '2',
    name: 'Device 2',
    status: DeviceStatus.off,
  ),
  UDevice(
    id: '3',
    name: 'Device 3',
    status: DeviceStatus.auto,
  ),
];

List<USensor> sampleSensors = [
  USensor(
    id: '1',
    type: SensorType.temperature,
    value: 22.5,
    unit: '°C',
  ),
  USensor(
    id: '2',
    type: SensorType.humidity,
    value: 45.0,
    unit: '%',
  ),
  USensor(
    id: '3',
    type: SensorType.light,
    value: 300.0,
    unit: 'lx',
  ),
  USensor(
    id: '4',
    type: SensorType.water,
    value: 1.5,
    unit: 'L',
  ),
];

UDetailedCage sampleDetailedCage = UDetailedCage(
  id: '1',
  name: 'Detailed Cage 1',
  deviceCount: 5,
  isEnabled: true,
  devices: sampleDevices,
  sensors: sampleSensors,
);

String sampleWebSocketUrl =
    'wss://demo.piesocket.com/v3/channel_123?api_key=VCXCEuvhGcBDP7XhiJJUDvR1e1D3eiVjgZ9VRiaV&notify_self';
