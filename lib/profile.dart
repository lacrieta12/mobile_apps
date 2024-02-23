import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:muhammadiyah/login.dart';
import 'package:muhammadiyah/profile_sub/profile_page.dart';
import 'package:muhammadiyah/size_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  double screenHeight = 0;
  double screenWidth = 0;
  double keyboardHeight = 0;

  Color bgPrimary = const Color.fromARGB(255, 230, 230, 230);

  late SharedPreferences sharedPreferences;
  String? nama = '';
  String? jabatan = '';
  String? departemen = '';

  late StreamSubscription<bool> _keyboardVisibilitySubscription;

  @override
  void initState() {
    super.initState();
    initializeSharedPreferences();
    fetchData();
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

  Future<void> initializeSharedPreferences() async {
    sharedPreferences = await SharedPreferences.getInstance();
    setState(() {
      nama = sharedPreferences.getString("nama");
      jabatan = sharedPreferences.getString("jabatan");
      departemen = sharedPreferences.getString("departemen");
    });
  }

  Future<void> fetchData() async {
    try {
      sharedPreferences = await SharedPreferences.getInstance();
      final String? idLogin = sharedPreferences.getString('idLogin');
      nama = sharedPreferences.getString("nama");

      if (idLogin != null) {
        final QuerySnapshot<Map<String, dynamic>> snapshot =
        await FirebaseFirestore.instance.collection('Pegawai').where('id', isEqualTo: idLogin).get();

        final DocumentSnapshot<Map<String, dynamic>> user = snapshot.docs.first;

        nama = user.get('nama');
        jabatan = user.get('jabatan');
        departemen = user.get('departemen');

        } else {
          print('No data found for idLogin: $idLogin');
        }
      } catch (error) {
        print('Error fetching data: $error');
      }
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

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;
    SizeConfig().init(context);

    return Scaffold(
      backgroundColor: bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
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
        title: const Text('Lainnya'),
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: SizeConfig.textType!.scale(34),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: keyboardHeight),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  height: SizeConfig.blockSizeVertical! * 10,
                  width: SizeConfig.blockSizeHorizontal! * 100,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF015C8F), // Start color
                        Color(0xFF001645), // End color
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: SizeConfig.blockSizeVertical! * 25,
                  width: SizeConfig.blockSizeHorizontal! * 100,
                  decoration: const BoxDecoration(
                    shape: BoxShape.rectangle,
                    color: Colors.transparent,
                  ),
                ),
                Positioned(
                  left: SizeConfig.safeBlockHorizontal! * 7,
                  top: SizeConfig.blockSizeVertical! * 1.5,
                  child: Container(
                    height: SizeConfig.safeBlockHorizontal! * 25,
                    width: SizeConfig.safeBlockHorizontal! * 25,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: SizeConfig.blockSizeHorizontal! * 1,
                      ),
                    ),
                    child: Hero(
                      tag: "profilePhoto",
                      child: ClipOval(
                        child: Image.asset(
                          "lib/assets/images/profpic.png",
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: SizeConfig.safeBlockHorizontal! * 3,
                  top: SizeConfig.blockSizeVertical! * 16,
                  child: Text(
                    nama ?? 'NAMA',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: SizeConfig.textType!.scale(26),
                    ),
                  ),
                ),
                Positioned(
                  left: SizeConfig.safeBlockHorizontal! * 3,
                  top: SizeConfig.blockSizeVertical! * 19,
                  child: Text(
                    jabatan ?? "JABATAN",
                    style: TextStyle(
                      fontSize: SizeConfig.textType!.scale(22),
                    ),
                  ),
                ),
                Positioned(
                  left: SizeConfig.safeBlockHorizontal! * 3,
                  top: SizeConfig.blockSizeVertical! * 21,
                  child: Text(
                    departemen ?? "departemen",
                    style: TextStyle(
                      fontSize: SizeConfig.textType!.scale(22),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: SizeConfig.blockSizeVertical! * 3,
            ),
            ListTile(
              leading: Container(
                height: SizeConfig.blockSizeHorizontal! * 8,
                width: SizeConfig.blockSizeHorizontal! * 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF29C08B),
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                ),
              ),
              title: Text(
                'Profil Saya',
                style: TextStyle(
                  fontSize: SizeConfig.textType!.scale(24),
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => Profile_page(), // Pass the page widget class itself
                  ),
                );
              },
            ),
            Divider(
              height: SizeConfig.blockSizeVertical! * 3,
            ),
            ListTile(
              leading: Container(
                height: SizeConfig.blockSizeHorizontal! * 8,
                width: SizeConfig.blockSizeHorizontal! * 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF29C08B),
                ),
                child: const Icon(
                  Icons.settings,
                  color: Colors.white,
                ),
              ),
              title: Text(
                'Pengaturan',
                style: TextStyle(
                  fontSize: SizeConfig.textType!.scale(24),
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // Navigate to the Settings page
              },
            ),
            Divider(
              height: SizeConfig.blockSizeVertical! * 3,
            ),
            ListTile(
              leading: Container(
                height: SizeConfig.blockSizeHorizontal! * 8,
                width: SizeConfig.blockSizeHorizontal! * 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF29C08B),
                ),
                child: const Icon(
                  Icons.policy,
                  color: Colors.white,
                ),
              ),
              title: Text(
                'Syarat & ketentuan',
                style: TextStyle(
                  fontSize: SizeConfig.textType!.scale(24),
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // Navigate to the Terms & Conditions page
              },
            ),
            Divider(
              height: SizeConfig.blockSizeVertical! * 3,
            ),
            ListTile(
              leading: Container(
                height: SizeConfig.blockSizeHorizontal! * 8,
                width: SizeConfig.blockSizeHorizontal! * 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF29C08B),
                ),
                child: const Icon(
                  Icons.privacy_tip,
                  color: Colors.white,
                ),
              ),
              title: Text(
                'Pengaturan Privasi',
                style: TextStyle(
                  fontSize: SizeConfig.textType!.scale(24),
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // Navigate to the Privacy Policy page
              },
            ),
            Divider(
              height: SizeConfig.blockSizeVertical! * 3,
            ),
            ListTile(
              leading: Container(
                height: SizeConfig.blockSizeHorizontal! * 8,
                width: SizeConfig.blockSizeHorizontal! * 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF29C08B),
                ),
                child: const Icon(
                  Icons.logout,
                  color: Colors.white,
                ),
              ),
              title: Text(
                'Keluar',
                style: TextStyle(
                  fontSize: SizeConfig.textType!.scale(24),
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () async {
                _showLogoutDialog();
              },
            ),
            Divider(
              height: SizeConfig.blockSizeVertical! * 3,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showLogoutDialog() async {
    sharedPreferences = await SharedPreferences.getInstance();

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pemberitahuan Keluar'),
          content: const Text(
            'Apakah anda yakin ingin keluar?',
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
                await sharedPreferences.clear();
                await Future.delayed(const Duration(seconds: 2));

                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const Login()),
                      (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        );
      },
    );
  }
}
