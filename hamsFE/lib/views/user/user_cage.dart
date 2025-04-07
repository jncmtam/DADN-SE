import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hamsFE/controllers/apis.dart';
import 'package:hamsFE/models/cage.dart';
import 'package:hamsFE/models/device.dart';
import 'package:hamsFE/views/constants.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:hamsFE/models/sensor.dart';

class UserCageScreen extends StatefulWidget {
  final String cageId;

  const UserCageScreen({super.key, required this.cageId});

  @override
  State<UserCageScreen> createState() => _UserCageScreenState();
}

class _UserCageScreenState extends State<UserCageScreen> {
  late WebSocketChannel _channel;
  late UDetailedCage _cage;
  late bool _isLoading;

  @override
  void initState() {
    super.initState();
    _isLoading = true;
    _channel = APIs.getCageSensorData(widget.cageId);
    _fetchData();
  }

  @override
  void dispose() {
    _channel.sink.close();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final cage = await APIs.getCageDetails(widget.cageId);
      setState(() {
        _cage = cage;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Something went wrong'),
            backgroundColor: debugStatus,
          ),
        );
      }

      debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: loadingStatus),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: lAppBarHeight,
        backgroundColor: lappBarBackground,
        centerTitle: true,
        title: Text(
          _cage.name,
          style: TextStyle(
            fontSize: lAppBarFontSize,
            fontWeight: FontWeight.bold,
            color: lAppBarTitle,
          ),
        ),
        leading: IconButton(
          color: lAppBarContent,
          icon: Icon(Icons.arrow_back_ios_rounded),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      backgroundColor: lappBackground,
      body: StreamBuilder(
        stream: _channel.stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return Center(child: Text('No data available'));
          }

          final data = jsonDecode(snapshot.data!);

          // print('Sensor data: $data');

          // set value to the sensors
          for (var sensor in _cage.sensors) {
            if (data.containsKey(sensor.id)) {
              sensor.value = double.parse(data[sensor.id].toString());
            }
          }

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sensors Data (${_cage.sensors.length})',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: lSectionTitle,
                  ),
                ),
                SizedBox(height: 10),
                _buildSensorList(),
                // SizedBox(height: 20),
                Text(
                  'Devices (${_cage.devices.length})',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: lSectionTitle,
                  ),
                ),
                SizedBox(height: 10),
                _buildDeviceList(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSensorList() {
    return Expanded(
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 5,
          mainAxisSpacing: 5,
          childAspectRatio: 1.6,
        ),
        itemCount: _cage.sensors.length,
        itemBuilder: (context, index) {
          return _buildSensorCard(_cage.sensors[index]);
        },
      ),
    );
  }

  Widget _buildSensorCard(USensor sensor) {
    late Icon themeIcon;
    late Color themeColor;
    switch (sensor.type) {
      case SensorType.temperature:
        themeColor = Colors.redAccent;
        themeIcon = Icon(Icons.thermostat, color: themeColor);
        break;
      case SensorType.humidity:
        themeColor = Colors.blueAccent;
        themeIcon = Icon(Icons.water_drop, color: themeColor);
        break;
      case SensorType.light:
        themeColor = Colors.orangeAccent;
        themeIcon = Icon(Icons.wb_sunny, color: themeColor);
        break;
      case SensorType.water:
        themeColor = Colors.blueAccent;
        themeIcon = Icon(Icons.water, color: themeColor);
        break;
    }

    return Card(
      color: lcardBackground,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  themeIcon.icon,
                  color: themeColor,
                ),
                Text(
                  '${sensor.value}',
                  style: TextStyle(
                    // fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: themeColor,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  sensor.type.toString().split('.').last,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  sensor.unit,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceList() {
    return Expanded(
      child: ListView.builder(
        itemCount: _cage.devices.length,
        itemBuilder: (context, index) {
          return _buildDeviceCard(_cage.devices[index]);
        },
      ),
    );
  }

  Widget _buildDeviceCard(UDevice device) {
    return Card(
      color: lcardBackground,
      child: ListTile(
        title: Text(
          device.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: lCardTitle,
          ),
        ),
        trailing: Icon(
          device.status == DeviceStatus.on
              ? Icons.power_settings_new
              : Icons.power_off,
          color: device.status == DeviceStatus.on ? successStatus : failStatus,
        ),
      ),
    );
  }
}
