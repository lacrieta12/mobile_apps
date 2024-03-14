import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:muhammadiyah/navbar.dart';
import 'package:muhammadiyah/room_booking.dart';
import 'package:muhammadiyah/size_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class bookingSystem extends StatefulWidget {
  const bookingSystem({super.key});

  @override
  State<bookingSystem> createState() => _bookingSystemState();
}

class _bookingSystemState extends State<bookingSystem> {
  double screenHeight = 0;
  double screenWidth = 0;
  double keyboardHeight = 0;

  Color bgPrimary = const Color.fromARGB(255, 230, 230, 230);

  late SharedPreferences sharedPreferences;

  late StreamSubscription<bool> _keyboardVisibilitySubscription;

  String? _selectedButton;
  String docId = "";
  bool _isFetched = false;

  String b1 = "R001";
  String b2 = "R002";
  String b3 = "R003";
  String b4 = "R004";
  String b5 = "R005";
  String b6 = "R006";
  String? nama_ruangan;
  int? kapasitas;
  List<dynamic> fasilitas = [];
  String ruangan = '';

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

  Future<void> initializeSharedPreferences() async {
    sharedPreferences = await SharedPreferences.getInstance();
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

  void handleButtonTap(String buttonName) async {
    setState(() {
      if (_selectedButton == buttonName) {
        _selectedButton = null; // Toggle off if the same button is tapped again
      } else {
        _selectedButton = buttonName; // Toggle on if a different button is tapped
      }
      _isFetched = true; // Set to true to display circular progress indicator
    });

    switch (buttonName) {
      case "Ruangan A":
        docId = b1;
        ruangan = "lib/assets/images/r1.png";
        break;
      case "Ruangan B":
        docId = b2;
        ruangan = "lib/assets/images/r2.png";
        break;
      case "Ruangan C":
        docId = b3;
        ruangan = "lib/assets/images/r3.png";
        break;
      case "Ruangan D":
        docId = b4;
        ruangan = "lib/assets/images/r4.png";
        break;
      case "Ruangan E":
        docId = b5;
        ruangan = "lib/assets/images/r5.png";
        break;
      case "Ruangan F":
        docId = b6;
        ruangan = "lib/assets/images/r6.png";
        break;
      default:
        docId = "";
        ruangan = "lib/assets/images/r1.png";
    }

    if (docId.isNotEmpty) {
      final DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('RuanganMeeting').doc(docId).get();
      // Extract data from the snapshot and update UI accordingly
      String fetchNamaRuangan = snapshot.get('nama_ruangan');
      int fetchKapasitas = snapshot.get('kapasitas');
      List<dynamic> fetchFasilitas = snapshot.get('fasilitas');

      List<String> modifiedFasilitas = fetchFasilitas.map((item) => "- $item").toList();

      setState(() {
        // Update UI with fetched data
        nama_ruangan = fetchNamaRuangan;
        kapasitas = fetchKapasitas;
        fasilitas = modifiedFasilitas;
        _isFetched = false; // Set to false once data fetching is complete
      });
    } else {
      setState(() {
        nama_ruangan = "";
        kapasitas = 0;
        fasilitas = [];
        _isFetched = false; // Set to false if docId is empty
      });
      print("Doc is not found.");
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const Navbar(),
              ),
            );
          },
        ),
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
        title: const Text('Booking Ruangan'),
        titleTextStyle: TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.white,
        fontSize: 30,
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              SizedBox(
                height: SizeConfig.blockSizeVertical! * 2,
              ),
              Text(
                "Silahkan Pilih Ruangan Meeting!",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(
                height: SizeConfig.blockSizeVertical! * 3,
              ),
              roomButton("Ruangan A", "Ruangan B", "Ruangan C"),
              SizedBox(
                height: SizeConfig.blockSizeVertical! * 2,
              ),
              roomButton("Ruangan D", "Ruangan E", "Ruangan F"),
              SizedBox(
                height: SizeConfig.blockSizeVertical! * 5,
              ),
              if (_selectedButton != null)
                _isFetched
                  ? Column(
                      children: [
                        CircularProgressIndicator(), // Show circular progress indicator
                        SizedBox(
                          height: SizeConfig.blockSizeVertical! * 5,
                        ),
                      ],
                    )
                  : Column(
                    children: [
                      Container(
                        width: SizeConfig.safeBlockHorizontal! * 60,
                        height: SizeConfig.safeBlockHorizontal! * 30,
                        child: Image.asset(
                          ruangan,
                          fit: BoxFit.cover,
                        ),
                      ),
                      SizedBox(
                        height: SizeConfig.blockSizeVertical! * 5,
                      ),
                      Container(
                        width: SizeConfig.blockSizeHorizontal! * 90,
                        height: SizeConfig.blockSizeVertical! * 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.rectangle,
                          color: Colors.transparent,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: SizeConfig.blockSizeHorizontal! * 30,
                              height: SizeConfig.blockSizeVertical! * 5,
                              decoration: BoxDecoration(
                                shape: BoxShape.rectangle,
                              ),
                              child: Text(
                                "RUANGAN",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                            ),
                            Container(
                              width: SizeConfig.blockSizeHorizontal! * 30,
                              height: SizeConfig.blockSizeVertical! * 5,
                              decoration: BoxDecoration(
                                shape: BoxShape.rectangle,
                              ),
                              child: Text(
                                "KAPASITAS",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold
                                ),
                              ),
                            ),
                            Container(
                              width: SizeConfig.blockSizeHorizontal! * 30,
                              height: SizeConfig.blockSizeVertical! * 5,
                              decoration: BoxDecoration(
                                shape: BoxShape.rectangle,
                              ),
                              child: Text(
                                "FASILITAS",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                      Container(
                        width: SizeConfig.blockSizeHorizontal! * 90,
                        height: SizeConfig.blockSizeVertical! * (5 + fasilitas.length * 2),
                        decoration: BoxDecoration(
                          shape: BoxShape.rectangle,
                          color: Colors.transparent,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: SizeConfig.blockSizeHorizontal! * 30,
                              height: SizeConfig.blockSizeVertical! * (5 + fasilitas.length * 2),
                              decoration: BoxDecoration(
                                shape: BoxShape.rectangle,
                              ),
                              child: Text(
                                nama_ruangan ?? "",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16
                                ),
                              ),
                            ),
                            Container(
                              width: SizeConfig.blockSizeHorizontal! * 30,
                              height: SizeConfig.blockSizeVertical! * (5 + fasilitas.length * 2),
                              decoration: BoxDecoration(
                                shape: BoxShape.rectangle,
                                border: Border(
                                  right: BorderSide(color: Color.fromARGB(255, 134, 134, 134)),
                                )
                              ),
                              child: Text(
                                "$kapasitas Orang",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 16
                                ),
                              ),
                            ),
                            Container(
                              width: SizeConfig.blockSizeHorizontal! * 30,
                              height: SizeConfig.blockSizeVertical! * (5 + fasilitas.length * 2),
                              decoration: BoxDecoration(
                                shape: BoxShape.rectangle,
                              ),
                              child: Column(
                                children: List.generate(
                                  fasilitas.length, // Replace yourArray with your actual array variable
                                  (index) => Padding(
                                    padding: EdgeInsets.only(left: SizeConfig.blockSizeHorizontal! * 2),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        fasilitas[index], // Accessing each element of the array
                                        style: TextStyle(
                                          fontSize: 16,
                                        ),
                                        softWrap: true,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: SizeConfig.blockSizeVertical! * 1,
                      ),
                      Text(
                        "Jadwal Hariini xxxxxxxx",
                        style: TextStyle(
                          fontSize: 22,
                        ),
                      ),
                      SizedBox(
                        height: SizeConfig.blockSizeVertical! * 1,
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => RoomBooking(docId: docId, ruangan: ruangan), // Pass the page widget class itself
                            ),
                          );
                        },
                        child: Container(
                          height: SizeConfig.blockSizeVertical! * 5,
                          width: SizeConfig.blockSizeHorizontal! * 25,
                          child: Align(
                            alignment: Alignment.center,
                            child: Text(
                              "Booking!",
                              style: TextStyle(
                                fontSize: 22,
                                color: Colors.black
                              ),
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

  Widget roomButton (
      String room1,
      String room2,
      String room3
      ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        OutlinedButton(
          onPressed: () {
            handleButtonTap(room1);
          },
          style: OutlinedButton.styleFrom(
            backgroundColor: _selectedButton == room1 ? Colors.green : null, // Set the selected button color
          ),
          child: SizedBox(
            width: SizeConfig.blockSizeHorizontal! * 18,
            height: SizeConfig.blockSizeVertical! * 7,
            child: Center(
              child: Text(
                room1,
                style: TextStyle(
                  fontSize: 20,
                  color: _selectedButton == room1 ? Colors.white : null, // Set the selected button text color
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        SizedBox(
          width: SizeConfig.blockSizeHorizontal! * 2,
        ),
        OutlinedButton(
          onPressed: () {
            handleButtonTap(room2);
          },
          style: OutlinedButton.styleFrom(
            backgroundColor: _selectedButton == room2 ? Colors.green : null, // Set the selected button color
          ),
          child: SizedBox(
            width: SizeConfig.blockSizeHorizontal! * 18,
            height: SizeConfig.blockSizeVertical! * 7,
            child: Center(
              child: Text(
                room2,
                style: TextStyle(
                  fontSize: 20,
                  color: _selectedButton == room2 ? Colors.white : null, // Set the selected button text color
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        SizedBox(
          width: SizeConfig.blockSizeHorizontal! * 2,
        ),
        OutlinedButton(
          onPressed: () {
            handleButtonTap(room3);
          },
          style: OutlinedButton.styleFrom(
            backgroundColor: _selectedButton == room3 ? Colors.green : null, // Set the selected button color
          ),
          child: SizedBox(
            width: SizeConfig.blockSizeHorizontal! * 18,
            height: SizeConfig.blockSizeVertical! * 7,
            child: Center(
              child: Text(
                room3,
                style: TextStyle(
                  fontSize: 20,
                  color: _selectedButton == room3 ? Colors.white : null, // Set the selected button text color
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
