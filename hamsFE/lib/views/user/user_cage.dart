import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hamsFE/controllers/apis.dart';
import 'package:hamsFE/models/cage.dart';
import 'package:hamsFE/models/device.dart';
import 'package:hamsFE/views/constants.dart';
import 'package:hamsFE/views/user/user_device.dart';
import 'package:hamsFE/views/utils.dart';
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
    _channel = APIs.listenCageSensorData(widget.cageId);
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

  Future<void> _switchDeviceStatus(String deviceId, DeviceStatus status) async {
    try {
      await APIs.setDeviceStatus(deviceId, status);

      // Update the device status in the UI
      setState(() {
        final device = _cage.devices.firstWhere((d) => d.id == deviceId);
        device.status = status;
      });
    } catch (e) {
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
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Utils.displayInfo('Cage ID', _cage.id),
                  Utils.displayInfo(
                    'Status',
                    _cage.isEnabled ? 'Enabled' : 'Disabled',
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Sensors (${_cage.sensors.length})',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: lSectionTitle,
                    ),
                  ),
                  SizedBox(height: 10),
                  _buildSensorList(),
                  SizedBox(height: 20),
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
            ),
          );
        },
      ),
    );
  }

  Widget _buildSensorList() {
    return GridView.count(
      physics: NeverScrollableScrollPhysics(), // disable internal scroll
      shrinkWrap: true,
      crossAxisCount: 2,
      crossAxisSpacing: 5,
      mainAxisSpacing: 5,
      childAspectRatio: 1.6,
      children: _cage.sensors.map(_buildSensorCard).toList(),
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
        themeColor = const Color.fromARGB(255, 218, 167, 0);
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
            // icon and value
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  themeIcon.icon,
                  color: themeColor,
                  size: 30,
                ),
                Text(
                  '${sensor.value}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: themeColor,
                  ),
                ),
              ],
            ),
            // type and unit
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  sensor.type.toString().split('.').last,
                  // style: TextStyle(
                  //   fontWeight: FontWeight.bold,
                  // ),
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
    final List<String> options = ['Off', 'Auto', 'On'];
    final List<Color> selectedColors = [lOffMode, lAutoMode, lOnMode];

    return ListView.separated(
      physics: NeverScrollableScrollPhysics(), // disable internal scroll
      shrinkWrap: true,
      separatorBuilder: (context, index) => SizedBox(height: 10),
      itemCount: _cage.devices.length,
      itemBuilder: (context, index) {
        final device = _cage.devices[index];
        return ListTile(
          minTileHeight: 80,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          tileColor: lcardBackground,
          title: Text(
            device.name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: lCardTitle,
            ),
          ),
          trailing: device.type == DeviceType.refill
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        _switchDeviceStatus(device.id, DeviceStatus.on);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: lOnMode,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          "Refill",
                          style: TextStyle(color: primaryButtonContent),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (device.status == DeviceStatus.auto) {
                          _switchDeviceStatus(device.id, DeviceStatus.off);
                        } else {
                          _switchDeviceStatus(device.id, DeviceStatus.auto);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: device.status == DeviceStatus.auto
                            ? lAutoMode
                            : ldisableBackground,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          "Auto",
                          style: TextStyle(
                            color: device.status == DeviceStatus.auto
                                ? lAppBarContent
                                : lDisableText,
                          ),
                        ),
                      ),
                    )
                  ],
                )
              : Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: ldisableBackground,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(options.length, (index) {
                      final isSelected = index == device.status.index;
                      return GestureDetector(
                        onTap: () {
                          _switchDeviceStatus(
                              device.id, DeviceStatus.values[index]);
                        },
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? selectedColors[index]
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Center(
                            child: Text(
                              options[index],
                              style: TextStyle(
                                fontSize: 14,
                                color:
                                    isSelected ? lAppBarContent : lDisableText,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserDeviceScreen(
                  deviceId: device.id,
                  sensors: _cage.sensors,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
