import 'package:flutter/material.dart';
import 'package:hamsFE/models/cageinit.dart';
import 'package:hamsFE/views/admin/admin_cage.dart';
// import 'package:flutter/foundation.dart';
// import 'admin_home.dart';
import 'package:hamsFE/views/constants.dart';
import '../../models/user.dart';
import '../../controllers/apis.dart';
import '../utils.dart';

class AdminViewUser extends StatefulWidget {
  final User participant;
  const AdminViewUser({super.key, required this.participant});
  @override
  State<StatefulWidget> createState() => _ViewUserState();
}

class _ViewUserState extends State<AdminViewUser> {
  late final User participant;
  List<CageInit> cages = [];
  bool _isLoading = true;

  Future<void> _loadcages() async {
    setState(() {
      _isLoading = true; // Set loading to true before fetching data
    });
    try {
      List<CageInit> fetchedCages = await APIs.getUserCage(participant.id);
      setState(() {
        cages = fetchedCages; // Update the users list with fetched data
        _isLoading = false; // Set loading to false after data is fetched
      });
    } catch (e) {
      // Handle error (e.g., show a snackbar)
      setState(() {
        _isLoading = false; // Ensure loading is set to false even on error
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadcages();
  }

  @override
  void initState() {
    super.initState();
    participant = widget.participant;
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
          'Profile & Settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: kBase0,
          ),
        ),
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          color: lappBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  participant.name,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8),
                // Email
                Text(
                  participant.email,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                SizedBox(height: 16),
                // Info
                Utils.displayInfo('Role', participant.role),
                Divider(),
                Utils.displayInfo('Joined on', participant.joinDate),
                SizedBox(height: 32),
                // Delete Button
                ElevatedButton(
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
                              'Are you sure you want to\ndelete this user?',
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
                              onPressed: () {
                                Navigator.of(context).pop();
                                APIs.deleteUser(participant.id).then((value) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('User deleted successfully'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                  Navigator.pop(context, true); // Return to previous screen with reload flag
                                }).catchError((error) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to delete user: $error'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                });
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Delete user',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                // Cages header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Cages(${cages.length})',
                      style: TextStyle(
                        color: lSectionTitle,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AdminCage(cageInit: null, userId: participant.id),
                          ),
                        );
                        if (result == true) {
                          // Reload cages after adding a new cage
                          _loadcages();
                        }
                      },
                      icon: Icon(Icons.add_circle, color: secondaryButtonContent),
                      iconSize: 35,
                      constraints: BoxConstraints(minWidth: 40, minHeight: 40),
                    ),
                  ],
                ),

                // Cage list or loading
                _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : cages.isEmpty
                        ? Center(child: Text("No cages found."))
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: cages.length,
                            itemBuilder: (context, index) {
                              return Card(
                                color: kBase1,
                                margin: EdgeInsets.symmetric(vertical: 4),
                                child: InkWell(
                                  onTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AdminCage(
                                          cageInit: cages[index],
                                          userId: participant.id,
                                        ),
                                      ),
                                    );
                                    if (result == true) {
                                      _loadcages(); // Reload cages if changes were made
                                    }
                                  },
                                  child: ListTile(
                                    title: Text(
                                      cages[index].name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: lSectionTitle,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                // SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}