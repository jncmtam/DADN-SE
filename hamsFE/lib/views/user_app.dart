import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hamsFE/controllers/apis.dart';
import 'package:hamsFE/models/noti.dart';
import 'package:hamsFE/views/user/user_home.dart';
import 'package:hamsFE/views/user/user_notification.dart';
import 'package:hamsFE/views/user/user_profile.dart';
import 'package:hamsFE/views/utils.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:hamsFE/views/user/user_statistic.dart';
import 'constants.dart';

class UserApp extends StatefulWidget {
  const UserApp({super.key});

  @override
  State<StatefulWidget> createState() => _UserAppState();
}

class _UserAppState extends State<UserApp> {
  int _selectedIndex = 0;
  late bool _isLoading;
  final List<MyNotification> _notifications = [];
  late WebSocketChannel _channel;
  late List<Widget> _pages;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    _isLoading = true;
    _initApp();
  }

  Future<void> _initApp() async {
    try {
      final user = await APIs.getUserInfo();
      final notifs = await APIs.getUserNotifications();

      _notifications.addAll(notifs);
      _connectWebSocket();

      setState(() {
        _pages = <Widget>[
          UserHome(userName: user.name),
          ChartExample(),
          UserNotification(
            notifications: _notifications,
            onMarkAsRead: _markAsRead,
          ),
          UserProfile(user: user),
        ];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: const Text('Something went wrong'),
            backgroundColor: debugStatus,
          ),
        );
      }
      debugPrint(e.toString());
    }
  }

  void _connectWebSocket() {
    _channel = APIs.listenUserNotifications();

    _channel.stream.listen((message) {
      final data = jsonDecode(message);
      debugPrint('WebSocket message: $data');
      final newNotif = MyNotification.fromJson(data);

      setState(() {
        _notifications.insert(0, newNotif);
      });

      if (_selectedIndex != 2) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(newNotif.title),
            backgroundColor: Utils.getStatusColor(newNotif.type),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }, onError: (error) {
      debugPrint('WebSocket error: $error');
    });
  }

  void _markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].read) {
      setState(() {
        _notifications[index].read = true;
      });

      APIs.markNotificationAsRead(id);
    }
  }

  int _unreadCount() => _notifications.where((n) => !n.read).length;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void dispose() {
    _channel.sink.close();
    super.dispose();
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

    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        body: _pages[_selectedIndex],
        backgroundColor: lappBackground,
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BottomNavigationBar(
              iconSize: 30,
              currentIndex: _selectedIndex,
              selectedItemColor: selectedTab,
              unselectedItemColor: unselectedTab,
              backgroundColor: kBase2,
              onTap: _onItemTapped,
              type: BottomNavigationBarType.fixed,
              showUnselectedLabels: false,
              showSelectedLabels: false,
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Home',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.bar_chart),
                  label: 'Statistics',
                ),
                BottomNavigationBarItem(
                  icon: Stack(
                    children: [
                      const Icon(Icons.notifications),
                      if (_unreadCount() > 0)
                        Positioned(
                          right: 0,
                          top: -6,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                                minWidth: 16, minHeight: 16),
                            child: Text(
                              '${_unreadCount()}',
                              style: const TextStyle(
                                color: primaryButtonContent,
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  label: 'Notifications',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
