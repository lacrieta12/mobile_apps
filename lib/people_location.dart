import 'dart:async';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:muhammadiyah/navbar.dart';
import 'package:muhammadiyah/size_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Location extends StatefulWidget {
  const Location({super.key});

  @override
  State<Location> createState() => _LocationState();
}

class _LocationState extends State<Location> {
  double keyboardHeight = 0;

  Color bgPrimary = const Color.fromARGB(255, 230, 230, 230);

  late SharedPreferences sharedPreferences;

  late StreamSubscription<bool> _keyboardVisibilitySubscription;
  late StreamSubscription<QuerySnapshot<Map<String, dynamic>>> _subscription;

  String id1 = '100001';
  String id2 = '100002';
  String id3 = '100003';
  String id4 = '100004';
  String id5 = '100005';
  String id6 = '100006';

  String jam1 = '--:--:--';
  String jam2 = '--:--:--';
  String jam3 = '--:--:--';
  String jam4 = '--:--:--';
  String jam5 = '--:--:--';
  String jam6 = '--:--:--';

  String loc1 = '-';
  String loc2 = '-';
  String loc3 = '-';
  String loc4 = '-';
  String loc5 = '-';
  String loc6 = '-';
  
  String nama1 = "";
  String nama2 = "";
  String nama3 = "";
  String nama4 = "";
  String nama5 = "";
  String nama6 = "";

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
    // Listen for real-time updates in Firestore collection
    _subscription = FirebaseFirestore.instance
        .collection('Absensi')
        .snapshots()
        .listen((QuerySnapshot<Map<String, dynamic>> snapshot) {
      // Trigger data fetching whenever there's a change in the collection
      initializeSharedPreferences();
      fetchData();
    });
  }

  @override
  void dispose() {
    // Dispose of keyboard visibility subscription
    _keyboardVisibilitySubscription.cancel();
    _subscription.cancel();
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
    try {
      sharedPreferences = await SharedPreferences.getInstance();

      final DateTime now = DateTime.now();
      final DateFormat timeFormatter = DateFormat('HH:mm:ss');

      final QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
          .collection('Absensi')
          .where('id_pegawai', whereIn: [id1, id2, id3, id4, id5, id6])
          .where('scan_jam', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(now.year, now.month, now.day))) // Filter by today's date or later
          .where('scan_jam', isLessThan: Timestamp.fromDate(DateTime(now.year, now.month, now.day + 1))) // Filter by before tomorrow
          .get();

      if (snapshot.docs.isNotEmpty) {
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final dynamic scanJamData = data['scan_jam'];
          if (scanJamData is Timestamp) {
            // Process single timestamp
            final Timestamp timestamp = scanJamData;
            final DateTime dateTime = timestamp.toDate();
            final time = timeFormatter.format(dateTime);

            final id = data["id"];
            final nama = data["nama"];
            final rfid_no = data["rfid_no"];

            String loc;
            switch (rfid_no) {
              case 1:
                loc = 'Tempat Absensi';
                break;
              case 2:
                loc = 'Lantai 1';
                break;
              case 3:
                loc = 'Lantai 2';
                break;
              case 4:
                loc = 'Lantai 3';
                break;
              case 5:
                loc = 'Lantai 4';
                break;
              case 6:
                loc = 'Lantai 5';
                break;
              case 7:
                loc = 'Lantai 6';
                break;
              default:
                loc = 'Null';
            }

            if (id == id1) {
              setState(() {
                nama1 = nama;
                jam1 = time;
                loc1 = loc;
              });
            } else if (id == id2) {
              setState(() {
                nama2 = nama;
                jam2 = time;
                loc2 = loc;
              });
            } else if (id == id3) {
              setState(() {
                nama3 = nama;
                jam3 = time;
                loc3 = loc;
              });
            } else if (id == id4) {
              setState(() {
                nama4 = nama;
                jam4 = time;
                loc4 = loc;
              });
            } else if (id == id5) {
              setState(() {
                nama5 = nama;
                jam5 = time;
                loc5 = loc;
              });
            } else if (id == id6) {
              setState(() {
                nama6 = nama;
                jam6 = time;
                loc6 = loc;
              });
            }
            // Add conditions for other ids (id7 to idN) if needed
          }
        }
      } else {
        print('No data found for idLogin');
      }
    } catch (error) {
      print('Error fetching data: $error');
    }
  }


  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);

    return Scaffold(
      backgroundColor: bgPrimary,
      appBar: AppBar(
        backgroundColor: bgPrimary,
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              fetchData();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Data Anda Telah Diperbaharui'),
                ),
              );
            },
          ),
        ],
        title: const Text('Lokasi'),
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black,
          fontSize: 30,
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: keyboardHeight),
        child: Center(
          child: Column(
            children: [
              SizedBox(
                height: SizeConfig.blockSizeVertical! * 2,
              ),
              Text(
                "Lokasi",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 30,
                ),
              ),
              SizedBox(
                height: SizeConfig.blockSizeVertical! * 5,
              ),
              loc(
                nama1,
                loc1,
                jam1,
                nama2,
                loc2,
                jam2
              ),
              SizedBox(
                height: SizeConfig.blockSizeVertical! * 2,
              ),
              loc(
                  nama3,
                  loc3,
                  jam3,
                  nama4,
                  loc4,
                  jam4
              ),
              SizedBox(
                height: SizeConfig.blockSizeVertical! * 2,
              ),
              loc(
                  nama5,
                  loc5,
                  jam5,
                  nama6,
                  loc6,
                  jam6
              ),
              SizedBox(
                height: SizeConfig.blockSizeVertical! * 2,
              ),
              loc(
                "NAMA 1 PANJANG BANGET",
                "TEMPAT ABSENSI 1",
                "--:--:--",
                "NAMA 2 PANJANG BANGET",
                "TEMPAT ABSENSI 2",
                "--:--:--"
              ),
              SizedBox(
                height: SizeConfig.blockSizeVertical! * 2,
              ),
              loc(
                  "NAMA 1 PANJANG BANGET",
                  "TEMPAT ABSENSI 1",
                  "--:--:--",
                  "NAMA 2 PANJANG BANGET",
                  "TEMPAT ABSENSI 2",
                  "--:--:--"
              ),
              SizedBox(
                height: SizeConfig.blockSizeVertical! * 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget loc(
      String nama1,
      String loc1,
      String jam1,
      String nama2,
      String loc2,
      String jam2
      ){
    return Row(
      children: [
        Container(
          height: SizeConfig.blockSizeVertical! * 12,
          width: SizeConfig.blockSizeHorizontal! * 18,
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: SizeConfig.blockSizeHorizontal! * 16,
                  width: SizeConfig.blockSizeHorizontal! * 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.black,
                      width: SizeConfig.blockSizeHorizontal! * 0.3,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      "lib/assets/images/profpic.png",
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          height: SizeConfig.blockSizeVertical! * 12,
          width: SizeConfig.blockSizeHorizontal! * 30,
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
          child: Stack(
            alignment: Alignment.topLeft,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: SizeConfig.blockSizeHorizontal! * 1.5),
                    child: Text(
                      nama1,
                      softWrap: true,
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700
                      ),
                    ),
                  ),
                  SizedBox(
                    height: SizeConfig.blockSizeVertical! * 1.5,
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: SizeConfig.blockSizeHorizontal! * 1.5),
                    child: Text(
                      loc1,
                      softWrap: true,
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: 18,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: SizeConfig.blockSizeHorizontal! * 1.5),
                    child: Text(
                      jam1,
                      softWrap: true,
                      style: TextStyle(
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(
          width: SizeConfig.blockSizeHorizontal! * 2,
        ),
        Container(
          height: SizeConfig.blockSizeVertical! * 12,
          width: SizeConfig.blockSizeHorizontal! * 18,
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: SizeConfig.blockSizeHorizontal! * 16,
                  width: SizeConfig.blockSizeHorizontal! * 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.black,
                      width: SizeConfig.blockSizeHorizontal! * 0.3,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      "lib/assets/images/profpic.png",
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          height: SizeConfig.blockSizeVertical! * 12,
          width: SizeConfig.blockSizeHorizontal! * 30,
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
          child: Stack(
            alignment: Alignment.topLeft,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: SizeConfig.blockSizeHorizontal! * 1.5),
                    child: Text(
                      nama2,
                      softWrap: true,
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700
                      ),
                    ),
                  ),
                  SizedBox(
                    height: SizeConfig.blockSizeVertical! * 1.5,
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: SizeConfig.blockSizeHorizontal! * 1.5),
                    child: Text(
                      loc2,
                      softWrap: true,
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: 18,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: SizeConfig.blockSizeHorizontal! * 1.5),
                    child: Text(
                      jam2,
                      softWrap: true,
                      style: TextStyle(
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
