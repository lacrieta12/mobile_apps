import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:muhammadiyah/login.dart';
import 'package:muhammadiyah/size_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChangePassword extends StatefulWidget {
  const ChangePassword({Key? key}) : super(key: key);

  @override
  State<ChangePassword> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
  TextEditingController passController = TextEditingController();
  TextEditingController rePassController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  double keyboardHeight = 0;

  late Future<SharedPreferences> _sharedPreferences;

  late StreamSubscription<bool> _keyboardVisibilitySubscription;

  @override
  void initState() {
    super.initState();
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

  Future<void> _showBackDialog() async {
    final SharedPreferences prefs = await _sharedPreferences;

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
                await prefs.remove("idPegawai");
                passController.clear();
                rePassController.clear();

                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Login(),
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
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: keyboardHeight),
        child: FutureBuilder<SharedPreferences>(
          future: _sharedPreferences,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            return Form(
              key: _formKey,
              child: Column(
                children: [
                  SizedBox(
                    height: SizeConfig.blockSizeVertical! * 20,
                    width: SizeConfig.blockSizeVertical! * 100,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          top: (SizeConfig.blockSizeVertical! * 0) - (SizeConfig.blockSizeHorizontal! * 1),
                          left: SizeConfig.blockSizeHorizontal! * 0,
                          child: Image.asset(
                            'lib/assets/images/blue_shape.png',
                            width: SizeConfig.blockSizeHorizontal! * 25,
                            height: SizeConfig.blockSizeHorizontal! * 25,
                          ),
                        ),
                        Positioned(
                          top: SizeConfig.blockSizeVertical! * 10,
                          child: Text(
                              "Silahkan Masukkan Password Baru Anda!",
                              style: TextStyle(
                                fontSize: SizeConfig.textType!.scale(24),
                                fontWeight: FontWeight.bold,
                              )
                          ),
                        ),
                      ],
                    ),
                  ),
                  fieldTitle("PASSWORD"),
                  customField("Masukkan Password Baru Anda", passController, true, Icons.key, isPassword: true),
                  Container(
                    height: SizeConfig.blockSizeVertical! * 2,
                  ),
                  fieldTitle("PASSWORD"),
                  customField("Masukkan Kembali Password Baru Anda", rePassController, true, Icons.key, isPassword: true),
                  Container(
                    height: SizeConfig.safeBlockVertical! * 8,
                    width: SizeConfig.safeBlockHorizontal! * 75,
                    margin: EdgeInsets.only(top: SizeConfig.safeBlockVertical! * 2),
                    child: Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0172B2),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(30)),
                          ),
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Konfirmasi'),
                              content: const Text('Apakah Anda yakin ingin mengganti password?'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    _changePassword();
                                  },
                                  child: const Text('Ya'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('Tidak'),
                                ),
                              ],
                            ),
                          );
                        },
                        child: SizedBox(
                          width: SizeConfig.blockSizeHorizontal! * 75,
                          height: SizeConfig.blockSizeVertical! * 20,
                          child: Center(
                            child: Text(
                              "GANTI PASSWORD",
                              style: TextStyle(
                                fontSize: SizeConfig.textType!.scale(20),
                                color: Colors.white,
                                letterSpacing: 2,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
            );
          },
        ),
      ),
    );
  }

  Future<void> _updatePassword() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString("idPegawai");

    if (id != null) {
      if (passController.text == rePassController.text) {
        // Query Firestore to find the document with the matching "id" field
        QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
            .collection('Pegawai')
            .where('id', isEqualTo: id)
            .limit(1)
            .get();

        // Check if the query returned any documents
        if (snapshot.docs.isNotEmpty) {
          // Get the first document from the query result
          String docId = snapshot.docs.first.id;

          // Update the password field of the document
          FirebaseFirestore.instance.collection('Pegawai').doc(docId).update({
            'password': passController.text,
          }).then((value) {
            // Update successful
            prefs.remove("idPegawai");
            passController.clear();
            rePassController.clear();

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const Login(),
              ),
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
      } else {
        // Show error message if passwords don't match
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Passwords do not match.'),
          ),
        );
      }
    }
  }

  void _changePassword() {
    if (_formKey.currentState!.validate()) {
      // Perform password change logic here
      if (passController.text == rePassController.text) {
        _updatePassword();
        // If successful, navigate back to Login page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const Login(),
          ),
        );
      } else {
        // Show error message if passwords don't match
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Passwords do not match.'),
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
            fontSize: SizeConfig.blockSizeVertical! * 2.5,
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
