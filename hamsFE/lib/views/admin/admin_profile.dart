import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../controllers/apis.dart';
import '../../models/user.dart';
import '../constants.dart';
import '../utils.dart';

class AdminProfile extends StatelessWidget {
  final User user;
  const AdminProfile({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 60,
        backgroundColor: kBase2,
        title: Center(
          child: Text(
            'Profile & Settings',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: kBase0,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              Center(
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: NetworkImage(user.avatarUrl),
                ),
              ),
              SizedBox(height: 16),
              // Name
              Text(
                user.name,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 8),
              // Email
              Text(
                user.email,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              SizedBox(height: 16),
              // Profile Information
              Utils.displayInfo('Role', user.role),
              Divider(),
              Utils.displayInfo('Joined on', user.joinDate),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => _showChangePasswordDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: secondaryButton,
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                ),
                child: Text(
                  'Change Password',
                  style: TextStyle(
                    fontSize: 16,
                    color: secondaryButtonContent,
                  ),
                ),
              ),
              SizedBox(height: 16),
              // Logout Button
              Align(
                alignment: Alignment.bottomCenter,
                child: ElevatedButton(
                  onPressed: () async {
                    await APIs.logout();
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    TextEditingController currentPasswdController = TextEditingController();
    TextEditingController newPasswdController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Change Password',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: primaryText
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswdController,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                ),
              ),
              TextField(
                controller: newPasswdController,
                decoration: InputDecoration(
                  labelText: 'New Password',
                ),
              ),
              // TextField(
              //   controller: TextEditingController(),
              //   decoration: InputDecoration(
              //     labelText: 'Confirm New Password',
              //   ),
              // ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.redAccent,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                String currentPassword = currentPasswdController.text;
                String newPassword = newPasswdController.text;

                try {
                  bool success = await APIs.changePassword(currentPassword, newPassword);

                  if (!context.mounted) return;

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Password changed successfully' : 'Failed to change password'),
                      backgroundColor: success ? successStatus : failStatus,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Something went wrong'),
                      backgroundColor: debugStatus,
                    ),
                  );

                  if (kDebugMode) {
                    print('Error: $e');
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryButton,
              ),
              child: Text(
                'Change',
                style: TextStyle(
                  color: primaryButtonContent,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
