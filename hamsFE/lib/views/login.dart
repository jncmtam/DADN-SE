import 'package:flutter/material.dart';
import '../controllers/session.dart';
import 'constants.dart';
import '../controllers/apis.dart';
import 'forgot_password.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _email = '';
  String _password = '';

  // String _email = '';
  // String _password = '';
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
                padding: const EdgeInsets.only(top: 80.0),
                child: Text(
                  'Hamster Care',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 40,
                    color: kBase2,
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
                    fontSize: 20,
                    color: lPrimaryText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // wrapper
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    // login form
                    Container(
                      margin: EdgeInsets.only(bottom: 30),
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
                            ))),
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
                                    color: Color.fromARGB(255, 201, 201, 201)),
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
                    ElevatedButton(
                        style: TextButton.styleFrom(
                          backgroundColor: primaryButton,
                          padding: EdgeInsets.symmetric(
                              horizontal: 40, vertical: 10),
                        ),
                        onPressed: () async {
                          try {
                            bool success = await APIs.login(_email, _password);
                            if (!context.mounted) return;

                            if (success) {
                              String role = SessionManager().getRole()!;
                              if (role == 'admin') {
                                Navigator.pushReplacementNamed(
                                    context, '/admin');
                              } else {
                                Navigator.pushReplacementNamed(
                                    context, '/user');
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Wrong email or password'),
                                  backgroundColor: failStatus,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Something went wrong'),
                                  backgroundColor: debugStatus,
                                ),
                              );
                            }
                            debugPrint('Error: $e');
                          }
                        },
                        child: Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 16,
                            color: primaryButtonContent,
                          ),
                        )),
                    // forget password
                    TextButton(
                      child: Text(
                        'Forgot password?',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          decoration: TextDecoration.underline,
                          decorationColor: lSecondaryText,
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ForgetPassword(),
                          ),
                        );
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
