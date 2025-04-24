import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hamsFE/controllers/apis.dart';
import 'package:hamsFE/models/noti.dart';
import 'package:intl/intl.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../constants.dart';

class UserNotification extends StatefulWidget {
  const UserNotification({super.key});

  @override
  State<StatefulWidget> createState() => _UserNotificationState();
}

class _UserNotificationState extends State<UserNotification> {
  late bool _isLoading;
  final List<MyNotification> _notifications = [];
  late WebSocketChannel _channel;

  @override
  void initState() {
    super.initState();
    _isLoading = true;
    _fetchData();
    _connectWebSocket();
  }

  Future<void> _fetchData() async {
    try {
      final notifications = await APIs.getUserNotifications();

      setState(() {
        _notifications.addAll(notifications);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
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
      final newNotif = MyNotification.fromJson(data);

      setState(() {
        _notifications.insert(0, newNotif); // Prepend new notification
      });
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

      try {
        APIs.markNotificationAsRead(id);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to mark as read'),
              backgroundColor: debugStatus,
            ),
          );
        }
        debugPrint(e.toString());
      }
    }
  }

  int _unreadCount() => _notifications.where((n) => !n.read).length;

  Icon _statusIcon(String status) {
    switch (status) {
      case 'info':
        return const Icon(Icons.circle, color: primaryButton, size: 10);
      case 'error':
        return const Icon(Icons.circle, color: failStatus, size: 10);
      case 'warning':
        return const Icon(Icons.circle, color: warningStatus, size: 10);
      default:
        return const Icon(Icons.circle, color: debugStatus, size: 10);
    }
  }

  @override
  void dispose() {
    _channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: lAppBarHeight,
        backgroundColor: kBase2,
        centerTitle: true,
        title: Text(
          'Notifications',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: lAppBarContent,
          ),
        ),
      ),
      backgroundColor: lappBackground,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _notifications.isEmpty
            ? const Center(child: Text('No notifications found'))
            : ListView.builder(
                itemCount: _notifications.length,
                itemBuilder: (context, index) {
                  final notif = _notifications[index];
                  return GestureDetector(
                    onTap: () => _markAsRead(notif.id),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            notif.read ? ldisableBackground : lcardBackground,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          _statusIcon(notif.type.toString().split('.').last),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              notif.title,
                              style: TextStyle(
                                fontWeight: notif.read
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                                color: notif.read ? lDisableText : lCardTitle,
                              ),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                DateFormat.Hm().format(notif.timestamp),
                                style: TextStyle(
                                  color: lNormalText,
                                ),
                              ),
                              Text(
                                DateFormat('dd/MM/yyyy')
                                    .format(notif.timestamp),
                                style: TextStyle(
                                  color: lNormalText,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
