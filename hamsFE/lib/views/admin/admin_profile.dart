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
      backgroundColor: lappBackground,
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
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              Center(
                child: FutureBuilder(
                  future: APIs.getUserAvatar(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircleAvatar(
                        radius: 70,
                        backgroundColor: lcardBackground,
                        child: CircularProgressIndicator(),
                      );
                    } else if (snapshot.hasError) {
                      return CircleAvatar(
                        radius: 70,
                        backgroundColor: lcardBackground,
                        child: Icon(Icons.error),
                      );
                    } else {
                      return ClipOval(
                        child: Image.memory(
                          snapshot.data!,
                          width: 140,
                          height: 140,
                          fit: BoxFit.fill,
                        ),
                      );
                    }
                  },
                ),
              ),
              SizedBox(height: 16),
              // Name
              Text(
                user.name,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: lPrimaryText,
                ),
              ),
              SizedBox(height: 8),
              // Email
              Text(
                user.email,
                style: TextStyle(
                  fontSize: 16,
                  color: lNormalText,
                ),
              ),
              SizedBox(height: 16),
              // Profile Information
              Divider(),
              Utils.displayInfo('Role', user.role),
              Divider(),
              Utils.displayInfo('Joined on', user.joinDate),
              Divider(),
              Utils.displayInfo(
                  'Email Verified', user.emailVerified ? 'Yes' : 'No'),
              Divider(),
              Row(
                children: [
                  // Change Password Button
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => _showChangePasswordDialog(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: secondaryButton,
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Change Password',
                        style: TextStyle(
                          fontSize: 16,
                          color: secondaryButtonContent,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  // Logout Button
                  Expanded(
                    flex: 1,
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
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Change Password',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: lPrimaryText),
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
                      content: Text(success
                          ? 'Password changed successfully'
                          : 'Failed to change password'),
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
