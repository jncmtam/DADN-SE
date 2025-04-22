import 'package:flutter/material.dart';
import 'package:hamsFE/models/cageinit.dart';
import 'package:hamsFE/views/constants.dart';
import '../../controllers/apis.dart';


class AdminCage extends StatefulWidget {
  final CageInit? cageInit;
  final String userId;

  const AdminCage({Key? key, required this.cageInit, required this.userId}) : super(key: key);

  @override
  _AdminCageState createState() => _AdminCageState();
}

class _AdminCageState extends State<AdminCage> {
  CageInit? cage;
  CageInit? cageDetails;
  bool isLoading = true;

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
      setState(() {
        cageDetails = details;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to load cage details: $e"),
          backgroundColor: Colors.red,
        ),
      );
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
                    setState(() {
                      cage = newCage;
                    });
                    await _loadCageDetails(); // Load cage details immediately
                    Navigator.of(context).pop(true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Cage added successfully"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
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
        String deviceType = 'display'; // Default type
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
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                 DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  hint: Text('Device name'),
                  value: deviceName.isEmpty ? null : deviceName,
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      deviceName = newValue;
                    }
                  },
                  items: [
                    'fan 1',
                    'light 1',
                    'door 1',
                  ].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value.toUpperCase()),
                    );
                  }).toList(),
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  hint: Text('Device Type'),
                  value: deviceType,
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      deviceType = newValue;
                    }
                  },
                  items: [
                    'display',
                    'none',
                  ].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value.toUpperCase()),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () async {
                if (deviceName.isNotEmpty) {
                  try {
                    await APIs.addDeviceToCage(cage!.id, deviceName, deviceType);
                    await _loadCageDetails(); // Wait for the details to load
                    Navigator.of(context).pop(); // Close dialog after successful load
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Device added successfully"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
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
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Cage deleted successfully'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              Navigator.of(context).pop(); // Close dialog
                              Navigator.pop(context, true); // Return to previous screen with reload flag
                            } catch (e) {
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

      // Cage details and devices
      // This is the main content of the screen
      // It shows the cage details and a list of devices
      // The list of devices is displayed in a scrollable view
      // The cage details are displayed at the top
      // The devices are displayed in a list below the cage details
      // The list of devices is scrollable
      // The cage details are displayed in a card
      // The devices are displayed in a list of cards
      body: Container(
        decoration: BoxDecoration(
          color: kBase0,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),

        // The device title and add button
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Devices (${(cageDetails?.devices?.length ?? 0)})',
                    style: TextStyle(
                      color: lSectionTitle,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      _showAddDeviceDialog();
                    },
                    icon: Icon(Icons.add_circle, color: secondaryButtonContent),
                    iconSize: 35,
                  ),
                ],
              ),

              // The list of devices
              // This is a scrollable list of devices
              Expanded(
                child: isLoading // Check if data is still loading
                    ? Center(child: CircularProgressIndicator()) // Show loading indicator while fetching data
                    : cageDetails == null || (cageDetails?.devices?.isEmpty ?? true) // Check if there are no devices
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
                                                    Navigator.of(context).pop();
                                                    _loadCageDetails(); // Reload cage details
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text("Device deleted successfully"),
                                                        backgroundColor: Colors.green,
                                                      ),
                                                    );
                                                  } catch (e) {
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
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



