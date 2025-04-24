import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  final _storage = FlutterSecureStorage();
  String? _jwt;
  String? _userId;
  String? _role;

  Future<void> login(String jwt) async {
    _jwt = jwt;
    await _storage.write(key: 'jwt', value: jwt);
    _fetchTokenPayload();
  }

  Future<void> loadToken() async {
    _jwt = await _storage.read(key: 'jwt');
    if (_jwt != null) {
      _fetchTokenPayload();
    }
  }

  void _fetchTokenPayload() async {
    if (_jwt == null) {
      throw Exception('User not logged in');
    }
    if (JwtDecoder.isExpired(_jwt!)) {
      await logout();
    } else {
      final decoded = JwtDecoder.decode(_jwt!);
      _userId = decoded['user_id'];
      _role = decoded['role'];
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt');
    _jwt = null;
    _userId = null;
    _role = null;
  }

  bool isLoggedIn() => _jwt != null;

  String? getRole() => _role;

  String? getUserId() => _userId;

  String? getJwt() => _jwt;
}
