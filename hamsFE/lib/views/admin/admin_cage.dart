import 'package:flutter/material.dart';
import 'package:hamsFE/models/cageinit.dart';
import 'package:hamsFE/views/constants.dart';
import '../../controllers/apis.dart';
import 'package:hamsFE/models/device.dart';
import 'package:hamsFE/models/sensor.dart';

class AdminCage extends StatefulWidget {
  final CageInit? cageInit;
  final String userId;

  const AdminCage({super.key, required this.cageInit, required this.userId});

  @override
  _AdminCageState createState() => _AdminCageState();
}

class _AdminCageState extends State<AdminCage> {
  CageInit? cage;
  CageInit? cageDetails;
  bool isLoading = true;
  bool showDevices = true; // Toggle between devices and sensors view

  @override
  void initState() {
    super.initState();
    if (widget.cageInit == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAddCageDialog();
      });
    } else {
      cage = widget.cageInit;
      _loadCageDetails();
    }
  }

  Future<void> _loadCageDetails() async {
    if (cage == null) return;

    try {
      final details = await APIs.adminGetCageDetails(cage!.id);
      // Assuming details cannot be null, directly proceed
      if (!mounted) return; // Add mounted check
      setState(() {
        cageDetails = details;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return; // Add mounted check
      setState(() {
        isLoading = false;
        // Don't set cageDetails to null, keep the previous value if any
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to load cage details: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddCageDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String cageName = "";
        return AlertDialog(
          backgroundColor: Color(0xFFF5D7A1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Center(
            child: Text(
              "Name of cage",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          content: TextField(
            onChanged: (value) {
              cageName = value;
            },
            decoration: InputDecoration(
              hintText: "Enter the name for cage",
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () async {
                if (cageName.isNotEmpty) {
                  try {
                    final newCage = await APIs.createCage(cageName, widget.userId);
                    if (!mounted) return; // Add mounted check
                    setState(() {
                      cage = newCage;
                    });
                    await _loadCageDetails(); // Load cage details immediately
                    if (!mounted) return; // Add mounted check
                    Navigator.of(context).pop(true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Cage added successfully"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return; // Add mounted check
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Failed to add cage: $e"),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2C5D51),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: Text(
                "Save",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFB22222),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: Text(
                "Cancel",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    ).then((value) {
      if (value != true) {
        Navigator.pop(context, false);
      }
    });
  }

  void _showAddDeviceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String deviceName = '';
        List<UDevice>? availableDevices;
        bool isLoadingDevices = true;

        return StatefulBuilder(
          builder: (context, setState) {
            // Fetch available devices when dialog opens
            if (isLoadingDevices) {
              APIs.getAvailableDevice().then((devices) {
                if (!mounted) return; // Add mounted check
                setState(() {
                  availableDevices = devices;
                  isLoadingDevices = false;
                });
              }).catchError((error) {
                if (!mounted) return; // Add mounted check
                setState(() {
                  availableDevices = [];
                  isLoadingDevices = false;
                });
              });
            }

            return AlertDialog(
              backgroundColor: Color(0xFFF5D7A1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Center(
                child: Text(
                  "Add Device",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isLoadingDevices)
                      CircularProgressIndicator()
                    else if (availableDevices?.isEmpty ?? true)
                      Text(
                        'No available devices found',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      )
                    else
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        hint: Text('Select device'),
                        value: deviceName.isEmpty ? null : deviceName,
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              deviceName = newValue;
                            });
                          }
                        },
                        items: availableDevices?.map<DropdownMenuItem<String>>((UDevice device) {
                          return DropdownMenuItem<String>(
                            value: device.id,
                            child: Text(device.name),
                          );
                        }).toList() ?? [],
                      ),
                  ],
                ),
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                ElevatedButton(
                  onPressed: availableDevices?.isEmpty ?? true ? null : () async {
                    if (deviceName.isNotEmpty) {
                      try {
                        await APIs.addDeviceToCage(deviceName, cage!.id);
                        if (!mounted) return; // Add mounted check
                        await _loadCageDetails();
                        if (!mounted) return; // Add mounted check
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Device added successfully"),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        if (!mounted) return; // Add mounted check
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Failed to add device: $e"),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF2C5D51),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: Text(
                    "Add",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFB22222),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: Text(
                    "Cancel",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddSensorDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String sensorId = '';
        List<SensorInit>? availableSensors;
        bool isLoadingSensors = true;

        return StatefulBuilder(
          builder: (context, setState) {
            // Fetch available sensors when dialog opens
            if (isLoadingSensors) {
              APIs.getAvailableSensor().then((sensors) {
                if (!mounted) return; // Add mounted check
                setState(() {
                  availableSensors = sensors;
                  isLoadingSensors = false;
                });
              }).catchError((error) {
                if (!mounted) return; // Add mounted check
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('No available sensors found'),
                    backgroundColor: Colors.red,
                  ),
                );
                setState(() {
                  isLoadingSensors = false;
                });
              });
            }

            return AlertDialog(
              backgroundColor: Color(0xFFF5D7A1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Center(
                child: Text(
                  "Add Sensor",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isLoadingSensors)
                      CircularProgressIndicator()
                    else
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        hint: Text('Select sensor'),
                        value: sensorId.isEmpty ? null : sensorId,
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              sensorId = newValue;
                            });
                          }
                        },
                        items: availableSensors?.map<DropdownMenuItem<String>>((SensorInit sensor) {
                          return DropdownMenuItem<String>(
                            value: sensor.id,
                            child: Text(sensor.name),  // Fix: proper access to name property
                          );
                        }).toList() ?? [],
                      ),
                  ],
                ),
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                ElevatedButton(
                  onPressed: () async {
                    if (sensorId.isNotEmpty) {
                      try {
                        await APIs.assignSensorToCage(sensorId, cage!.id);
                        if (!mounted) return; // Add mounted check
                        await _loadCageDetails();
                        if (!mounted) return; // Add mounted check
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Sensor added successfully"),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        if (!mounted) return; // Add mounted check
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Failed to add sensor: $e"),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF2C5D51),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: Text(
                    "Add",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFB22222),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: Text(
                    "Cancel",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDeviceList() {
    return cageDetails == null || (cageDetails?.devices?.isEmpty ?? true)
        ? Center(
            child: Text(
              "No devices found.",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          )
        : ListView.builder(
            itemCount: cageDetails?.devices?.length ?? 0,
            itemBuilder: (context, index) {
              final device = cageDetails!.devices![index];
              return Card(
                color: kBase1,
                margin: EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  title: Text(
                    device.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: lSectionTitle,
                    ),
                  ),
                  subtitle: Text(
                    "Status: ${device.status}",
                    style: TextStyle(color: lSectionTitle),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          // Confirmation dialog for deleting device
                          return AlertDialog(
                            backgroundColor: Color(0xFFF5D7A1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            title: Center(
                              child: Text(
                                'Delete Device',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            content: Text(
                              'Are you sure you want to delete this device?',
                              textAlign: TextAlign.center,
                            ),
                            actionsAlignment: MainAxisAlignment.center,
                            actions: [
                              // Yes button
                              ElevatedButton(
                                onPressed: () async {
                                  try {
                                    await APIs.deleteDevice(cage!.id, device.id);
                                    if (!mounted) return; // Add mounted check
                                    Navigator.of(context).pop();
                                    _loadCageDetails(); // Reload cage details
                                    if (!mounted) return; // Add mounted check
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("Device deleted successfully"),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } catch (e) {
                                    if (!mounted) return; // Add mounted check
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("Failed to delete device: $e"),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF2C5D51),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                ),
                                child: Text(
                                  "Yes",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFFB22222),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                ),
                                child: Text(
                                  "Cancel",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              );
            },
          );
  }

  Widget _buildSensorList() {
    return cageDetails == null || (cageDetails?.sensors?.isEmpty ?? true)
        ? Center(
            child: Text(
              "No sensors found.",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          )
        : ListView.builder(
            itemCount: cageDetails?.sensors?.length ?? 0,
            itemBuilder: (context, index) {
              final sensor = cageDetails!.sensors![index];
              return Card(
                color: kBase1,
                margin: EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  title: Text(
                    sensor.getSensorName(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: lSectionTitle,
                    ),
                  ),
                  subtitle: Text(
                    "Type: ${sensor.type}",
                    style: TextStyle(color: lSectionTitle),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            backgroundColor: Color(0xFFF5D7A1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            title: Center(
                              child: Text(
                                'Delete Sensor',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            content: Text(
                              'Are you sure you want to delete this sensor?',
                              textAlign: TextAlign.center,
                            ),
                            actionsAlignment: MainAxisAlignment.center,
                            actions: [
                              ElevatedButton(
                                onPressed: () async {
                                  try {
                                    await APIs.deleteSensor(sensor.id);
                                    if (!mounted) return; // Add mounted check
                                    Navigator.of(context).pop();
                                    _loadCageDetails();
                                    if (!mounted) return; // Add mounted check
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("Sensor deleted successfully"),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } catch (e) {
                                    if (!mounted) return; // Add mounted check
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("Failed to delete sensor: $e"),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF2C5D51),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                ),
                                child: Text(
                                  "Yes",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFFB22222),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                ),
                                child: Text(
                                  "Cancel",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              );
            },
          );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBase2,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 60,
        backgroundColor: kBase2,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: kBase0),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: Text(
          cage?.name ?? "Add Cage",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: kBase0,
          ),
        ),

        // Delete button
        actions: [
          if (cage != null) // Only show delete button if cage exists
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      backgroundColor: Color(0xFFF5D7A1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      title: Center(
                        child: Text(
                          'Are you sure you want to\ndelete this cage?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      actionsAlignment: MainAxisAlignment.center,
                      actions: [
                        ElevatedButton(
                          onPressed: () async {
                            try {
                              await APIs.deleteCage(cage!.id);
                              if (!mounted) return; // Add mounted check
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Cage deleted successfully'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              Navigator.of(context).pop(); // Close dialog
                              Navigator.pop(context, true); // Return to previous screen with reload flag
                            } catch (e) {
                              if (!mounted) return; // Add mounted check
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to delete cage: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF2C5D51),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                          ),
                          child: Text(
                            'Yes',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFB22222),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
        ],
      ),

      body: Container(
        decoration: BoxDecoration(
          color: lappBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Toggle buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ToggleButtons(
                    borderRadius: BorderRadius.circular(10),
                    selectedColor: Colors.white,
                    fillColor: Color(0xFF2C5D51),
                    onPressed: (int index) {
                      setState(() {
                        showDevices = index == 0;
                      });
                    },
                    isSelected: [showDevices, !showDevices],
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('Devices'),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('Sensors'),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 20),

              // Title and add button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    showDevices 
                      ? 'Devices (${(cageDetails?.devices?.length ?? 0)})'
                      : 'Sensors (${(cageDetails?.sensors?.length ?? 0)})',
                    style: TextStyle(
                      color: lSectionTitle,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      if (showDevices) {
                        _showAddDeviceDialog();
                      } else {
                        _showAddSensorDialog();
                      }
                    },
                    icon: Icon(Icons.add_circle, color: secondaryButtonContent),
                    iconSize: 35,
                  ),
                ],
              ),

              // List view
              Expanded(
                child: isLoading 
                    ? Center(child: CircularProgressIndicator())
                    : showDevices
                        ? _buildDeviceList()
                        : _buildSensorList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



