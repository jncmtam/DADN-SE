import 'package:flutter/material.dart';
import 'package:hamsFE/models/user.dart';
import 'package:hamsFE/views/constants.dart';
import 'admin_home.dart';
import 'package:hamsFE/controllers/apis.dart';




// text color
// const Color placeholderText = Color.fromARGB(255, 167, 167, 167);
const Color popUp = Color(0xFFEBF4F6);

// card color
// const Color activeTicket = Color(0xFFD7EAF8);
// const Color inactiveTicket = Color(0xFF89A8B2);




class AddUser extends StatefulWidget {
  final User user;
  const AddUser({super.key, required this.user});
  

  @override
  State<AddUser> createState() => _CreateUser();
}
class _CreateUser extends State<AddUser> {
  late final User user;
  String _email = '';
  String _password = '';
  String _username = '';
  String _role = '';
  bool _obscuredText = true;

  void _togglePasswordVisibility() {
    setState(() {
      _obscuredText = !_obscuredText;
    });
  }

  @override
  void initState() {
    super.initState();
    user = widget.user;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBase2,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              color: kBase2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _backbutton(context),
                  Text(
                    'Add user',
                    style: TextStyle(
                      color: kBase0,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 50,)
                ],
              ),
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 20, horizontal: 30),
                decoration: BoxDecoration(
                  color: kBase0,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20))
                ),
                child: SingleChildScrollView(
                  child: _form(context),
                ),
              )
            )
          ],
        )
      ),
    );
  }

  Widget _backbutton(BuildContext context){
    return Container(
      width: 40, // Set the width of the container
      height: 40, 
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: kBase2,
        border: Border.all(color: kBase0, width: 3.5)
      ),
      child: Center(
        child: IconButton(
        onPressed: (){
          Navigator.pop(context, MaterialPageRoute(builder: (context) => AdminHome(user: user)));
      }, 
        icon: Icon(Icons.chevron_left), color: kBase0, 
        iconSize: 30,
        padding: EdgeInsets.zero, // Remove extra padding
        constraints: BoxConstraints(), // Remove constraints
        ),
      )
    );
  }

  Widget _form(BuildContext context){
    return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Username',
                            style: TextStyle(
                              fontWeight: FontWeight.normal,
                            ),
                          ),
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
                                hintText: 'username',
                                hintStyle: TextStyle(
                                  color: Color.fromARGB(255, 201, 201, 201),
                                ),
                                prefixIcon: Icon(Icons.person),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _username = value;
                                });
                              },
                            ),
                          ),
                          SizedBox(height: 10,),
                          // password input
                          Text(
                            'User email',
                            style: TextStyle(
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(5.0),
                            decoration: BoxDecoration(
                                    border: Border(
                                    bottom: BorderSide(
                              color: Colors.black.withOpacity(0.2),
                            ))
                            ),
                            child: TextFormField(
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintStyle: TextStyle(
                                    color: Color.fromARGB(255, 201, 201, 201)),
                                hintText: 'email',
                                prefixIcon: Icon(Icons.mail),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _email = value;
                                });
                              },
                            ),
                          ),
                          SizedBox(height: 10,),
                          // password input
                          Text(
                            'User password',
                            style: TextStyle(
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(5.0),
                            decoration: BoxDecoration(
                                                              border: Border(
                                    bottom: BorderSide(
                              color: Colors.black.withOpacity(0.2),
                            ))
                            ),
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
                          SizedBox(height: 10,),
                          // password input
                          Text(
                            'User role',
                            style: TextStyle(
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(5.0),
                            decoration: BoxDecoration(
                              border: Border(
                                    bottom: BorderSide(
                              color: Colors.black.withOpacity(0.2),
                            ))
                            ),
                            child: TextFormField(
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintStyle: TextStyle(
                                    color: Color.fromARGB(255, 201, 201, 201)),
                                hintText: 'role',
                                prefixIcon:  Icon(Icons.person),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _role = value;
                                });
                              },
                            ),
                          ),
                          SizedBox(height: 30,),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                style: TextButton.styleFrom(
                                  backgroundColor: primaryButton,
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 40, vertical: 10),
                                ),
                                onPressed: () async {
                                  try {
                                    await APIs.addUser(_username, _email, _password, _role);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('User has been created successfully'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    // Navigate back with result true to trigger reload
                                    Navigator.pop(context, true);
                                  } catch (e) {
                                    // Handle error (e.g., show a snackbar)
                                    print('Error adding user: $e');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Failed to add user: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                                child: Text(
                                  'Add user',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: primaryButtonContent,
                                  ),
                                )),
                            ],
                          )
                        ],
                      );
  }
}

