import 'dart:async';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:muhammadiyah/profile_sub/profile_page.dart';
import 'package:muhammadiyah/size_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Home extends StatefulWidget{
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class AbsensiData {
  final String? id;
  final String? nama;
  final int rfidNo;
  final DateTime scanJam;

  AbsensiData({
    required this.id,
    required this.nama,
    required this.rfidNo,
    required this.scanJam,
  });
}

class _HomeState extends State<Home>{

  double screenHeight = 0;
  double screenWidth = 0;
  double keyboardHeight = 0;

  Color bgPrimary = const Color.fromARGB(255, 230, 230, 230);

  late SharedPreferences sharedPreferences;
  String? namaHome = '';
  late StreamSubscription<bool> _keyboardVisibilitySubscription;
  late StreamSubscription<QuerySnapshot<Map<String, dynamic>>> _subscription;

  bool isPresent = false;
  String? tanggal = '';
  String? jamMasuk = '--:--:--';
  String? jamKeluar = '--:--:--';
  String? jamKeluarIstirahat = '--:--:--';
  String? jamMasukIstirahat = '--:--:--';

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
      fetchData();
      initializeSharedPreferences();
    });
  }

  @override
  void dispose() {
    // Dispose of keyboard visibility subscription
    _keyboardVisibilitySubscription.cancel();
    _subscription.cancel();
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
    setState(() {
      namaHome = sharedPreferences.getString("nama");
    });
  }

  Future<void> fetchData() async {
    try {
      sharedPreferences = await SharedPreferences.getInstance();
      final String? idLogin = sharedPreferences.getString('idLogin');
      namaHome = sharedPreferences.getString("nama");

      if (idLogin != null) {
        final DateTime now = DateTime.now();
        final DateFormat dateFormatter = DateFormat('yyyy-MM-dd');
        final DateFormat timeFormatter = DateFormat('HH:mm:ss');

        final QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
            .collection('Absensi')
            .where('id', isEqualTo: idLogin)
            .where('scan_jam', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(now.year, now.month, now.day))) // Filter by today's date or later
            .where('scan_jam', isLessThan: Timestamp.fromDate(DateTime(now.year, now.month, now.day + 1))) // Filter by before tomorrow
            .get();

        if (snapshot.docs.isNotEmpty) {
          for (final doc in snapshot.docs) {
            final data = doc.data();
            if (data.containsKey('scan_jam')) {
              final dynamic scanJamData = data['scan_jam'];
              if (scanJamData is Timestamp) {
                // Process single timestamp
                final Timestamp timestamp = scanJamData;
                final DateTime dateTime = timestamp.toDate();
                final date = dateFormatter.format(dateTime);
                final time = timeFormatter.format(dateTime);
                // Process date and time as needed
                final timeComponents = time.split(':');
                final hour = int.parse(timeComponents[0]);
                final minute = int.parse(timeComponents[1]);
                final scanTime = TimeOfDay(hour: hour, minute: minute);

                if (date == dateFormatter.format(now)) {
                  setState(() {
                    isPresent = true;
                    tanggal = date;
                  });
                }

                if (scanTime.hour >= 4 && scanTime.hour <= 10) {
                  jamMasuk = time;
                } else if (scanTime.hour == 11) {
                  jamKeluarIstirahat = time;
                } else if (scanTime.hour == 12) {
                  jamMasukIstirahat = time;
                } else if (scanTime.hour >= 16 && scanTime.hour <= 23) {
                  jamKeluar = time;
                }
                print('Date: $date, Time: $time');

              } else if (scanJamData is List<dynamic>) {
                // Process list of timestamps
                for (final dynamic item in scanJamData) {
                  final Timestamp timestamp = item['date'] as Timestamp;
                  final DateTime dateTime = timestamp.toDate();
                  final date = dateFormatter.format(dateTime);
                  final time = timeFormatter.format(dateTime);
                  // Process date and time as needed
                  final timeComponents = time.split(':');
                  final hour = int.parse(timeComponents[0]);
                  final minute = int.parse(timeComponents[1]);
                  final scanTime = TimeOfDay(hour: hour, minute: minute);

                  if (date == dateFormatter.format(now)) {
                    setState(() {
                      isPresent = true;
                      tanggal = date;
                    });
                  }

                  if (scanTime.hour >= 4 && scanTime.hour <= 10) {
                    jamMasuk = time;
                  } else if (scanTime.hour == 11) {
                    jamKeluarIstirahat = time;
                  } else if (scanTime.hour == 12) {
                    jamMasukIstirahat = time;
                  } else if (scanTime.hour >= 16 && scanTime.hour <= 23) {
                    jamKeluar = time;
                  }
                  print('Date: $date, Time: $time');
                }
              }
            }
          }
        } else {
          print('No data found for idLogin: $idLogin');
          setState(() {
            isPresent = false;
            tanggal = '';
            jamMasuk = '--:--:--';
            jamKeluar = '--:--:--';
            jamKeluarIstirahat = '--:--:--';
            jamMasukIstirahat = '--:--:--';
          });
        }
      } else {
        print('idLogin is null');
        setState(() {
          isPresent = false;
          tanggal = '';
          jamMasuk = '--:--:--';
          jamKeluar = '--:--:--';
          jamKeluarIstirahat = '--:--:--';
          jamMasukIstirahat = '--:--:--';
        });
      }
    } catch (error) {
      print('Error fetching data: $error');
    }
  }

  Future<void> writeAbsensiToFirestore() async {
    try {
      // Get SharedPreferences instance
      SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

      // Get required data from SharedPreferences
      String? idLogin = sharedPreferences.getString('idLogin');
      String? nama = sharedPreferences.getString('nama');

      // Get current datetime from the phone
      DateTime nowLocal = DateTime.now();

      // Check if the local datetime is not already in UTC+7 timezone
      if (nowLocal.timeZoneOffset != const Duration(hours: 7)) {
        // Adjust datetime to UTC+7 timezone
        nowLocal = nowLocal.toUtc().add(const Duration(hours: 7));
      }

      if (idLogin != null) {
        // Create an instance of AbsensiData
        AbsensiData absensiData = AbsensiData(
          id: idLogin,
          nama: nama,
          rfidNo: 1,
          scanJam: nowLocal,
        );

        // Reference to Firestore collection "Absensi"
        CollectionReference absensiCollection = FirebaseFirestore.instance.collection('Absensi');

        // Add document with auto-generated ID and the data
        await absensiCollection.add({
          'id': absensiData.id,
          'nama': absensiData.nama,
          'rfid_no': absensiData.rfidNo,
          'scan_jam': absensiData.scanJam,
        });

        print('Data added to Firestore successfully.');
      } else {
        print('idLogin is null');
      }

    } catch (error) {
      print('Error writing data to Firestore: $error');
    }
  }

  Future<void> _showAttendanceButtonDialogTrue(String title, String message) async {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(
            message,
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
                writeAbsensiToFirestore();
                await Future.delayed(const Duration(seconds: 2));
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _showAttendanceButtonDialogFalse(BuildContext context, String message) {
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


  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    // Get current time
    DateTime currentTime = DateTime.now().toUtc().add(const Duration(hours: 7)); // Adjust to UTC+7
    // Check if current time is between 11:00 and 14:00
    bool isDisabled = currentTime.hour >= 11 && currentTime.hour < 14;

    print(currentTime);

    return Scaffold(
      backgroundColor: bgPrimary,
      appBar: AppBar(
        backgroundColor: bgPrimary,
        title: const Text('Beranda'),
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black,
          fontSize: SizeConfig.textType!.scale(34),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: keyboardHeight),
        child: Column(
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    height: SizeConfig.blockSizeVertical! * 25,
                    width: SizeConfig.blockSizeHorizontal! * 100,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Container(
                            height: SizeConfig.safeBlockHorizontal! * 25,
                            width: SizeConfig.safeBlockHorizontal! * 25,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.black,
                                width: SizeConfig.blockSizeHorizontal! * 1,
                              ),
                            ),
                            child: Hero(
                              tag: "profilePhoto",
                              child: ClipOval(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                        builder: (context) => const Profile_page(),
                                      ),
                                    );
                                  },
                                  child: Image.asset(
                                    "lib/assets/images/profpic.png",
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: SizeConfig.blockSizeVertical! * 1,
                          ),
                          Text(
                            "Selamat Datang",
                            style: TextStyle(
                              fontSize: SizeConfig.textType!.scale(22),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            namaHome ?? 'nama',
                            style: TextStyle(
                              fontSize: SizeConfig.textType!.scale(22),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(
                            height: SizeConfig.blockSizeVertical! * 1,
                          ),
                          RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: SizeConfig.textType!.scale(18),
                                color: Colors.black, // Default color for the text
                              ),
                              children: [
                                TextSpan(
                                  text: isPresent ? "Status Absensi: " : "Status Absensi:", // First part of the text
                                ),
                                TextSpan(
                                  text: isPresent ? " Hadir ($tanggal)" : " Tidak Hadir", // Second part of the text
                                  style: TextStyle(
                                    color: isPresent ? Colors.green : Colors.red, // Color for the second part of the text
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    ),
                  ),
                ],
              )
            ),
            SizedBox(
              height: SizeConfig.blockSizeVertical! * 2.5,
            ),
            Container(
              height: SizeConfig.blockSizeVertical! * 10,
              width: SizeConfig.blockSizeHorizontal! * 100,
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    flex : 3,
                    child: Column(
                      children: [
                        Container(
                          height: SizeConfig.blockSizeVertical! * 7,
                          width: SizeConfig.blockSizeVertical! * 7,
                          child: Icon(
                            Icons.access_time,
                            color: Colors.green,
                            size: SizeConfig.blockSizeVertical! * 7,
                          ),
                        ),
                        Text(
                          "Jam Masuk",
                          style: TextStyle(
                            fontSize: SizeConfig.textType!.scale(16),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  ),
                  Expanded(
                    flex: 1,
                    child: Container(
                      height: SizeConfig.blockSizeVertical! * 5,
                      width: SizeConfig.blockSizeHorizontal! * 7,
                    )
                  ),
                  Expanded(
                    flex : 3,
                    child: Text(
                      isPresent ? "$jamMasuk" : "--:--:--",
                      style: TextStyle(
                        fontSize: SizeConfig.textType!.scale(30),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: SizeConfig.blockSizeVertical! * 2.5,
            ),
            Container(
              height: SizeConfig.blockSizeVertical! * 10,
              width: SizeConfig.blockSizeHorizontal! * 100,
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                      flex : 3,
                      child: Column(
                        children: [
                          Container(
                            height: SizeConfig.blockSizeVertical! * 7,
                            width: SizeConfig.blockSizeVertical! * 7,
                            child: Icon(
                              Icons.access_time,
                              color: Colors.red,
                              size: SizeConfig.blockSizeVertical! * 7,
                            ),
                          ),
                          Text(
                            "Jam Keluar",
                            style: TextStyle(
                              fontSize: SizeConfig.textType!.scale(16),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                  ),
                  Expanded(
                      flex: 1,
                      child: Container(
                        height: SizeConfig.blockSizeVertical! * 5,
                        width: SizeConfig.blockSizeHorizontal! * 7,
                      )
                  ),
                  Expanded(
                    flex : 3,
                    child: Text(
                      isPresent ? "$jamKeluar" : "--:--:--",
                      style: TextStyle(
                        fontSize: SizeConfig.textType!.scale(30),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: SizeConfig.blockSizeVertical! * 2.5,
            ),
            Container(
              height: SizeConfig.blockSizeVertical! * 15,
              width: SizeConfig.blockSizeHorizontal! * 100,
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: SizeConfig.blockSizeVertical! * 1,
                  ),
                  Text(
                    "Jam Istirahat",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: SizeConfig.textType!.scale(24),
                    ),
                  ),
                  SizedBox(
                    height: SizeConfig.blockSizeVertical! * 1,
                  ),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Center(
                          child: Column(
                            children: [
                              Text(
                                "Keluar",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: SizeConfig.textType!.scale(22),
                                ),
                              ),
                              Text(
                                isPresent ? "$jamKeluarIstirahat" : "--:--:--",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: SizeConfig.textType!.scale(22),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Container(
                          height: SizeConfig.blockSizeVertical! * 1,
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Center(
                          child: Column(
                            children: [
                              Text(
                                "Masuk",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: SizeConfig.textType!.scale(22),
                                ),
                              ),
                              Text(
                                isPresent ? "$jamMasukIstirahat" : "--:--:--",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: SizeConfig.textType!.scale(22),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(
              height: SizeConfig.blockSizeVertical! * 2.5,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(30)),
                    ),
                  ),
                  onPressed: () {
                    if (isDisabled) {
                      _showAttendanceButtonDialogTrue("Pemberitahuan Istirahat", "Apakah anda ingin beristirahat?");
                    } else {
                      _showAttendanceButtonDialogFalse(context, "Belum waktunya untuk istirahat");
                    }
                  },
                  child: SizedBox(
                    width: SizeConfig.safeBlockHorizontal! * 35,
                    height: SizeConfig.blockSizeVertical! * 6,
                    child: Center(
                      child: Text(
                        "Istirahat",
                        style: TextStyle(
                          fontSize: SizeConfig.textType!.scale(22),
                          color: Colors.white,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: SizeConfig.blockSizeHorizontal! * 5,
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(30)),
                    ),
                  ),
                  onPressed: () {
                    fetchData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Data Anda Telah Diperbaharui'),
                      ),
                    );
                  },
                  child: SizedBox(
                    width: SizeConfig.safeBlockHorizontal! * 35,
                    height: SizeConfig.blockSizeVertical! * 6,
                    child: Center(
                      child: Text(
                        "Perbaharui",
                        style: TextStyle(
                          fontSize: SizeConfig.textType!.scale(22),
                          color: Colors.white,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: SizeConfig.blockSizeVertical! * 2.5,
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white60,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(30)),
                ),
              ),
              onPressed: () {
                if (isDisabled) {
                  _showAttendanceButtonDialogFalse(context, "Belum waktunya untuk melakukan absensi");
                } else {
                  _showAttendanceButtonDialogTrue("Pemberitahuan Absensi", "Apakah anda ingin melakukan absensi?");
                }
              },
              child: SizedBox(
                width: SizeConfig.safeBlockHorizontal! * 45,
                height: SizeConfig.blockSizeVertical! * 6,
                child: Center(
                  child: Text(
                    "Absensi Manual",
                    style: TextStyle(
                      fontSize: SizeConfig.textType!.scale(22),
                      color: Colors.black,
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}