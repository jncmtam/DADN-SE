import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:hamsFE/controllers/session.dart';
import 'package:hamsFE/models/cage.dart';
import 'package:hamsFE/models/chartdata.dart';
import 'package:hamsFE/models/device.dart';
import 'package:hamsFE/models/noti.dart';
import 'package:hamsFE/models/rule.dart';
import 'package:hamsFE/models/sensor.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:hamsFE/models/cageinit.dart';

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
    // final userId = SessionManager().getUserId();
    // Uri url = Uri.parse('$baseUrl/user/$userId');
    Uri url = Uri.parse('$baseUrl/profile');

    final response = await http.get(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${SessionManager().getJwt()}',
      },
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body)['user']);
    } else {
      final error = jsonDecode(response.body)['error'];
      throw Exception('Failed to get user info: $error');
    }
  }

  static Future<Uint8List> getUserAvatar() async {
    Uri url = Uri.parse('$baseUrl/profile/avatar');

    final response = await http.get(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${SessionManager().getJwt()}',
      },
    );

    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      final error = jsonDecode(response.body)['error'];
      throw Exception('Failed to get user avatar: $error');
    }
  }

  static Future<void> changeUserAvatar(String filePath) async {
    Uri url = Uri.parse('$baseUrl/profile/avatar');

    final request = http.MultipartRequest('POST', url)
      ..headers['Authorization'] = 'Bearer ${SessionManager().getJwt()}'
      ..files.add(
        await http.MultipartFile.fromPath(
          'avatar',
          filePath,
          contentType:
              MediaType('image', lookupMimeType(filePath)!.split('/').last),
        ),
      );

    final response = await request.send();
    if (response.statusCode == 200) {
      return;
    } else {
      // final error = jsonDecode(await response.stream.bytesToString())['error'];
      throw Exception('Failed to change avatar : ${response.statusCode}');
    }
  }

  static Future<bool> changeUsername(String username) async {
    Uri url = Uri.parse('$baseUrl/profile/username');

    final response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${SessionManager().getJwt()}',
      },
      body: jsonEncode(<String, String>{
        'username': username,
      }),
    );

    if (response.statusCode == 200) {
      return true;
    } else if (response.statusCode == 409) {
      return false;
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Unknown error';
      throw Exception('Failed to change username: $error');
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
    // return sampleActiveDeviceCount;

    Uri url = Uri.parse('$baseUrl/cages/general-info');

    final response = await http.get(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${SessionManager().getJwt()}',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['active_devices'];
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Unknown error';
      throw Exception('Failed to get active device count: $error');
    }
  }

  static Future<List<UCage>> getUserCages() async {
    // return sampleCages;

    Uri url = Uri.parse('$baseUrl/cages');

    final response = await http.get(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${SessionManager().getJwt()}',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> cages = jsonDecode(response.body);
      return cages.map((cage) => UCage.fromJson(cage)).toList();
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Unknown error';
      throw Exception('Failed to get cages: $error');
    }
  }

  static Future<void> setCageStatus(String cageId, bool isEnabled) async {
    Uri url = Uri.parse('$baseUrl/cages/$cageId/status');

    final response = await http.put(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${SessionManager().getJwt()}',
      },
      body: jsonEncode(
          <String, String>{'status': isEnabled ? 'inactive' : 'active'}),
    );

    if (response.statusCode == 200) {
      return;
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Unknown error';
      throw Exception('Failed to set cage status: $error');
    }
  }

  static Future<UDetailedCage> getCageDetails(String cageId) async {
    // return sampleDetailedCage;

    Uri url = Uri.parse('$baseUrl/cages/$cageId');

    final response = await http.get(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${SessionManager().getJwt()}',
      },
    );

    if (response.statusCode == 200) {
      return UDetailedCage.fromJson(jsonDecode(response.body));
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Unknown error';
      throw Exception('Failed to get cage details: $error');
    }
  }

  // Sensor Data APIs
  static WebSocketChannel listenCageSensorData(String cageId) {
    // return WebSocketChannel.connect(Uri.parse(sampleWebSocketUrl));

    try {
      final token = SessionManager().getJwt();
      final url = Uri.parse(
        '$websocketUrl/user/cages/$cageId/sensors-data?token=$token',
      );
      return WebSocketChannel.connect(url);
    } catch (e) {
      throw Exception('Failed to connect to WebSocket: $e');
    }
  }

  // Device APIs
  static Future<void> setDeviceStatus(
      String deviceId, DeviceStatus status) async {
    Uri url = Uri.parse('$baseUrl/devices/$deviceId/status');

    // create json payload
    final payload = {
      'status': status.toString().split('.').last,
    };

    final response = await http.put(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${SessionManager().getJwt()}',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      return;
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Unknown error';
      throw Exception('Failed to set device status: $error');
    }
  }

  static Future<void> setDeviceStatus2(
      String deviceId, DeviceStatus status) async {
    Uri url = Uri.parse('$baseUrl/devices/$deviceId/control');

    // create json payload
    final payload = {
      'action': status.toString().split('.').last,
    };

    final response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${SessionManager().getJwt()}',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      return;
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Unknown error';
      throw Exception('Failed to set device status: $error');
    }
  }

  static Future<UDetailedDevice> getDeviceDetails(String deviceId) async {
    // return sampleDetailedDevice;

    Uri url = Uri.parse('$baseUrl/devices/$deviceId');

    final response = await http.get(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${SessionManager().getJwt()}',
      },
    );

    if (response.statusCode == 200) {
      return UDetailedDevice.fromJson(jsonDecode(response.body));
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Unknown error';
      throw Exception('Failed to get device details: $error');
    }
  }

  // Automation rules APIs
  static Future<void> addConditionalRule(
      String deviceId, ConditionalRule rule) async {
    Uri url = Uri.parse('$baseUrl/devices/$deviceId/automations');

    final response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${SessionManager().getJwt()}',
      },
      body: jsonEncode(rule.toJson()),
    );

    if (response.statusCode == 200) {
      return;
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Unknown error';
      throw Exception('Failed to add conditional rule: $error');
    }
  }

  static Future<void> deleteConditionalRule(String ruleId) async {
    Uri url = Uri.parse('$baseUrl/automations/$ruleId');

    final response = await http.delete(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${SessionManager().getJwt()}',
      },
    );

    if (response.statusCode == 200) {
      return;
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Unknown error';
      throw Exception('Failed to delete conditional rule: $error');
    }
  }

  static Future<void> addScheduledRule(
      String deviceId, ScheduledRule rule) async {
    Uri url = Uri.parse('$baseUrl/devices/$deviceId/schedules');

    final response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${SessionManager().getJwt()}',
      },
      body: jsonEncode(rule.toJson()),
    );

    if (response.statusCode == 200) {
      return;
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Unknown error';
      throw Exception('Failed to add scheduled rule: $error');
    }
  }

  static Future<void> deleteScheduledRule(String ruleId) async {
    Uri url = Uri.parse('$baseUrl/schedules/$ruleId');

    final response = await http.delete(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${SessionManager().getJwt()}',
      },
    );

    if (response.statusCode == 200) {
      return;
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Unknown error';
      throw Exception('Failed to delete scheduled rule: $error');
    }
  }

  // Notification APIs

  static Future<List<MyNotification>> getUserNotifications() async {
    // return sampleNotifications;

    Uri url = Uri.parse('$baseUrl/notifications');

    final response = await http.get(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${SessionManager().getJwt()}',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> notifications = jsonDecode(response.body)['notifications'];
      return notifications
          .map((notification) => MyNotification.fromJson(notification))
          .toList();
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Unknown error';
      throw Exception('Failed to get notifications: $error');
    }
  }

  static Future<void> markNotificationAsRead(String notificationId) async {
    Uri url = Uri.parse('$baseUrl/notifications/$notificationId/read');

    final response = await http.patch(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${SessionManager().getJwt()}',
      },
    );

    if (response.statusCode == 200) {
      return;
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Unknown error';
      throw Exception('Failed to mark notification as read: $error');
    }
  }

  static WebSocketChannel listenUserNotifications() {
    // return WebSocketChannel.connect(Uri.parse(sampleWebSocketUrl));

    final token = SessionManager().getJwt();
    final url = Uri.parse('$websocketUrl/ws/notifications?token=$token');
    return WebSocketChannel.connect(url);
  }

  //////////////////// Admin APIs /////////////////////////////////

  static Future<CageInit> adminGetCageDetails(String cageId) async {
    Uri url = Uri.parse('$baseUrl/admin/cages/$cageId');
    final response = await http.get(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${SessionManager().getJwt()}'
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return CageInit.fromJson(data);
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Unknown error';
      throw Exception('Failed to get cage details: $error');
    }
  }

  static Future<CageInit> createCage(String cageName, String userid) async {
    Uri url = Uri.parse('$baseUrl/admin/users/$userid/cages');
    final response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${SessionManager().getJwt()}'
      },
      body: jsonEncode(<String, String>{'name_cage': cageName}),
    );
    if (response.statusCode == 201) {
      final Map<String, dynamic> res = jsonDecode(response.body);
      return CageInit.fromJson(res); // Pass the response as CageInit
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Unknown error';
      throw Exception('Failed to create cage: $error');
    }
  }

  static Future<List<UDevice>> getAvailableDevice() async {
    Uri url = Uri.parse('$baseUrl/admin/devices');
    final response = await http.get(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${SessionManager().getJwt()}'
      },
    );
    if (response.statusCode == 200) {
      List<dynamic> devices = jsonDecode(response.body);
      return devices.map((device) => UDevice.fromJson(device)).toList();
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Unknown error';
      throw Exception('Failed to get available devices: $error');
    }
  }

  static Future<List<SensorInit>> getAvailableSensor() async {
    Uri url = Uri.parse('$baseUrl/admin/sensors');
    final response = await http.get(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${SessionManager().getJwt()}'
      },
    );
    if (response.statusCode == 200) {
      List<dynamic> sensors = jsonDecode(response.body);
      return sensors.map((sensor) => SensorInit.fromJson(sensor)).toList();
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Unknown error';
      throw Exception('Failed to get available sensors: $error');
    }
  }

  static Future<Map<String, dynamic>> assignSensorToCage(
      String sensorId, String cageId) async {
    Uri url = Uri.parse('$baseUrl/admin/sensors/$sensorId/cage');
    final response = await http.put(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${SessionManager().getJwt()}'
      },
      body: jsonEncode({
        'cageID': cageId,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Unknown error';
      throw Exception('Failed to assign sensor: $error');
    }
  }

  static Future<Map<String, dynamic>> addDeviceToCage(
      String deviceId, String cageId) async {
    Uri url = Uri.parse('$baseUrl/admin/devices/$deviceId/cage');
    final response = await http.put(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${SessionManager().getJwt()}'
      },
      body: jsonEncode({
        'cageID': cageId,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Unknown error';
      throw Exception('Failed to add device: $error');
    }
  }

  static Future<void> deleteDevice(String cageId, String deviceId) async {
    Uri url = Uri.parse('$baseUrl/admin/devices/$deviceId');
    final response = await http.delete(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${SessionManager().getJwt()}'
      },
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body)['error'] ?? 'Unknown error';
      throw Exception('Failed to delete device: $error');
    }
  }

  static Future<void> deleteCage(String cageId) async {
    Uri url = Uri.parse('$baseUrl/admin/cages/$cageId');
    final response = await http.delete(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${SessionManager().getJwt()}'
      },
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body)['error'] ?? 'Unknown error';
      throw Exception('Failed to delete cage: $error');
    }
  }

  static Future<Map<String, dynamic>> addSensorToCage(
      String cageId, String name, String type) async {
    Uri url = Uri.parse('$baseUrl/admin/cages/$cageId/sensors');
    final response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${SessionManager().getJwt()}'
      },
      body: jsonEncode({'name': name, 'type': type}),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Unknown error';
      throw Exception('Failed to add sensor: $error');
    }
  }

  static Future<void> deleteSensor(String sensorId) async {
    Uri url = Uri.parse('$baseUrl/admin/sensors/$sensorId');
    final response = await http.delete(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${SessionManager().getJwt()}'
      },
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body)['error'] ?? 'Unknown error';
      throw Exception('Failed to delete sensor: $error');
    }
  }

  static Future<List<User>> getAlluser() async {
    Uri url = Uri.parse('$baseUrl/admin/users');
    final response = await http.get(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${SessionManager().getJwt()}'
      },
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      final List<dynamic> usersData = responseData['users'];
      List<User> users =
          usersData.map((dynamic item) => User.fromJson(item)).toList();
      return users;
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Unknown error';
      throw Exception('Failed to load users: $error');
    }
  }

  static Future<void> deleteUser(String userId) async {
    Uri url = Uri.parse('$baseUrl/admin/users/$userId');
    final response = await http.delete(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${SessionManager().getJwt()}'
      },
    );
    if (response.statusCode == 200) {
      return;
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Unknown error';
      throw Exception('Failed to delete user: $error');
    }
  }

  static Future<void> addUser(
      String username, String email, String password, String role) async {
    Uri url = Uri.parse('$baseUrl/admin/auth/register');
    final response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${SessionManager().getJwt()}'
      },
      body: jsonEncode(<String, String>{
        'username': username,
        'email': email,
        'password': password,
        'role': role
      }),
    );

    if (response.statusCode == 201) {
      return;
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Unknown error';
      throw Exception('Failed to create user: $error');
    }
  }

  static Future<List<CageInit>> getUserCage(String userid) async {
    Uri url = Uri.parse('$baseUrl/admin/users/$userid/cages');
    final response = await http.get(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${SessionManager().getJwt()}'
      },
    );
    if (response.statusCode == 200) {
      if (response.body.isEmpty) {
        return []; // Return empty list if response body is empty
      }
      final List<dynamic> body = jsonDecode(response.body);
      List<CageInit> cages = body
          .map(
              (dynamic item) => CageInit.fromJson(item as Map<String, dynamic>))
          .toList();
      return cages;
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Unknown error';
      throw Exception('Failed to load cages: $error');
    }
  }

  Future<ChartResponse> getChartData(
      String cageid, String startDate, String endDate) async {
    // Temporary: Return fake data while API is in development
    return ChartResponse.fromJson({
      "statistics": [
        {"day": "2025-04-21", "value": 35}, // Monday
        {"day": "2025-04-22", "value": 28}, // Tuesday
        {"day": "2025-04-23", "value": 34}, // Wednesday
        {"day": "2025-04-24", "value": 32}, // Thursday
        {"day": "2025-04-25", "value": 40}, // Friday
        {"day": "2025-04-26", "value": 25}, // Saturday
        {"day": "2025-04-27", "value": 30}, // Sunday
      ],
      "summary": {"average": 32.0, "highest": 40.0, "lowest": 25.0}
    });
  }
}
