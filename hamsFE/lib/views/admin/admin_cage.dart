import 'package:flutter/material.dart';
import 'package:hamsFE/models/cageinit.dart';
import 'package:hamsFE/views/constants.dart';
import '../../controllers/apis.dart';

class AdminCage extends StatefulWidget {
  final CageInit? cageInit;
  final String userId; // Add userId as a required parameter

  const AdminCage({Key? key, required this.cageInit, required this.userId}) : super(key: key);

  @override
  _AdminCageState createState() => _AdminCageState();
}

class _AdminCageState extends State<AdminCage> {
  CageInit? cage; // Define the cage variable

  @override
  void initState() {
    super.initState();
    if (widget.cageInit == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAddCageDialog();
      });
    }
    else {
      cage = widget.cageInit; // Initialize cage with the passed cageInit
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Cage added successfully"),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.of(context).pop(true); // Return true to indicate success
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
                Navigator.of(context).pop(false); // Return false to indicate cancellation
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
      // If dialog was dismissed or cancelled, pop back to previous screen
      if (value != true) {
        Navigator.pop(context);
      }
    });
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          cage?.name ?? "Add Cage",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: kBase0,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: kBase0,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Devices (${cage?.numDevice ?? 0})',
                    style: TextStyle(
                      color: primaryText,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      // Handle adding a new device
                    },
                    icon: Icon(Icons.add_circle, color: secondaryButtonContent),
                    iconSize: 35,
                  ),
                ],
              ),
              Expanded(
                child: cage == null || cage!.numDevice == 0
                    ? Center(
                        child: Text(
                          "No devices found.",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: cage!.numDevice,
                        itemBuilder: (context, index) {
                          return Card(
                            color: kBase1,
                            margin: EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              title: Text(
                                'Device ${index + 1}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: primaryText,
                                ),
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  // Handle device deletion
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



