import 'package:flutter/material.dart';
import 'package:hamsFE/views/constants.dart';

import '../controllers/apis.dart';

class ForgetPassword extends StatefulWidget {
  const ForgetPassword({super.key});

  @override
  State<ForgetPassword> createState() => _ForgetPasswordState();
}

class _ForgetPasswordState extends State<ForgetPassword> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPasswdController = TextEditingController();
  bool _isSendingOtp = false;

  void _sendOTP() async {
    setState(() {
      _isSendingOtp = true;
    });

    String email = _emailController.text.trim();
    try {
      await APIs.forgotPassword(email);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('OTP sent to $email'),
          backgroundColor: successStatus,
        ),
      );

      _showOTPDialog(email);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send OTP'),
          backgroundColor: debugStatus,
        ),
      );

      debugPrint('Error: $e');
    } finally {
      setState(() {
        _isSendingOtp = false;
      });
    }
  }

  void _showOTPDialog(String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          title: const Text('Reset Password'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _otpController,
                  decoration: const InputDecoration(
                    labelText: 'OTP',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _newPasswdController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: TextButton(
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: failStatus,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _resetPassword(email),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryButton,
                          padding: EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: const Text(
                          'Submit',
                          style: TextStyle(
                            color: primaryButtonContent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _resetPassword(String email) async {
    String otp = _otpController.text.trim();
    String newPassword = _newPasswdController.text.trim();

    try {
      await APIs.resetPassword(email, otp, newPassword);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password reset successfully'),
          backgroundColor: successStatus,
        ),
      );

      Navigator.pop(context);

      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to reset password'),
          backgroundColor: failStatus,
        ),
      );

      debugPrint('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lappBackground,
      appBar: AppBar(
        toolbarHeight: lAppBarHeight,
        backgroundColor: kBase2,
        title: Text(
          'Forget Password',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: kBase0,
          ),
        ),
        leading: IconButton(
          color: kBase0,
          icon: Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Enter your email',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSendingOtp ? null : _sendOTP,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryButton,
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              ),
              child: _isSendingOtp
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'Send OTP',
                      style: TextStyle(color: primaryButtonContent),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
