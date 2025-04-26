import 'package:intl/intl.dart';
class ChartData {
  final String day;
  final double value;

  ChartData({required this.day, required this.value});

  factory ChartData.fromJson(Map<String, dynamic> json) {
    String dayValue = json['day'] as String;
    // Try to parse as a date if it's a full date string
    try {
      final date = DateTime.parse(dayValue);
      dayValue = DateFormat('E').format(date); // 'E' gives short weekday name
    } catch (e) {
      // If parsing fails, use the string as is (assuming it's already a short day name)
    }
    
    return ChartData(
      day: dayValue,
      value: (json['value'] as num).toDouble(),
    );
  }
}