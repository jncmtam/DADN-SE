import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hamsFE/controllers/permission.dart';
import '../../controllers/apis.dart';
import '../../models/user.dart';
import '../constants.dart';
import '../utils.dart';
import 'package:image_picker/image_picker.dart';

class UserProfile extends StatefulWidget {
  final User user;
  const UserProfile({super.key, required this.user});

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  late User _user;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
  }

  Future<void> _updateUsername(String newUsername) async {
    try {
      bool success = await APIs.changeUsername(newUsername);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(success ? 'Username updated' : 'Failed to update username'),
          backgroundColor: success ? successStatus : failStatus,
        ),
      );

      if (success) {
        User updatedUser = await APIs.getUserInfo();
        setState(() {
          _user = updatedUser;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Something went wrong'),
          backgroundColor: debugStatus,
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
        automaticallyImplyLeading: false,
        toolbarHeight: 60,
        backgroundColor: kBase2,
        centerTitle: true,
        title: Text(
          'Profile & Settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: kBase0,
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
                child: GestureDetector(
                  onTap: () => _pickAndUploadAvatar(context),
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
              ),
              SizedBox(height: 16),
              // Name
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _user.name,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: lPrimaryText,
                    ),
                  ),
                  SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _showChangeUsernameDialog(context),
                    child: Icon(
                      Icons.edit,
                      color: lPrimaryText,
                      size: 20,
                    ),
                  )
                ],
              ),

              SizedBox(height: 8),
              // Email
              Text(
                _user.email,
                style: TextStyle(
                  fontSize: 16,
                  color: lNormalText,
                ),
              ),
              SizedBox(height: 16),
              // Profile Information
              // Utils.displayInfo('ID', user.id),
              Divider(),
              Utils.displayInfo('Role', _user.role),
              Divider(),
              Utils.displayInfo('Joined on', _user.joinDate),
              Divider(),
              Utils.displayInfo(
                  'Email Verified', _user.emailVerified ? 'Yes' : 'No'),
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
                        padding:
                            EdgeInsets.symmetric(vertical: 12, horizontal: 24),
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
                        padding:
                            EdgeInsets.symmetric(vertical: 12, horizontal: 24),
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
                  bool success =
                      await APIs.changePassword(currentPassword, newPassword);

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

                  debugPrint('Error: $e');
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

  void _showChangeUsernameDialog(BuildContext context) {
    TextEditingController usernameController = TextEditingController();
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Change Username',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: lPrimaryText),
          ),
          content: TextField(
            controller: usernameController,
            decoration: InputDecoration(
              labelText: 'New Username',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: failStatus,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _updateUsername(usernameController.text.trim());
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

  Future<void> _pickAndUploadAvatar(BuildContext context) async {
    bool granted = await requestImagePermission();
    if (!granted) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Permission denied")),
        );
      }
      return;
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    File avatarFile = File(pickedFile.path);
    final fileSize = await avatarFile.length();

    if (fileSize > 5 * 1024 * 1024) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("File size exceeds 5MB")),
        );
        return;
      }
    }

    try {
      await APIs.changeUserAvatar(avatarFile.path);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Avatar updated successfully")),
        );
      }
      if (!mounted) return;

      setState(() {}); // refresh the avatar
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update avatar")),
        );
      }
      debugPrint('Error: $e');
    }
  }
}
