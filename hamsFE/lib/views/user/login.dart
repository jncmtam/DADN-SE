import 'package:flutter/material.dart';

import '../../controllers/session.dart';
import '../constants.dart';
import '../../controllers/apis.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _email = '';
  String _password = '';
  bool _obscuredText = true;

  void _togglePasswordVisibility() {
    setState(() {
      _obscuredText = !_obscuredText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(30),
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/login-bg.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          child: Column(
            children: [
              // app name
              Padding(
                padding: const EdgeInsets.only(top: 100.0),
                child: Text(
                  'Hamster Care',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 40,
                    color: kBase3,
                  ),
                ),
              ),
              // welcome message
              Container(
                padding: const EdgeInsets.only(top: 80.0, bottom: 10.0),
                alignment: Alignment.topLeft,
                child: Text(
                  'Welcome back!',
                  style: TextStyle(
                    fontSize: 25,
                    color: textPrimary,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    Container(
                      margin: EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 14.0,
                              offset: Offset(0, 9),
                            )
                          ]),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // username input
                          Container(
                            padding: EdgeInsets.all(5.0),
                            decoration: BoxDecoration(
                                border: Border(
                                    bottom: BorderSide(
                                      color: Colors.black.withOpacity(0.2),
                                    )
                                )
                            ),
                            child: TextFormField(
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'email',
                                hintStyle: TextStyle(
                                  color: Color.fromARGB(255, 201, 201, 201),
                                ),
                                prefixIcon: Icon(Icons.person),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _email = value;
                                });
                              },
                            ),
                          ),
                          // password input
                          Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: TextFormField(
                              obscureText: _obscuredText,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintStyle: TextStyle(
                                    color: Color.fromARGB(255, 201, 201, 201)
                                ),
                                hintText: 'password',
                                prefixIcon: Icon(Icons.lock),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscuredText
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: _togglePasswordVisibility,
                                ),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _password = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    // submit button -> call login()
                    TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: loginButton,
                          minimumSize: Size(200, 50),
                        ),
                        onPressed: () async {
                          try {
                            bool success = await APIs.login(_email, _password);
                            if (!context.mounted) return;

                            if (success) {
                              String role = SessionManager().getRole()!;
                              if (role == 'admin') {
                                Navigator.pushReplacementNamed(context, '/admin');
                              } else {
                                Navigator.pushReplacementNamed(context, '/user');
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Wrong email or password'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar( // !!! AlertDialog
                                  content: Text(e.toString()),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        child: Text(
                          'Login',
                          style: TextStyle(
                              fontSize: 20,
                              color: Colors.white
                          ),
                        )),
                    // forget password
                    TextButton(
                      child: Text(
                        'Forgot password?',
                        style: TextStyle(
                          color: textSecondary,
                          fontStyle: FontStyle.italic,
                          // underline same color as text
                          decoration: TextDecoration.underline,
                          decorationColor: textSecondary,
                        ),
                      ),
                      onPressed: () {
                        print('Forget password pressed');
                      },
                    )
                  ],
                ),
              )
              // login form
            ],
          ),
        ),
      ),
    );
  }
}