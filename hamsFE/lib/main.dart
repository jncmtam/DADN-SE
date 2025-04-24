import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hamsFE/views/admin/admin_app.dart';
import 'package:hamsFE/views/login.dart';
import 'package:hamsFE/views/user_app.dart';
import 'controllers/session.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Required by FlutterSecureStorage
  await SessionManager().loadToken(); // Load token from storage
  // await SessionManager().logout(); // Load user from storage

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hamster Care IoT',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: GoogleFonts.openSans().fontFamily,
      ),
      routes: {
        '/login': (context) => LoginScreen(),
        '/user': (context) => UserApp(),
        '/admin': (context) => AdminApp(),
      },
      initialRoute: _getInitialScreen(),
    );
  }

  String _getInitialScreen() {
    if (SessionManager().isLoggedIn()) {
      if (SessionManager().getRole() == 'admin') {
        return '/admin';
      } else {
        return '/user';
      }
    } else {
      return '/login';
    }
  }
}