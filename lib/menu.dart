import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:muhammadiyah/absent_recap.dart';
import 'package:muhammadiyah/booking.dart';
import 'package:muhammadiyah/navbar.dart';
import 'package:muhammadiyah/people_location.dart';
import 'package:muhammadiyah/size_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Menu extends StatefulWidget {
  const Menu({super.key});

  @override
  State<Menu> createState() => _MenuState();
}

class _MenuState extends State<Menu> {
  double screenHeight = 0;
  double screenWidth = 0;
  double keyboardHeight = 0;

  Color bgPrimary = const Color.fromARGB(255, 230, 230, 230);

  late SharedPreferences sharedPreferences;

  late StreamSubscription<bool> _keyboardVisibilitySubscription;

  bool isPresent = false;

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
    setState(() {
      isPresent = sharedPreferences.getBool("isPresent")!;
    });
  }

  @override
  void dispose() {
    // Dispose of keyboard visibility subscription
    _keyboardVisibilitySubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);

    return Scaffold(
      backgroundColor: bgPrimary,
      appBar: AppBar(
        backgroundColor: bgPrimary,
        automaticallyImplyLeading: false,
        title: const Text('Menu'),
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black,
          fontSize: 30,
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: keyboardHeight),
        child: Column(
          children: [
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  buttonCustomized(
                    context,
                    Icons.computer_sharp,
                    const absentRecap(),
                    "Absensi",
                    "Hariini : ",
                    isPresent ? "Sudah Absen" : "Belum Absen",
                    isPresent ? Colors.red : Colors.black
                  ),
                  SizedBox(
                    width: SizeConfig.blockSizeHorizontal! * 3,
                  ),
                  buttonCustomized(
                    context,
                    Icons.pending_actions,
                    const Navbar(),
                    "KPI",
                    "Status KPI : ",
                    isPresent ? "Sudah input" : "Belum input",
                    isPresent ? Colors.red : Colors.black
                  ),
                ],
              ),
            ),
            SizedBox(
              height: SizeConfig.blockSizeVertical! * 3,
            ),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  buttonCustomized(
                    context,
                    Icons.person_pin_circle_outlined,
                    const Location(),
                    "Lokasi Eksekutif",
                    "Cek Lokasi Eksekutif",
                    " ",
                    Colors.black
                  ),
                  SizedBox(
                    width: SizeConfig.blockSizeHorizontal! * 3,
                  ),
                  buttonCustomized(
                    context,
                    Icons.meeting_room,
                    const bookingSystem(),
                    "Ruang Meeting",
                    "Cek Ketersediaan Ruangan",
                    " ",
                    Colors.black
                  ),
                ],
              ),
            ),
            SizedBox(
              height: SizeConfig.blockSizeVertical! * 3,
            ),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  buttonCustomized(
                    context,
                    Icons.computer_sharp,
                    const Navbar(),
                    "Absensi",
                    "Absensi Hariini : Sudah / Belum",
                    " ",
                    Colors.black
                  ),
                  SizedBox(
                    width: SizeConfig.blockSizeHorizontal! * 3,
                  ),
                  buttonCustomized(
                    context,
                    Icons.pending_actions,
                    const Navbar(),
                    "KPI",
                    "Status KPI",
                    " ",
                    Colors.black
                  ),
                ],
              ),
            ),
            SizedBox(
              height: SizeConfig.blockSizeVertical! * 3,
            ),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  buttonCustomized(
                    context,
                    Icons.computer_sharp,
                    const Navbar(),
                    "Absensi",
                    "Absensi Hariini : Sudah / Belum",
                    " ",
                    Colors.black
                  ),
                  SizedBox(
                    width: SizeConfig.blockSizeHorizontal! * 3,
                  ),
                  buttonCustomized(
                    context,
                    Icons.pending_actions,
                    const Navbar(),
                    "KPI",
                    "Status KPI",
                    " ",
                    Colors.black
                  ),
                ],
              ),
            ),
            SizedBox(
              height: SizeConfig.blockSizeVertical! * 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget buttonCustomized(BuildContext context, IconData iconData, Widget page, String title, String message, String message2, Color fontColor) {
    SizeConfig().init(context);

    return Container(
      height: SizeConfig.blockSizeHorizontal! * 40,
      width : SizeConfig.blockSizeHorizontal! * 45,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFFFFF), // Start color
            Color(0xFFCEF8F2), // End color
          ],
        ),
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(30)),
          ),
        ),
        onPressed: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => page, // Pass the page widget class itself
            ),
          );
        },
        child: Center(
          child: Column(
            children: [
              SizedBox(
                height: SizeConfig.blockSizeVertical! * 1,
              ),
              Icon(
                iconData,
                color: Colors.blueAccent,
                size: SizeConfig.blockSizeHorizontal! * 12,
              ),
              SizedBox(
                height: SizeConfig.blockSizeVertical! * 2,
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 22,
                  color: Colors.black,
                ),
              ),
              SizedBox(
                height: SizeConfig.blockSizeVertical! * 3,
              ),
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black, // Default color for the text
                  ),
                  children: [
                    TextSpan(
                      text: message, // First part of the text
                    ),
                    TextSpan(
                      text: message2, // Second part of the text
                      style: TextStyle(
                        color: fontColor, // Color for the second part of the text
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
