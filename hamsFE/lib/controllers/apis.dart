import 'dart:async';
import 'dart:convert';
import 'package:hamsFE/controllers/session.dart';
import 'package:hamsFE/models/cageinit.dart';
import 'package:http/http.dart' as http;

import '../models/user.dart';
import '../views/constants.dart';

class APIs {
  static const String baseUrl = apiUrl;

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

  // get user information
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

  static Future<bool> changePassword(String currentPassword, String newPassword) async {
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

  static Future<void> resetPassword(String email, String otp, String newPasswd) async {
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
    static Future<void> addUser(String username, String email, String password, String role) async {
    Uri url = Uri.parse('$baseUrl/admin/auth/register');
    final response = await http.post(
      url,
      headers: <String,String> {
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

    if (response.statusCode == 201){
      return;
    }
    else {
      final error = jsonDecode(response.body)['error'] ?? 'Unknown error';
      throw Exception('Failed to create user: $error');
    }
  }

  static Future<List<User>> getAlluser() async {
    Uri url = Uri.parse('$baseUrl/admin/users');
    final response = await http.get(
      url,
      headers: <String,String> {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${SessionManager().getJwt()}'
      },
    );
    if (response.statusCode == 200){
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      final List<dynamic> usersData = responseData['users'];
      List<User> users = usersData.map((dynamic item) => User.fromJson(item)).toList();
      return users;
    }
    else {
      final error = jsonDecode(response.body)['error'] ?? 'Unknown error';
      throw Exception('Failed to load users: $error');
    }
  }

  static Future<void> deleteUser(String userId) async {
    Uri url = Uri.parse('$baseUrl/admin/users/$userId');
    final response = await http.delete(
      url,
      headers: <String,String> {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${SessionManager().getJwt()}'
      },
    );
    if (response.statusCode == 200){
      return;
    }
    else {
      final error = jsonDecode(response.body)['error'] ?? 'Unknown error';
      throw Exception('Failed to delete user: $error');
    }
  }

  static Future<List<CageInit>> getUserCage(String userid) async {
    Uri url = Uri.parse('$baseUrl/admin/users/$userid/cages');
    final response = await http.get(
      url,
      headers: <String,String> {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${SessionManager().getJwt()}'
      },
    );
    if (response.statusCode == 200) {
      if (response.body.isEmpty) {
        return []; // Return empty list if response body is empty
      }
      final List<dynamic> body = jsonDecode(response.body);
      List<CageInit> cages = body.map((dynamic item) => CageInit.fromJson(item as Map<String, dynamic>)).toList();
      return cages;
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Unknown error';
      throw Exception('Failed to load cages: $error');
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
      body: jsonEncode(<String, String>{
        'name_cage': cageName
      }),
    );
    if (response.statusCode == 201) {
      final Map<String, dynamic> res = jsonDecode(response.body);
      return CageInit.fromJson(res); // Pass the response as CageInit
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Unknown error';
      throw Exception('Failed to create cage: $error');
    }
  }
}
