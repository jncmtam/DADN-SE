import 'package:flutter/material.dart';
import 'package:hamsFE/views/constants.dart';

import '../../models/user.dart';

class AdminHome extends StatefulWidget {
  final User user;
  const AdminHome({super.key, required this.user});

  @override
  State<StatefulWidget> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  late final User user;

  @override
  void initState() {
    super.initState();
    user = widget.user;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.only(left: 25, right: 25, top: 40),
        physics: BouncingScrollPhysics(),
        children: [
          // Greeting user
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi, ${user.name}',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: lPrimaryText),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
