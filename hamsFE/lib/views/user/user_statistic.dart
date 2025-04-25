import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

void main() async {
  runApp(MaterialApp(
    home: const ChartExample(),
    debugShowCheckedModeBanner: false,
  ));
}

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

class ChartExample extends StatefulWidget {
  const ChartExample({super.key});

  @override
  State<ChartExample> createState() => _ChartExampleState();
}

class _ChartExampleState extends State<ChartExample> {
  // Example JSON data with weekdays
  final List<Map<String, dynamic>> jsonData = [
    {"day": "2025-04-21", "value": 35}, // Monday
    {"day": "2025-04-22", "value": 28}, // Tuesday
    {"day": "2025-04-23", "value": 34}, // Wednesday
    {"day": "2025-04-24", "value": 32}, // Thursday
    {"day": "2025-04-25", "value": 40}, // Friday
    {"day": "2025-04-26", "value": 25}, // Saturday
    {"day": "2025-04-27", "value": 30}, // Sunday
  ];

  late final List<ChartData> chartData;
  
  @override
  void initState() {
    super.initState();
    // Convert JSON to ChartData objects
    chartData = jsonData.map((data) => ChartData.fromJson(data)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chart Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: BarChart(
          BarChartData(
            gridData: FlGridData(show: false),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,  // Reduced since we have shorter day names now
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() < 0 || value.toInt() >= chartData.length) {
                      return const Text('');
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                        chartData[value.toInt()].day,
                        style: const TextStyle(
                          fontSize: 12,  // Back to original size since we have shorter names
                        ),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                ),
              ),
              topTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border(
                bottom: BorderSide(color: Colors.black),
                left: BorderSide(color: Colors.black),
              ),
            ),
            barGroups: chartData.asMap().entries.map((entry) {
              return BarChartGroupData(
                x: entry.key,
                barRods: [
                  BarChartRodData(
                    toY: entry.value.value,
                    color: Colors.blue,
                    width: 20,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}