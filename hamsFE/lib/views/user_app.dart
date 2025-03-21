import 'package:flutter/material.dart';
import 'package:hamsFE/controllers/apis.dart';
import 'package:hamsFE/views/temp.dart';
import 'package:hamsFE/views/user/profile.dart';
import '../models/user.dart';
import 'constants.dart';

class UserApp extends StatefulWidget {
  const UserApp({super.key});

  @override
  State<StatefulWidget> createState() => _UserAppState();
}

class _UserAppState extends State<UserApp> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;
  User? _user;
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
          Temp(),
          Temp(),
          Temp(),
          UserProfile(user: _user!),
        ];
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print(e);
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
      body: Center(
        child: _pages.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: SizedBox(
        height: 60,
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: false,
          showSelectedLabels: false,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: 'Statistics',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications),
              label: 'Notifications',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: kBase1,
          unselectedItemColor: kBase2,
          backgroundColor: kBase3,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
