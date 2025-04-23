import 'package:flutter/material.dart';
import 'package:hamsFE/views/constants.dart';
import 'package:intl/intl.dart';

class Utils {
  static String processDisplayValue(dynamic value) {
    if (value is List<String>) {
      return value.join(', ');
    } else if (value is DateTime) {
      return DateFormat('yyyy-MM-dd HH:mm:ss').format(value);
      // return value.toIso8601String().substring(0, 10); // format???
      // return "${value.day.toString().padLeft(2, '0')}-${value.month.toString().padLeft(2, '0')}-${value.year}";
    } else {
      return value.toString();
    }
  }

  static Widget displayInfo(String label, dynamic value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: lPrimaryText,
            ),
          ),
          Flexible(
            child: Text(
              Utils.processDisplayValue(value),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 16,
                color: lNormalText,
              ),
            ),
          )
        ],
      ),
    );
  }
}
