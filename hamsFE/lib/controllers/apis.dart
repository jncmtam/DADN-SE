import 'dart:async';
import 'dart:convert';
import 'package:hamsFE/controllers/session.dart';
import 'package:hamsFE/models/cage.dart';
import 'package:hamsFE/models/device.dart';
import 'package:hamsFE/models/rule.dart';
import 'package:hamsFE/models/sensor.dart';
import 'package:hamsFE/views/sample_data.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/user.dart';
import '../views/constants.dart';

class APIs {
  static const String baseUrl = apiUrl;

  // Auth APIs
  static Future<bool> login(String email, String password) async {
    Uri url = Uri.parse('$baseUrl/auth/login');

    final response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, String>{
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final token = jsonDecode(response.body)['access_token'];
      await SessionManager().login(token); // save token to secure storage
      return true;
    } else if (response.statusCode == 401) {
      return false;
    } else {
      final error = jsonDecode(response.body)['error'];
      throw Exception('Failed to login: $error');
    }
  }

  static Future<void> logout() async {
    await SessionManager().logout();
  }

  static Future<User> getUserInfo() async {
    final userId = SessionManager().getUserId();
    Uri url = Uri.parse('$baseUrl/user/$userId');

    final response = await http.get(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${SessionManager().getJwt()}',
      },
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      final error = jsonDecode(response.body)['error'];
      throw Exception('Failed to get user info: $error');
    }
  }

  static Future<bool> changePassword(
      String currentPassword, String newPassword) async {
    Uri url = Uri.parse('$baseUrl/auth/change-password');

    final response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${SessionManager().getJwt()}',
      },
      body: jsonEncode(<String, String>{
        'old_password': currentPassword,
        'new_password': newPassword,
      }),
    );

    if (response.statusCode == 200) {
      return true;
    } else if (response.statusCode == 401) {
      return false;
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Unknown error';
      throw Exception('Failed to change password: $error');
    }
  }

  static Future<void> forgotPassword(String email) async {
    Uri url = Uri.parse('$baseUrl/auth/forgot-password');

    final response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, String>{
        'email': email,
      }),
    );

    if (response.statusCode == 200) {
      return;
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Unknown error';
      throw Exception('Failed to send reset password email: $error');
    }
  }

  static Future<void> resetPassword(
      String email, String otp, String newPasswd) async {
    Uri url = Uri.parse('$baseUrl/auth/reset-password');

    final response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, String>{
        'email': email,
        'otp_code': otp,
        'new_password': newPasswd,
      }),
    );

    if (response.statusCode == 200) {
      return;
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Unknown error';
      throw Exception('Failed to reset password: $error');
    }
  }

  // Cage APIs
  static Future<int> getUserActiveDevices() async {
    return sampleActiveDeviceCount;

    // Uri url = Uri.parse('$baseUrl/user/active-device-count');

    // final response = await http.get(
    //   url,
    //   headers: <String, String>{
    //     'Content-Type': 'application/json',
    //     'Authorization': 'Bearer ${SessionManager().getJwt()}',
    //   },
    // );

    // if (response.statusCode == 200) {
    //   return jsonDecode(response.body)['active_device_count'];
    // } else {
    //   final error = jsonDecode(response.body)['error'] ?? 'Unknown error';
    //   throw Exception('Failed to get active device count: $error');
    // }
  }

  static Future<List<UCage>> getUserCages() async {
    return sampleCages;

    // Uri url = Uri.parse('$baseUrl/user/cages');

    // final response = await http.get(
    //   url,
    //   headers: <String, String>{
    //     'Content-Type': 'application/json',
    //     'Authorization': 'Bearer ${SessionManager().getJwt()}',
    //   },
    // );

    // if (response.statusCode == 200) {
    //   List<dynamic> cages = jsonDecode(response.body);
    //   return cages.map((cage) => UCage.fromJson(cage)).toList();
    // } else {
    //   final error = jsonDecode(response.body)['error'] ?? 'Unknown error';
    //   throw Exception('Failed to get cages: $error');
    // }
  }

  static Future<void> enableCage(String cageId) async {
    return;
  }

  static Future<void> disableCage(String cageId) async {
    return;
  }

  static Future<UDetailedCage> getCageDetails(String cageId) async {
    return sampleDetailedCage;

    // Uri url = Uri.parse('$baseUrl/user/cages/$cageId');

    // final response = await http.get(
    //   url,
    //   headers: <String, String>{
    //     'Content-Type': 'application/json',
    //     'Authorization': 'Bearer ${SessionManager().getJwt()}',
    //   },
    // );

    // if (response.statusCode == 200) {
    //   return UDetailedCage.fromJson(jsonDecode(response.body));
    // } else {
    //   final error = jsonDecode(response.body)['error'] ?? 'Unknown error';
    //   throw Exception('Failed to get cage details: $error');
    // }
  }

  // Sensor Data APIs
  static WebSocketChannel getCageSensorData(String cageId) {
    return WebSocketChannel.connect(Uri.parse(sampleWebSocketUrl));

    // final token = SessionManager().getJwt();
    // final url =
    //     Uri.parse('$baseUrl/user/cages/$cageId/sensor-data?token=$token');
    // return WebSocketChannel.connect(url);
  }

  // Device APIs
  static Future<void> setDeviceStatus(
      String deviceId, DeviceStatus status) async {
    return;
  }

  static Future<UDetailedDevice> getDeviceDetails(String deviceId) async {
    return sampleDetailedDevice;

    // Uri url = Uri.parse('$baseUrl/user/devices/$deviceId');

    // final response = await http.get(
    //   url,
    //   headers: <String, String>{
    //     'Content-Type': 'application/json',
    //     'Authorization': 'Bearer ${SessionManager().getJwt()}',
    //   },
    // );

    // if (response.statusCode == 200) {
    //   return UDetailedDevice.fromJson(jsonDecode(response.body));
    // } else {
    //   final error = jsonDecode(response.body)['error'] ?? 'Unknown error';
    //   throw Exception('Failed to get device details: $error');
    // }
  }

  // get sensor list of a cage for display dropdown
  static Future<List<USensor>> getCageSensors(String cageId) async {
    return sampleSensors;

    // Uri url = Uri.parse('$baseUrl/user/cages/$cageId/sensors');

    // final response = await http.get(
    //   url,
    //   headers: <String, String>{
    //     'Content-Type': 'application/json',
    //     'Authorization': 'Bearer ${SessionManager().getJwt()}',
    //   },
    // );

    // if (response.statusCode == 200) {
    //   List<dynamic> sensors = jsonDecode(response.body);
    //   return sensors.map((sensor) => USensor.fromJson(sensor)).toList();
    // } else {
    //   final error = jsonDecode(response.body)['error'] ?? 'Unknown error';
    //   throw Exception('Failed to get sensors: $error');
    // }
  }

  // Automation rules APIs
  static Future<void> addConditionalRule(
      String deviceId, ConditionalRule rule) async {
    return;
    // Uri url = Uri.parse('$baseUrl/user/devices/$deviceId/automations');

    // final response = await http.post(
    //   url,
    //   headers: <String, String>{
    //     'Content-Type': 'application/json',
    //     'Authorization': 'Bearer ${SessionManager().getJwt()}',
    //   },
    //   body: jsonEncode(rule.toJson()),
    // );

    // if (response.statusCode == 200) {
    //   return;
    // } else {
    //   final error = jsonDecode(response.body)['error'] ?? 'Unknown error';
    //   throw Exception('Failed to add conditional rule: $error');
    // }
  }

  static Future<void> deleteConditionalRule(String ruleId) async {
    return;
    // Uri url = Uri.parse('$baseUrl/user/automations/$ruleId');

    // final response = await http.delete(
    //   url,
    //   headers: <String, String>{
    //     'Content-Type': 'application/json',
    //     'Authorization': 'Bearer ${SessionManager().getJwt()}',
    //   },
    // );

    // if (response.statusCode == 200) {
    //   return;
    // } else {
    //   final error = jsonDecode(response.body)['error'] ?? 'Unknown error';
    //   throw Exception('Failed to delete conditional rule: $error');
    // }
  }

  static Future<void> addScheduledRule(
      String deviceId, ScheduledRule rule) async {
    return;
    // Uri url = Uri.parse('$baseUrl/user/devices/$deviceId/schedules');

    // final response = await http.post(
    //   url,
    //   headers: <String, String>{
    //     'Content-Type': 'application/json',
    //     'Authorization': 'Bearer ${SessionManager().getJwt()}',
    //   },
    //   body: jsonEncode(rule.toJson()),
    // );

    // if (response.statusCode == 200) {
    //   return;
    // } else {
    //   final error = jsonDecode(response.body)['error'] ?? 'Unknown error';
    //   throw Exception('Failed to add scheduled rule: $error');
    // }
  }

  static Future<void> deleteScheduledRule(String ruleId) async {
    return;
    // Uri url = Uri.parse('$baseUrl/user/schedules/$ruleId');

    // final response = await http.delete(
    //   url,
    //   headers: <String, String>{
    //     'Content-Type': 'application/json',
    //     'Authorization': 'Bearer ${SessionManager().getJwt()}',
    //   },
    // );

    // if (response.statusCode == 200) {
    //   return;
    // } else {
    //   final error = jsonDecode(response.body)['error'] ?? 'Unknown error';
    //   throw Exception('Failed to delete scheduled rule: $error');
    // }
  }
}
