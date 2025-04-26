import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hamsFE/models/chartdata.dart';
import 'package:hamsFE/controllers/apis.dart';
import 'package:hamsFE/views/constants.dart';

class ChartExample extends StatefulWidget {
  const ChartExample({super.key});

  @override
  State<ChartExample> createState() => _ChartExampleState();
}

class _ChartExampleState extends State<ChartExample> {
  List<ChartData> chartData = [];
  bool isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _fetchChartData();
  }

  Future<void> _fetchChartData() async {
    try {
      final data = await APIs().getChartData();
      setState(() {
        chartData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load chart data: $e')),
      );
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
          'Statistics',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: lAppBarContent,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : chartData.isEmpty
                ? const Center(child: Text('No data available'))
                : BarChart(
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