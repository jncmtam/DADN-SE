import 'package:flutter/material.dart';
import '../constants.dart';

class UserNotification extends StatefulWidget {
  const UserNotification({super.key});

  @override
  State<StatefulWidget> createState() => _UserNotificationState();
}

class _UserNotificationState extends State<UserNotification> {
  late bool _isLoading;

  @override
  void initState() {
    super.initState();
    _isLoading = true;
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      setState(() {
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
          child: CircularProgressIndicator(),
        ),
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
            color: kBase0,
          ),
        ),
      ),
      backgroundColor: lappBackground,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
