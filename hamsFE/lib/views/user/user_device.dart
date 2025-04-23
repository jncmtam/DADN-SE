import 'package:flutter/material.dart';
import 'package:hamsFE/models/rule.dart';
import 'package:hamsFE/models/sensor.dart';
import 'package:hamsFE/views/constants.dart';
import 'package:hamsFE/controllers/apis.dart';
import 'package:hamsFE/models/device.dart';
import 'package:hamsFE/views/utils.dart';

class UserDeviceScreen extends StatefulWidget {
  final String deviceId;
  final List<USensor> sensors;

  const UserDeviceScreen(
      {super.key, required this.deviceId, required this.sensors});

  @override
  State<StatefulWidget> createState() => _UserDeviceScreenState();
}

class _UserDeviceScreenState extends State<UserDeviceScreen> {
  late UDetailedDevice _device;
  late bool _isLoading;
  bool _deleteMode = false;
  int? _deleteIndex;

  @override
  void initState() {
    super.initState();
    _isLoading = true;
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final device = await APIs.getDeviceDetails(widget.deviceId);
      setState(() {
        _device = device;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Something went wrong'),
            backgroundColor: debugStatus,
          ),
        );
      }

      debugPrint(e.toString());
    }
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
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: lAppBarHeight,
        backgroundColor: lappBarBackground,
        centerTitle: true,
        title: Text(
          _device.name,
          style: TextStyle(
            fontSize: lAppBarFontSize,
            fontWeight: FontWeight.bold,
            color: lAppBarTitle,
          ),
        ),
        leading: IconButton(
          color: lAppBarContent,
          icon: Icon(Icons.arrow_back_ios_rounded),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      backgroundColor: lappBackground,
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Utils.displayInfo('Device ID', _device.id),
            Utils.displayInfo('Status',
                _device.status.toString().split('.').last.toUpperCase()),
            SizedBox(height: 20),
            _buildRuleList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        shape: CircleBorder(),
        backgroundColor: primaryButton,
        onPressed: _showAddRuleDialog,
        child: Icon(
          Icons.add,
          color: primaryButtonContent,
          size: 40,
        ),
      ),
    );
  }

  Widget _buildRuleList() {
    List<AutomationRule> rules = _device.condRules.cast<AutomationRule>() +
        _device.schedRules.cast<AutomationRule>();

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Automation Rules (${_device.condRules.length})',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: lSectionTitle,
            ),
          ),
          SizedBox(height: 10),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_deleteMode) {
                  setState(() {
                    _deleteMode = false;
                    _deleteIndex = null;
                  });
                }
              },
              child: ListView.separated(
                separatorBuilder: (context, index) => SizedBox(height: 10),
                itemCount: rules.length,
                itemBuilder: (context, index) {
                  final rule = rules[index];
                  return GestureDetector(
                    onLongPress: () {
                      setState(() {
                        _deleteMode = true;
                        _deleteIndex = index;
                      });
                    },
                    child: Stack(
                      children: [
                        ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          tileColor: kBase3,
                          title: Center(
                            child: Text(
                              rule.toRuleString(),
                              style: TextStyle(
                                color: lNormalText,
                              ),
                            ),
                          ),
                        ),
                        if (_deleteMode && _deleteIndex == index)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: IconButton(
                              icon: Icon(Icons.delete, color: failStatus),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text("Delete Rule"),
                                    content: Text(
                                        "Are you sure you want to delete this rule?"),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: Text("Cancel"),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: Text("Delete",
                                            style:
                                                TextStyle(color: failStatus)),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  try {
                                    if (rule is ConditionalRule) {
                                      await APIs.deleteConditionalRule(rule.id);
                                    } else if (rule is ScheduledRule) {
                                      await APIs.deleteScheduledRule(rule.id);
                                    }

                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content:
                                              Text('Rule deleted successfully'),
                                          backgroundColor: successStatus,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text('Something went wrong'),
                                          backgroundColor: debugStatus,
                                        ),
                                      );
                                    }
                                    debugPrint(e.toString());
                                  }

                                  setState(() {
                                    _deleteMode = false;
                                    _deleteIndex = null;
                                  });
                                  _fetchData();
                                }
                              },
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddRuleDialog() {
    bool isConditionTab = true;

    // Shared state holders
    String selectedSensor =
        widget.sensors.isNotEmpty ? widget.sensors.first.id : 'N/A';
    ConditionalOperator selectedOperator = ConditionalOperator.greaterThan;
    double selectedValue = 30.5;

    TimeOfDay selectedTime = TimeOfDay.now();
    Set<DayOfWeek> selectedDays = {};

    debugPrint('actionType: ${ActionType.values}');
    List<ActionType> availableActions = _device.type == DeviceType.refill
        ? ActionType.values.sublist(2, 3)
        : ActionType.values.sublist(0, 2);
    ActionType selectedAction = availableActions.first;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              child: Container(
                decoration: BoxDecoration(
                  color: kBase3,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        _tabHeader("Condition", isConditionTab, () {
                          setState(() => isConditionTab = true);
                        }),
                        _tabHeader("Schedule", !isConditionTab, () {
                          setState(() => isConditionTab = false);
                        }),
                      ],
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 30,
                      ),
                      child: Column(
                        children: [
                          // Condition UI
                          if (isConditionTab) ...[
                            // if no sensor in cage, display Text Conditional Rule unavailable
                            if (widget.sensors.isEmpty) ...[
                              Text(
                                'No sensors available',
                                style: TextStyle(
                                  color: lNormalText,
                                  fontSize: 16,
                                ),
                              ),
                            ] else ...[
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'When',
                                  style: TextStyle(
                                    color: lSectionTitle,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  DropdownButton<String>(
                                    value: selectedSensor,
                                    items: widget.sensors
                                        .map((sensor) => DropdownMenuItem(
                                              value: sensor.id,
                                              child:
                                                  Text(sensor.getSensorName()),
                                            ))
                                        .toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() => selectedSensor = val);
                                      }
                                    },
                                  ),
                                  DropdownButton<ConditionalOperator>(
                                    value: selectedOperator,
                                    items: ConditionalOperator.values
                                        .map((e) => DropdownMenuItem(
                                              value: e,
                                              child: Text(
                                                conditionalOperatorToString(e),
                                              ),
                                            ))
                                        .toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() => selectedOperator = val);
                                      }
                                    },
                                  ),
                                  SizedBox(
                                    width: 80,
                                    child: TextField(
                                      textAlign: TextAlign.center,
                                      keyboardType:
                                          TextInputType.numberWithOptions(
                                              decimal: true),
                                      decoration: InputDecoration(
                                        isDense: true,
                                        border: OutlineInputBorder(),
                                        hintText: selectedValue.toString(),
                                        hintStyle: TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                      onChanged: (val) {
                                        if (val.isNotEmpty) {
                                          setState(() => selectedValue =
                                              double.parse(val));
                                        }
                                      },
                                    ),
                                  ),
                                  Text(
                                    widget.sensors
                                        .firstWhere((sensor) =>
                                            sensor.id == selectedSensor)
                                        .unit,
                                  )
                                ],
                              ),
                              SizedBox(height: 20),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Do',
                                    style: TextStyle(
                                      color: lSectionTitle,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  DropdownButton<ActionType>(
                                    value: selectedAction,
                                    items: availableActions
                                        .map((e) => DropdownMenuItem(
                                              value: e,
                                              child: Text(
                                                actionTypeToString(e),
                                              ),
                                            ))
                                        .toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() => selectedAction = val);
                                      }
                                    },
                                  ),
                                ],
                              ),
                              SizedBox(height: 20),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryButton,
                                ),
                                onPressed: () async {
                                  if (isConditionTab) {
                                    // Save condition rule logic here
                                    final newRule = ConditionalRule(
                                      id: 'tmp',
                                      sensorId: selectedSensor,
                                      sensorType: SensorType.humidity,
                                      operator: selectedOperator,
                                      threshold: selectedValue,
                                      unit: widget.sensors
                                          .firstWhere((sensor) =>
                                              sensor.id == selectedSensor)
                                          .unit,
                                      action: selectedAction,
                                    );

                                    try {
                                      await APIs.addConditionalRule(
                                          widget.deviceId, newRule);

                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content:
                                                Text('Rule added successfully'),
                                            backgroundColor: successStatus,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content:
                                                Text('Something went wrong'),
                                            backgroundColor: debugStatus,
                                          ),
                                        );
                                      }

                                      debugPrint(e.toString());
                                    }
                                  } else {
                                    // Save schedule rule logic here
                                    final newRule = ScheduledRule(
                                      id: 'tmp',
                                      days: selectedDays.toList(),
                                      time: selectedTime,
                                      action: selectedAction,
                                    );

                                    try {
                                      await APIs.addScheduledRule(
                                          widget.deviceId, newRule);

                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content:
                                                Text('Rule added successfully'),
                                            backgroundColor: successStatus,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content:
                                                Text('Something went wrong'),
                                            backgroundColor: debugStatus,
                                          ),
                                        );
                                      }

                                      debugPrint(e.toString());
                                    }
                                  }

                                  if (context.mounted) {
                                    Navigator.pop(context);
                                  }
                                  _fetchData();
                                },
                                child: Text(
                                  'Save',
                                  style: TextStyle(
                                    color: primaryButtonContent,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ],

                          // Schedule UI
                          if (!isConditionTab) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'At',
                                  style: TextStyle(
                                    color: lSectionTitle,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                InkWell(
                                  onTap: () async {
                                    final picked = await showTimePicker(
                                      context: context,
                                      initialTime: selectedTime,
                                    );
                                    if (picked != null) {
                                      setState(() => selectedTime = picked);
                                    }
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      border: Border.all(),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      selectedTime.format(context),
                                      style: TextStyle(
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Every',
                                style: TextStyle(
                                  color: lSectionTitle,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: List.generate(
                                DayOfWeek.values.length,
                                (index) {
                                  final isSelected = selectedDays
                                      .contains(DayOfWeek.values[index]);
                                  return ChoiceChip(
                                    showCheckmark: false,
                                    label: Text(
                                      DayOfWeek.values[index]
                                          .toString()
                                          .split('.')
                                          .last,
                                      style: TextStyle(
                                        color: isSelected
                                            ? primaryButtonContent
                                            : lNormalText,
                                      ),
                                    ),
                                    selected: isSelected,
                                    selectedColor: kBase2,
                                    backgroundColor: disableStatus,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(
                                        color: isSelected
                                            ? Colors.teal
                                            : Colors.transparent,
                                      ),
                                    ),
                                    onSelected: (selected) {
                                      setState(() {
                                        if (selected) {
                                          selectedDays
                                              .add(DayOfWeek.values[index]);
                                        } else {
                                          selectedDays
                                              .remove(DayOfWeek.values[index]);
                                        }
                                      });
                                    },
                                  );
                                },
                              ),
                            ),
                            SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Do',
                                  style: TextStyle(
                                    color: lSectionTitle,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                DropdownButton<ActionType>(
                                  value: selectedAction,
                                  items: availableActions
                                      .map((e) => DropdownMenuItem(
                                            value: e,
                                            child: Text(
                                              actionTypeToString(e),
                                            ),
                                          ))
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => selectedAction = val);
                                    }
                                  },
                                ),
                              ],
                            ),
                            SizedBox(height: 20),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryButton,
                              ),
                              onPressed: () async {
                                if (isConditionTab) {
                                  // Save condition rule logic here
                                  final newRule = ConditionalRule(
                                    id: 'tmp',
                                    sensorId: selectedSensor,
                                    sensorType: SensorType.humidity,
                                    operator: selectedOperator,
                                    threshold: selectedValue,
                                    unit: widget.sensors
                                        .firstWhere((sensor) =>
                                            sensor.id == selectedSensor)
                                        .unit,
                                    action: selectedAction,
                                  );

                                  try {
                                    await APIs.addConditionalRule(
                                        widget.deviceId, newRule);

                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content:
                                              Text('Rule added successfully'),
                                          backgroundColor: successStatus,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text('Something went wrong'),
                                          backgroundColor: debugStatus,
                                        ),
                                      );
                                    }

                                    debugPrint(e.toString());
                                  }
                                } else {
                                  // Save schedule rule logic here
                                  final newRule = ScheduledRule(
                                    id: 'tmp',
                                    days: selectedDays.toList(),
                                    time: selectedTime,
                                    action: selectedAction,
                                  );

                                  try {
                                    await APIs.addScheduledRule(
                                        widget.deviceId, newRule);

                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content:
                                              Text('Rule added successfully'),
                                          backgroundColor: successStatus,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text('Something went wrong'),
                                          backgroundColor: debugStatus,
                                        ),
                                      );
                                    }

                                    debugPrint(e.toString());
                                  }
                                }

                                if (context.mounted) {
                                  Navigator.pop(context);
                                }
                                _fetchData();
                              },
                              child: Text(
                                'Save',
                                style: TextStyle(
                                  color: primaryButtonContent,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _tabHeader(String title, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? kBase3 : kBase2,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(title == "Condition" ? 16 : 0),
              topRight: Radius.circular(title == "Schedule" ? 16 : 0),
            ),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: active ? kBase2 : kBase3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
