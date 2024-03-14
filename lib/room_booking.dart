import 'dart:async';
import 'package:intl/intl.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:muhammadiyah/booking.dart';
import 'package:muhammadiyah/size_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RoomBooking extends StatefulWidget {
  final String docId;
  final String ruangan;

  const RoomBooking({Key? key, required this.docId, required this.ruangan}) : super(key: key);

  @override
  State<RoomBooking> createState() => _RoomBookingState();
}

class _RoomBookingState extends State<RoomBooking> {
  double screenHeight = 0;
  double screenWidth = 0;
  double keyboardHeight = 0;

  Color bgPrimary = const Color.fromARGB(255, 230, 230, 230);

  late SharedPreferences sharedPreferences;

  late StreamSubscription<bool> _keyboardVisibilitySubscription;

  String? nama_ruangan;
  int? kapasitas;
  List<dynamic> fasilitas = [];
  bool _isFetched = false;
  DateTime? selectedDate;

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

  Future<void> fetchData() async {
    if (widget.docId.isNotEmpty) {
      final DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('RuanganMeeting').doc(widget.docId).get();
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
        _isFetched = true;
      });
    } else {
      setState(() {
        nama_ruangan = "";
        kapasitas = 0;
        fasilitas = [];
        _isFetched = false;
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
                builder: (context) => const bookingSystem(),
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
      body: _isFetched
          ? content()
          : FutureBuilder<void>(
              future: Future.wait([
                fetchData(),
              ]),
              builder: (context, AsyncSnapshot<void> snapshot) {
                if (snapshot.hasData) {
                  _isFetched = true;
                  return content();
                } else {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }
              }
      )
    );
  }

  Widget content() {
    SizeConfig().init(context);

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: Center(
        child: Column(
          children: [
            SizedBox(
              height: SizeConfig.blockSizeVertical! * 5,
            ),
            Container(
              width: SizeConfig.safeBlockHorizontal! * 60,
              height: SizeConfig.safeBlockHorizontal! * 30,
              child: Image.asset(
                widget.ruangan,
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
              height: SizeConfig.blockSizeVertical! * 1.5,
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20),
              width: SizeConfig.blockSizeHorizontal! * 60,
              height: SizeConfig.blockSizeVertical! * 5,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.black
                )
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(Icons.calendar_today, color: Colors.blue),
                  Text(
                    selectedDate == null ? 'Pilih Tanggal' : DateFormat('dd / MM / yyyy').format(selectedDate!),
                    style: TextStyle(fontSize: 18, color: Colors.black),
                  ),
                  IconButton(
                    onPressed: () => _selectDate(context),
                    icon: Icon(Icons.arrow_drop_down, color: Colors.blue),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: SizeConfig.blockSizeVertical! * 1.5,
            ),
            Text(
              "KETERSEDIAAN RUANGAN",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(
              height: SizeConfig.blockSizeVertical! * 1,
            ),
            if (selectedDate != null)
              Container(
                width: SizeConfig.blockSizeHorizontal! * 90,
                height: SizeConfig.blockSizeVertical! * 35,
                child: Column(
                  children: [
                    clockButton("08:00", "09:00", "10:00"),
                    clockButton("11:00", "12:00", "13:00"),
                    clockButton("14:00", "15:00", "16:00"),
                    clockButton("17:00", "18:00", "19:00"),
                    clockButton("20:00", "21:00", "22:00"),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)), // 1 year from now
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue, // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: Colors.black, // Calendar text color
            ),
            dialogBackgroundColor: Colors.white, // Background color
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null && pickedDate != selectedDate) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  Widget clockButton(String hours, String hours2, String hours3) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          OutlinedButton(
            onPressed: () {

            },
            style: OutlinedButton.styleFrom(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
            ),
            child: SizedBox(
              width: SizeConfig.blockSizeHorizontal! * 11,
              height: SizeConfig.blockSizeVertical! * 4,
              child: Center(
                child: Text(
                  hours,
                  style: TextStyle(
                      fontSize: 18,
                      color: Colors.black
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          SizedBox(
            width: SizeConfig.blockSizeHorizontal! * 2.5
          ),
          OutlinedButton(
            onPressed: () {

            },
            style: OutlinedButton.styleFrom(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
            ),
            child: SizedBox(
              width: SizeConfig.blockSizeHorizontal! * 11,
              height: SizeConfig.blockSizeVertical! * 4,
              child: Center(
                child: Text(
                  hours2,
                  style: TextStyle(
                      fontSize: 18,
                      color: Colors.black
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          SizedBox(
              width: SizeConfig.blockSizeHorizontal! * 2.5
          ),
          OutlinedButton(
            onPressed: () {

            },
            style: OutlinedButton.styleFrom(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
            ),
            child: SizedBox(
              width: SizeConfig.blockSizeHorizontal! * 11,
              height: SizeConfig.blockSizeVertical! * 4,
              child: Center(
                child: Text(
                  hours3,
                  style: TextStyle(
                      fontSize: 18,
                      color: Colors.black
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
