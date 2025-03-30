import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hamsFE/controllers/apis.dart';
import 'package:hamsFE/views/temp.dart';
import 'package:hamsFE/views/user/user_home.dart';
import 'package:hamsFE/views/user/user_profile.dart';
import '../models/user.dart';
import 'admin/admin_profile.dart';
import 'constants.dart';

class UserApp extends StatefulWidget {
  const UserApp({super.key});

  @override
  State<StatefulWidget> createState() => _UserAppState();
}

class _UserAppState extends State<UserApp> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;
  late final User _user;
  late bool _isLoading;

  @override
  void initState() {
    super.initState();
    _isLoading = true;
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      User fetchedUser = await APIs.getUserInfo();
      setState(() {
        _user = fetchedUser;
        _isLoading = false;
        _pages = <Widget>[
          UserHome(user: _user),
          Temp(),
          Temp(),
          UserProfile(user: _user),
        ];
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

      if (kDebugMode) {
        print(e);
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Scaffold(
      body: Stack(
        children: [
          _pages[_selectedIndex], // Ensure each page has its own Scaffold
          // Floating Bottom Navigation Bar
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: BottomNavigationBar(
                  currentIndex: _selectedIndex,
                  selectedItemColor: selectedItem,
                  unselectedItemColor: unselectedItem,
                  backgroundColor: kBase2,
                  onTap: _onItemTapped,
                  type: BottomNavigationBarType.fixed,
                  showUnselectedLabels: false,
                  showSelectedLabels: false,
                  items: [
                    BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                    BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Statistics'),
                    BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notifications'),
                    BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
