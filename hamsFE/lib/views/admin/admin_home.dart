import 'package:flutter/material.dart';
import 'package:hamsFE/views/admin/admin_new_user.dart';
import 'package:hamsFE/views/admin/admin_view_user.dart';
import 'package:hamsFE/views/constants.dart';
import '../../models/user.dart';
import '../../controllers/apis.dart';

class AdminHome extends StatefulWidget {
  final User user;
  const AdminHome({super.key, required this.user});

  @override
  State<StatefulWidget> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  late final User user;
  List<User> users = []; // Initialize an empty list of users
  bool _isLoading = true; // Add a loading indicator

  @override
  void initState() {
    super.initState();
    user = widget.user;
    // _loadUsers(); // Load users when the widget is initialized
  }

    @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadUsers(); // Load users when the widget is initialized or dependencies change
  }
  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true; // Set loading to true before fetching data
    });
    try {
      List<User> fetchedUsers = await APIs.getAlluser();
      setState(() {
        users = fetchedUsers; // Update the users list with fetched data
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBase2,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(20),
              color: kBase2,
              child: Text(
                'HI, ${user.name}',
                style: TextStyle(
                  color: kBase0,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                padding: EdgeInsets.symmetric(vertical: 20, horizontal: 30),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Users',
                          style: TextStyle(
                            color: primaryText,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () async {
                            final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => AddUser(user: user)));
                            if (result == true) {
                              _loadUsers(); // Reload users if result is true
                            }
                          },
                          icon: Icon(Icons.add_circle, color: secondaryButtonContent),
                          iconSize: 35,
                          constraints: BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                        )
                      ],
                    ),
                    Expanded(
                      child: _isLoading // Show loading indicator if data is loading
                          ? Center(child: CircularProgressIndicator())
                          : ListView.builder(
                              itemCount: users.length, // Use the length of the users list
                              itemBuilder: (context, index) {
                                return Card(
                                  color: kBase1,
                                  margin: EdgeInsets.symmetric(vertical: 4),
                                  child: ListTile(
                                    title: Text(users[index].name, style: TextStyle(fontWeight: FontWeight.bold, color: primaryText),),  // Display the user's username
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                            onPressed: () async {
                                              final result = await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => AdminViewUser(participant: users[index]),
                                                ),
                                              );
                                              if (result == true) {
                                                _loadUsers(); // Reload users if user was deleted
                                              }
                                            },
                                            icon: Icon(Icons.edit, color: Colors.blue)),
                                        IconButton(
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
                                                          APIs.deleteUser(users[index].id).then((value) {
                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                              SnackBar(
                                                                content: Text('User deleted successfully'),
                                                                backgroundColor: Colors.green,
                                                              ),
                                                            );
                                                            _loadUsers();
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
                                            icon: Icon(Icons.delete, color: primaryText))
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}