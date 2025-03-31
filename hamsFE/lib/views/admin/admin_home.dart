import 'package:flutter/material.dart';
import 'package:hamsFE/views/admin/admin_new_user.dart';
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
      print('Failed to load users: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load users: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => AddUser(user: user)));
                          },
                          icon: Icon(Icons.add_circle, color: secondaryButtonContent),
                          iconSize: 35, // Set the size of the icon
                          constraints: BoxConstraints(
                            minWidth: 40, // Set the minimum width
                            minHeight: 40, // Set the minimum height
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
                                            onPressed: () {

                                            },
                                            icon: Icon(Icons.edit, color: Colors.blue)),
                                        IconButton(
                                            onPressed: () {},
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