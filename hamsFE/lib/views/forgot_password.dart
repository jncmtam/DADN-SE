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
      builder: (context) {
        return AlertDialog(
          title: Padding(
            padding: EdgeInsets.all(16),
            child: Text('Enter OTP & New Password'),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _otpController,
                decoration: InputDecoration(labelText: 'OTP'),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _newPasswdController,
                obscureText: true,
                decoration: InputDecoration(labelText: 'New Password'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: _sendOTP,
              child: Text('Resend OTP'),
            ),
            ElevatedButton(
              onPressed: () => _resetPassword(email),
              child: Text('Submit'),
            ),
          ],
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to reset password'),
          backgroundColor: debugStatus,
        ),
      );

      debugPrint('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 60,
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
              child: _isSendingOtp
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('Send OTP'),
            ),
          ],
        ),
      ),
    );
  }
}
