import 'dart:async';

import 'package:bcrypt/bcrypt.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:muhammadiyah/profile_sub/profile_page.dart';
import 'package:muhammadiyah/size_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class editPassword extends StatefulWidget {
  const editPassword({super.key});

  @override
  State<editPassword> createState() => _editPasswordState();
}

class _editPasswordState extends State<editPassword> {
  TextEditingController passController = TextEditingController();
  TextEditingController newPassController = TextEditingController();
  TextEditingController rePassController = TextEditingController();
  double keyboardHeight = 0;

  Color bgPrimary = const Color.fromARGB(255, 230, 230, 230);

  late SharedPreferences sharedPreferences;
  String? passwordLama = '';
  String? passwordBaru = '';
  String? rePasswordBaru = '';

  late StreamSubscription<bool> _keyboardVisibilitySubscription;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    initializeSharedPreferences();
    // Listen to keyboard visibility changes
    _keyboardVisibilitySubscription = KeyboardVisibilityController().onChange.listen((bool isVisible) {
      // Execute the function to handle keyboard visibility after the frame is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        handleKeyboardVisibility(isVisible);
      });
    });
  }

  @override
  void dispose() {
    // Dispose of keyboard visibility subscription
    _keyboardVisibilitySubscription.cancel();
    super.dispose();
  }

  // Function to handle keyboard visibility
  void handleKeyboardVisibility(bool isVisible) {
    // Determine the appropriate bottom padding based on keyboard visibility
    double bottomPadding = isVisible ? MediaQuery.of(context).viewInsets.bottom : 0;

    // Set the bottom padding to the SingleChildScrollView
    // You can replace SingleChildScrollView with your desired widget
    if (mounted) {
      setState(() {
        keyboardHeight = bottomPadding;
      });
    }
  }

  Future<void> initializeSharedPreferences() async {
    sharedPreferences = await SharedPreferences.getInstance();
  }

  void _showBackDialog() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pemberitahuan'),
          content: const Text(
            'Apakah anda yakin ingin meninggalkan halaman ini?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Tidak'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: const Text('Ya'),
              onPressed: () async {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Profile_page(),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);

    return Scaffold(
      backgroundColor: bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _showBackDialog();
          },
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF0172B2),
                Color(0xFF015C8F),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        title: const Text('Ganti Password'),
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 30,
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: keyboardHeight),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              SizedBox(
                height: SizeConfig.blockSizeVertical! * 4,
              ),
              fieldTitle("PASSWORD LAMA"),
              customField("Masukkan Password Lama Anda", passController, true, Icons.key, isPassword: true),
              Container(
                height: SizeConfig.blockSizeVertical! * 2,
              ),
              fieldTitle("PASSWORD BARU"),
              customField("Masukkan Password Baru Anda", newPassController, true, Icons.key, isPassword: true),
              Container(
                height: SizeConfig.blockSizeVertical! * 2,
              ),
              fieldTitle("PASSWORD BARU"),
              customField("Masukkan Kembali Password Baru Anda", rePassController, true, Icons.key, isPassword: true),
              Container(
                height: SizeConfig.blockSizeVertical! * 2,
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white60,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(30)),
                  ),
                ),
                onPressed: () {
                  _changePassword();
                },
                child: SizedBox(
                  width: SizeConfig.blockSizeHorizontal! * 65,
                  height: SizeConfig.blockSizeVertical! * 8,
                  child: Center(
                    child: Text(
                      "Ganti Password",
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.black,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              PopScope(
                canPop: false,
                onPopInvoked: (bool didPop) {
                  if (didPop) {
                    return;
                  }
                  _showBackDialog();
                },
                child: TextButton(
                  onPressed: () {
                    _showBackDialog();
                  },
                  child: const Text(" "),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Update the _updatePassword method to hash and store the password
  Future<void> _updatePassword() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString("idLogin");
    final String password = passController.text;
    final String newPassword = newPassController.text;
    final String rePassword = rePassController.text;

    if (id != null) {
      // Query Firestore to find the document with the matching "id" field
      QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
          .collection('Pegawai')
          .where('id_pegawai', isEqualTo: id)
          .limit(1)
          .get();

      final DocumentSnapshot<Map<String, dynamic>> user = snapshot.docs.first;
      final String correctPasswordHash = user.get('password');

      final bool isPasswordCorrect = BCrypt.checkpw(password, correctPasswordHash);

      // Check if the entered password matches the stored hashed password
      if (password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Silahkan Masukkan Password Lama Anda!'),
          ),
        );
      } else if (!isPasswordCorrect) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password Lama Anda Salah'),
          ),
        );
      } else {
        if (newPassword == rePassword) {
          showDialog<void>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Pemberitahuan'),
                content: const Text(
                  'Apakah anda yakin dengan data yang diubah?',
                ),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Tidak'),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  TextButton(
                    child: const Text('Ya'),
                    onPressed: () async {
                      // Hash the password using bcrypt
                      String hashedPassword = BCrypt.hashpw(newPassController.text, BCrypt.gensalt());

                      // Check if the query returned any documents
                      if (snapshot.docs.isNotEmpty) {
                        // Get the first document from the query result
                        String docId = snapshot.docs.first.id;

                        // Update the password field of the document with the hashed password
                        FirebaseFirestore.instance.collection('Pegawai').doc(docId).update({
                          'password': hashedPassword,
                        }).then((value) {
                          // Update successful
                          passController.clear();
                          newPassController.clear();
                          rePassController.clear();

                          // Close the dialog
                          Navigator.pop(context);

                          showDialog<void>(
                            context: context,
                            barrierDismissible: false,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Berhasil'),
                                content: const Text('Password Berhasil diperbaharui!'),
                                actions: <Widget>[
                                  TextButton(
                                    child: const Text('OK'),
                                    onPressed: () {
                                      // Navigate back to the profile page
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const Profile_page(),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        }).catchError((error) {
                          print("Failed to update password: $error");
                          // Handle error
                        });
                      } else {
                        // Show error message if document with the given "id" is not found
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Document with the provided ID not found.'),
                          ),
                        );
                      }
                    },
                  ),
                ]
              );
            }
          );
        } else {
          // Show error message if passwords don't match
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password Tidak Sama.'),
            ),
          );
        }
      }
    }
  }

  void _changePassword() {
    if (_formKey.currentState!.validate()) {
      // Perform password change logic here
      if (newPassController.text == rePassController.text) {
        _updatePassword();
      } else {
        // Show error message if passwords don't match
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password Baru Anda Tidak Sama.'),
          ),
        );
      }
    }
  }

  Widget fieldTitle(String title) {
    SizeConfig().init(context);

    return Container(
      margin: EdgeInsets.only(
        bottom: SizeConfig.blockSizeVertical! * 2,
      ),
      child: Align(
        alignment: Alignment(
            SizeConfig.blockSizeHorizontal! * -0.21,
            0
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget customField(
      String hint,
      TextEditingController controller,
      bool obscure,
      IconData iconData,
      {bool isPassword = false}
      ) {
    SizeConfig().init(context);

    return Container(
      width: SizeConfig.blockSizeHorizontal! * 90,
      margin: EdgeInsets.only(
        bottom: SizeConfig.blockSizeVertical! * 2,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(SizeConfig.blockSizeVertical! * 2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: SizeConfig.blockSizeVertical! * 2,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: SizeConfig.blockSizeHorizontal! * 18,
            child: Icon(
              iconData,
              color: const Color(0xFF001645),
              size: SizeConfig.blockSizeHorizontal! * 7,
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                  right: SizeConfig.blockSizeHorizontal! * 7
              ),
              child: TextFormField(
                controller: controller,
                enableSuggestions: false,
                autocorrect: false,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    vertical: SizeConfig.blockSizeVertical! * 3,
                  ),
                  border: InputBorder.none,
                  hintText: hint,
                ),
                maxLines: 1,
                obscureText: obscure,
                validator: isPassword ? _validatePassword : _validateRePassword,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Add validation logic for password length
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  // Add validation logic to ensure re-entered password matches original password
  String? _validateRePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please re-enter your password';
    }
    if (value != passController.text) {
      return 'Passwords do not match';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }
}
