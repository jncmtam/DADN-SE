import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hamsFE/models/chartdata.dart';
import 'package:hamsFE/controllers/apis.dart';
import 'package:hamsFE/views/constants.dart';
import 'package:hamsFE/models/cage.dart';

class ChartExample extends StatefulWidget {
  const ChartExample({super.key});

  @override
  State<ChartExample> createState() => _ChartExampleState();
}

class _ChartExampleState extends State<ChartExample> {
  List<ChartData> statistics = [];
  ChartSummary? summary;
  List<UCage> cages = [];
  String? selectedCageId;
  bool isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadCages();
  }

  Future<void> _loadCages() async {
    try {
      final data = await APIs.getUserCages();
      setState(() {
        cages = data;
        if (cages.isNotEmpty) {
          selectedCageId = cages[0].id;
          _fetchChartData();
        } else {
          isLoading = false;
        }
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load cages: $e')),
        );
      }
    }
  }

  Future<void> _fetchChartData() async {
    if (selectedCageId == null) return;
    
    setState(() {
      isLoading = true;
    });

    try {
      // Get current date and 7 days ago for the date range
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));
      
      final response = await APIs().getChartData(
        selectedCageId!,
        sevenDaysAgo.toIso8601String().split('T')[0],
        now.toIso8601String().split('T')[0]
      );
      
      if (mounted) {
        setState(() {
          statistics = response.statistics;
          summary = response.summary;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load chart data: $e')),
        );
      }
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
          'Water Consumption',
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
            : cages.isEmpty
                ? const Center(child: Text('No cages available'))
                : Column(
                    children: [
                      // Cage Dropdown
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: kBase0,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: kBase2, width: 2),
                        ),
                        child: DropdownButton<String>(
                          value: selectedCageId,
                          isExpanded: true,
                          dropdownColor: kBase0,
                          icon: Icon(Icons.arrow_drop_down, color: kBase2),
                          underline: SizedBox(),
                          style: TextStyle(
                            color: kBase2,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          items: cages.map((cage) {
                            return DropdownMenuItem<String>(
                              value: cage.id,
                              child: Text(
                                cage.name,
                                style: TextStyle(color: kBase2),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedCageId = newValue;
                              _fetchChartData();
                            });
                          },
                        ),
                      ),
                      SizedBox(height: 20),
                      // Summary Cards
                      if (summary != null) Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: kBase2,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildSummaryCard('Average', summary!.average.toStringAsFixed(1)),
                            _buildSummaryCard('Highest', summary!.highest.toStringAsFixed(1)),
                            _buildSummaryCard('Lowest', summary!.lowest.toStringAsFixed(1)),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      // Chart
                      Expanded(
                        child: statistics.isEmpty
                            ? Center(child: Text('No data available for selected cage'))
                            : BarChart(
                                BarChartData(
                                  gridData: FlGridData(show: false),
                                  titlesData: FlTitlesData(
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 30,
                                        interval: 1,
                                        getTitlesWidget: (value, meta) {
                                          if (value.toInt() < 0 || value.toInt() >= statistics.length) {
                                            return const Text('');
                                          }
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 5),
                                            child: Text(
                                              statistics[value.toInt()].day,
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      axisNameWidget: Text(
                                        'Days',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 14,
                                        ),
                                      ),
                                      axisNameSize: 24,
                                    ),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 30,
                                      ),
                                      axisNameWidget: Text(
                                        'amount (ml)',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 14,
                                        ),
                                      ),
                                      axisNameSize: 24,
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
                                  barGroups: statistics.asMap().entries.map((entry) {
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
                    ],
                  ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: kBase0,
          ),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: kBase0,
          ),
        ),
      ],
    );
  }
}