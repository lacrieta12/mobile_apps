import 'dart:async';

import 'package:bcrypt/bcrypt.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:muhammadiyah/forgot_password.dart';
import 'package:muhammadiyah/navbar.dart';
import 'package:muhammadiyah/new_account.dart';
import 'package:muhammadiyah/size_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Login extends StatefulWidget{
  const Login({Key? key}) : super(key: key);

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  TextEditingController idController = TextEditingController();
  TextEditingController passController = TextEditingController();

  double screenHeight = 0;
  double screenWidth = 0;
  double keyboardHeight = 0;

  late SharedPreferences sharedPreferences;

  void _showPopupMessage(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Pemberitahuan"),
          content: Text(
              message,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Saya Mengerti"),
            ),
          ],
        );
      },
    );
  }

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

  Future<void> signIn(BuildContext context) async {
    try {
      final String id = idController.text;
      final String password = passController.text;

      final QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
          .collection('Pegawai')
          .where('id_pegawai', isEqualTo: id)
          .limit(1)
          .get();

      if (snapshot.size == 0) {
        _showPopupMessage(context, "ID tidak ditemukan");
        return;
      }

      final DocumentSnapshot<Map<String, dynamic>> user = snapshot.docs.first;
      final String correctPasswordHash = user.get('password');
      final bool isDefaultPassword = correctPasswordHash == '12345678';

      if (isDefaultPassword) {
        final String idLogin = user.get('id_pegawai');
        sharedPreferences = await SharedPreferences.getInstance();
        sharedPreferences.setString("idLogin", idLogin);
        // Redirect to the new account page for changing the default password
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const NewAccount()),
        );
        return;
      }
      // Check if the entered password matches the stored hashed password
      final bool isPasswordCorrect = BCrypt.checkpw(password, correctPasswordHash);
      if (!isPasswordCorrect) {
        _showPopupMessage(context, "Password salah");
        return;
      }

      // Get all user data
      final String idLogin = user.get('id_pegawai');
      final String nama = user.get('nama');
      final String email = user.get('email');
      final String jabatan = user.get('jabatan');
      final String departemen = user.get('departemen');
      final String fotoUrl = user.get('foto');

      sharedPreferences = await SharedPreferences.getInstance();

      // Save all user data in shared preferences
      sharedPreferences.setString("idLogin", idLogin);
      sharedPreferences.setString("nama", nama);
      sharedPreferences.setString("email", email);
      sharedPreferences.setString("jabatan", jabatan);
      sharedPreferences.setString("departemen", departemen);
      sharedPreferences.setString("fotoUrl", fotoUrl);

      // Navigate to Home page if login is successful
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Navbar()),
      );

    } catch (error) {
      print("Error signing in: $error");
      _showPopupMessage(context, "Terjadi kesalahan saat login");
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: keyboardHeight),
        child: Center(
          child: Column(
            children: [
              SizedBox(
                height: SizeConfig.blockSizeVertical! * 45,
                width: SizeConfig.blockSizeHorizontal! * 100,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      top: SizeConfig.blockSizeVertical! * 7,
                      child: Text(
                        "Selamat Datang Kembali!",
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Positioned(
                      top: SizeConfig.blockSizeVertical! * -1,
                      left: SizeConfig.blockSizeHorizontal! * 0,
                      child: Image.asset(
                        'lib/assets/images/blue_shape.png',
                        width: SizeConfig.blockSizeHorizontal! * 25,
                        height: SizeConfig.blockSizeHorizontal! * 25,
                      ),
                    ),
                    Positioned(
                      top: SizeConfig.blockSizeVertical! * 15,
                      left: SizeConfig.blockSizeHorizontal! * 28,
                      child: Image.asset(
                        'lib/assets/images/handphone_icon.png',
                        width: SizeConfig.blockSizeHorizontal! * 50,
                      ),
                    ),
                  ],
                ),
              ),
              fieldTitle("ID"),
              customField("Masukkan ID anda.", idController, false, Icons.person),
              Container(
                height: SizeConfig.blockSizeVertical! * 2,
              ),
              fieldTitle("PASSWORD"),
              customField("Masukkan Password anda.", passController, true, Icons.key),
              Container(
                height: SizeConfig.blockSizeVertical! * 2,
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ForgotPassword(),
                    ),
                  );
                  _showPopupMessage(context, "Halaman lupa password bisa diakses untuk yang masih mengetahui data dari nama, ID, dan email akun. Jika ada salah satu data tidak diketahui / lupa, silahkan hubungi bagian IT untuk mengembalikan akses ke akun anda.");
                },
                child: Text(
                  "Lupa Password?",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.blue, // Change color to indicate it's clickable
                  ),
                ),
              ),
              Container(
                height: SizeConfig.blockSizeVertical! * 10,
                width: SizeConfig.blockSizeHorizontal! * 85,
                margin: EdgeInsets.only(top: SizeConfig.blockSizeVertical! * 2),
                child: Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0172B2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(SizeConfig.blockSizeVertical! * 10)),
                      ),
                    ),
                    onPressed: () async {
                      await signIn(context);
                    },
                    child: SizedBox(
                      width: double.infinity,
                      height: SizeConfig.blockSizeVertical! * 9,
                      child: Center(
                        child: Text(
                          "MASUK",
                          style: TextStyle(
                            fontSize: 22,
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
            ],
          ),
        ),
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
            fontSize: 18,
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}