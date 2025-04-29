import 'package:intl/intl.dart';

class ChartSummary {
  final double average;
  final double highest;
  final double lowest;

  ChartSummary({
    required this.average,
    required this.highest,
    required this.lowest,
  });

  factory ChartSummary.fromJson(Map<String, dynamic> json) {
    return ChartSummary(
      average: (json['average'] as num).toDouble(),
      highest: (json['highest'] as num).toDouble(),
      lowest: (json['lowest'] as num).toDouble(),
    );
  }
}

class ChartData {
  final String day;
  final double value;
  final String? summary;

  ChartData({
    required this.day,
    required this.value,
    this.summary,
  });

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
      summary: json['summary'] as String?,
    );
  }

  static List<ChartData> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((item) => ChartData.fromJson(item)).toList();
  }
}

class ChartResponse {
  final List<ChartData> statistics;
  final ChartSummary summary;

  ChartResponse({
    required this.statistics,
    required this.summary,
  });

  factory ChartResponse.fromJson(Map<String, dynamic> json) {
    return ChartResponse(
      statistics: (json['statistics'] as List)
          .map((item) => ChartData.fromJson(item))
          .toList(),
      summary: ChartSummary.fromJson(json['summary'] as Map<String, dynamic>),
    );
  }
}
