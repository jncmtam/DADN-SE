import 'package:flutter/material.dart';
import 'package:hamsFE/models/noti.dart';
import 'package:intl/intl.dart';
import '../constants.dart';

class UserNotification extends StatefulWidget {
  final List<MyNotification> notifications;
  final void Function(String) onMarkAsRead;

  const UserNotification({
    super.key,
    required this.notifications,
    required this.onMarkAsRead,
  });

  @override
  State<UserNotification> createState() => _UserNotificationState();
}

class _UserNotificationState extends State<UserNotification> {
  late List<MyNotification> _notis;

  @override
  void initState() {
    super.initState();
    // Create a local mutable copy
    _notis = widget.notifications.map((n) => n.copy()).toList();
  }

  void _handleTap(String id) {
    final index = _notis.indexWhere((n) => n.id == id);
    if (index != -1 && !_notis[index].read) {
      setState(() {
        _notis[index].read = true;
      });
      widget.onMarkAsRead(id);
    }
  }

  // Icon _statusIcon(String status) {
  //   switch (status) {
  //     case 'info':
  //       return const Icon(Icons.circle, color: primaryButton, size: 10);
  //     case 'error':
  //       return const Icon(Icons.circle, color: failStatus, size: 10);
  //     case 'warning':
  //       return const Icon(Icons.circle, color: warningStatus, size: 10);
  //     default:
  //       return const Icon(Icons.circle, color: debugStatus, size: 10);
  //   }
  // }

  Color _getStatusColor(NotificationType type) {
    switch (type) {
      case NotificationType.info:
        return primaryButton;
      case NotificationType.error:
        return failStatus;
      case NotificationType.warning:
        return warningStatus;
      default:
        return debugStatus;
    }
  }

  @override
  Widget build(BuildContext context) {
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
        child: _notis.isEmpty
            ? const Center(child: Text('No notifications found'))
            : ListView.builder(
                itemCount: _notis.length,
                itemBuilder: (context, index) {
                  final notif = _notis[index];
                  return GestureDetector(
                    onTap: () => _handleTap(notif.id),
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
                          // Icon(
                          //   Icons.circle,
                          //   color: _getStatusColor(notif.type),
                          //   size: 10,
                          // ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              notif.title,
                              style: TextStyle(
                                fontWeight: notif.read
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                                color: _getStatusColor(notif.type),
                              ),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                DateFormat.Hm().format(notif.timestamp),
                                style: TextStyle(color: lNormalText),
                              ),
                              Text(
                                DateFormat('dd/MM/yyyy')
                                    .format(notif.timestamp),
                                style: TextStyle(color: lNormalText),
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

extension CopyableNotification on MyNotification {
  MyNotification copy() => MyNotification(
        id: id,
        title: title,
        timestamp: timestamp,
        type: type,
        read: read,
      );
}
