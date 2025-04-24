enum NotificationType { info, warning, error, unknown }

class MyNotification {
  final String id;
  final String title;
  final DateTime timestamp;
  final NotificationType type;
  bool read;

  MyNotification({
    required this.id,
    required this.title,
    required this.timestamp,
    required this.type,
    this.read = false,
  });

  factory MyNotification.fromJson(Map<String, dynamic> json) {
    return MyNotification(
      id: json['id'], // required
      title: json['title'] ?? 'N/A',
      timestamp: DateTime.parse(json['timestamp']),
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == 'NotificationType.${json['type']}',
        orElse: () => NotificationType.unknown,
      ),
      read: json['read'] ?? false,
    );
  }
}
