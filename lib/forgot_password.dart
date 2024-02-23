import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:muhammadiyah/change_password.dart';
import 'package:muhammadiyah/login.dart';
import 'package:muhammadiyah/size_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({Key? key}) : super(key: key);

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  TextEditingController nameController = TextEditingController();
  TextEditingController idController = TextEditingController();
  TextEditingController emailController = TextEditingController();

  double keyboardHeight = 0;

  late SharedPreferences sharedPreferences;

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

  void _showPopupMessage(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Pemberitahuan"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  Future<void> checkUserData(BuildContext context) async {
    try {
      final String name = nameController.text;
      final String id = idController.text;
      final String email = emailController.text;

      final QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
          .collection('Pegawai')
          .where('nama', isEqualTo: name)
          .where('id', isEqualTo: id)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (snapshot.size == 0) {
        _showPopupMessage(context, "Data yang anda masukkan salah, silahkan cek kembali!");
        return;
      }

      sharedPreferences = await SharedPreferences.getInstance();

      sharedPreferences.setString("idPegawai", id).then((_) {
        nameController.clear();
        idController.clear();
        emailController.clear();

        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ChangePassword(),
          )
        );
      });

    } catch (error) {
      print("Error checking user data: $error");
      _showPopupMessage(context, "Terjadi kesalahan saat memeriksa data pengguna");
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);

    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: keyboardHeight),
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
                      "Silahkan Masukkan Data Akun Anda!",
                      style: TextStyle(
                        fontSize: SizeConfig.textType!.scale(24),
                        fontWeight: FontWeight.bold,
                      )
                    ),
                  ),
                ],
              ),
            ),
            fieldTitle("NAMA"),
            customField("Masukkan Nama Anda", nameController, false, Icons.person),
            Container(
              height: SizeConfig.blockSizeVertical! * 2,
            ),
            fieldTitle("ID"),
            customField("Masukkan ID Anda", idController, false, Icons.key),
            Container(
              height: SizeConfig.blockSizeVertical! * 2,
            ),
            fieldTitle("EMAIL"),
            customField("Masukkan Email Anda", emailController, false, Icons.email),
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
                    checkUserData(context);
                  },
                  child: SizedBox(
                    width: SizeConfig.blockSizeHorizontal! * 75,
                    height: SizeConfig.blockSizeVertical! * 20,
                    child: Center(
                      child: Text(
                        "LUPA PASSWORD",
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
            Container(
              height: SizeConfig.blockSizeVertical! * 2,
            ),
            Container(
              height: SizeConfig.safeBlockVertical! * 8,
              width: SizeConfig.safeBlockHorizontal! * 75,
              margin: EdgeInsets.only(top: SizeConfig.safeBlockVertical! * 2),
              child: Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 198, 198, 198),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(30)),
                    ),
                  ),
                  onPressed: () {
                    nameController.clear();
                    idController.clear();
                    emailController.clear();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const Login(),
                      ),
                    );
                  },
                  child: SizedBox(
                    width: SizeConfig.blockSizeHorizontal! * 75,
                    height: SizeConfig.blockSizeVertical! * 8,
                    child: Center(
                      child: Text(
                        "KEMBALI",
                        style: TextStyle(
                          fontSize: SizeConfig.textType!.scale(20),
                          color: Colors.black,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        )
      ),
    );
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
      IconData iconData) {
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
            offset: Offset(2, 2),
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}
