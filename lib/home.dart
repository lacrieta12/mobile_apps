import 'dart:async';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:muhammadiyah/absent_recap.dart';
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
  late StreamSubscription<bool> _keyboardVisibilitySubscription;
  late StreamSubscription<QuerySnapshot<Map<String, dynamic>>> _subscription;

  bool isPresent = false;
  String? tanggal = '';
  String? jamMasuk = '--:--:--';
  String? jamKeluar = '--:--:--';
  String? jamKeluarIstirahat = '--:--:--';
  String? jamMasukIstirahat = '--:--:--';

  String nama = '';
  String fotoUrl = '';

  bool f1 = false;
  bool f2 = false;
  bool f3 = false;
  bool f4 = false;
  bool f5 = false;
  bool f6 = false;
  bool _dataFetched = false;

  String rfid_loc = "";
  int rfid_no = 0;

  @override
  void initState() {
    super.initState();
    initializeSharedPreferences();
    fetchAttendance();
    fetchLocation();
    // fetchData();
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
      fetchAttendance();
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
    sharedPreferences.setBool("isPresent", isPresent);
  }

  Future<void> fetchLocation() async {
    try{
      sharedPreferences = await SharedPreferences.getInstance();
      final String? idLogin = sharedPreferences.getString('idLogin');

      if (idLogin != null) {
        final QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
            .collection('Pegawai')
            .where('id_pegawai', isEqualTo: idLogin)
            .get();

        final DocumentSnapshot<Map<String, dynamic>> user = snapshot.docs.first;
        final String rfid_code = user.get('rfid_code');
        final String accessCode = rfid_code.substring(12, 16);

        if (accessCode == "D111") {
          setState(() {
            f1 = true;
          });
        } else if (accessCode == "D222") {
          setState(() {
            f1 = true;
            f2 = true;
          });
        } else if (accessCode == "D333") {
          setState(() {
            f1 = true;
            f2 = true;
            f3 = true;
          });
        } else if (accessCode == "D444") {
          setState(() {
            f1 = true;
            f2 = true;
            f3 = true;
            f4 = true;
          });
        } else if (accessCode == "D555") {
          setState(() {
            f1 = true;
            f2 = true;
            f3 = true;
            f4 = true;
            f5 = true;
          });
        } else if (accessCode == "D666") {
          setState(() {
            f1 = true;
            f2 = true;
            f3 = true;
            f4 = true;
            f5 = true;
            f6 = true;
          });
        } else {
          print("No match Access Code");
        }
      } else {
        print("No match idLogin");
      }
    } catch (error) {
      print('Error fetching data: $error');
    }
  }

  Future<void> fetchData() async {
    try {
      sharedPreferences = await SharedPreferences.getInstance();
      final String? idLogin = sharedPreferences.getString("idLogin");

      if (idLogin != null) {
        final QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
            .collection('Pegawai')
            .where('id_pegawai', isEqualTo: idLogin)
            .get();

        if (snapshot.docs.isNotEmpty) {
          final DocumentSnapshot<Map<String, dynamic>> user = snapshot.docs.first;
          final String fetchNama = user.get('nama');
          final String fetchFotoUrl = user.get('foto');
          setState(() {
            nama = fetchNama;
            fotoUrl = fetchFotoUrl;
          });
          print("Fetch Complete");
        } else {
          print("Doc is empty");
        }
      } else {
        print("idLogin is null");
      }
    } catch (error) {
      print('Error fetching data: $error');
    }
  }

  Future<void> fetchAttendance() async {
    try {
      sharedPreferences = await SharedPreferences.getInstance();
      final String? idLogin = sharedPreferences.getString('idLogin');

      if (idLogin != null) {
        final DateTime now = DateTime.now();
        final DateFormat dateFormatter = DateFormat('yyyy-MM-dd');
        final DateFormat timeFormatter = DateFormat('HH:mm:ss');

        final QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
            .collection('Absensi')
            .where('id_pegawai', isEqualTo: idLogin)
            .where('scan_jam', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(now.year, now.month, now.day))) // Filter by today's date or later
            .where('scan_jam', isLessThan: Timestamp.fromDate(DateTime(now.year, now.month, now.day + 1))) // Filter by before tomorrow
            .get();

        final DocumentSnapshot<Map<String, dynamic>> user = snapshot.docs.first;
        final int rfid_no = user.get('rfid_no');

        if (rfid_no == 1) {
          setState(() {
            rfid_loc = "Tempat Absensi";
          });
        } else if (rfid_no == 2) {
          setState(() {
            rfid_loc = "Lantai 1";
          });
        } else if (rfid_no == 3) {
          setState(() {
            rfid_loc = "Lantai 2";
          });
        } else if (rfid_no == 4) {
          setState(() {
            rfid_loc = "Lantai 3";
          });
        } else if (rfid_no == 5) {
          setState(() {
            rfid_loc = "Lantai 4";
          });
        } else if (rfid_no == 6) {
          setState(() {
            rfid_loc = "Lantai 5";
          });
        } else if (rfid_no == 7) {
          setState(() {
            rfid_loc = "Lantai 6";
          });
        }

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
                  sharedPreferences.setBool("isPresent", isPresent);
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
                    sharedPreferences.setBool("isPresent", isPresent);
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
          'id_pegawai': absensiData.id,
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

    return Scaffold(
      backgroundColor: bgPrimary,
      appBar: AppBar(
        backgroundColor: bgPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              fetchAttendance();
              fetchLocation();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Data Anda Telah Diperbaharui'),
                ),
              );
            },
          ),
        ],
        automaticallyImplyLeading: false,
        title: const Text('Beranda'),
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black,
          fontSize: 30,
        ),
      ),
      body: _dataFetched
          ? Home()
          : FutureBuilder<void>(
          future: Future.wait([
            fetchData(),
          ]),
          builder: (context, AsyncSnapshot<void> snapshot) {
            if (snapshot.hasData) {
              _dataFetched = true;
              return Home();
            } else {
              return Center(
                child: CircularProgressIndicator(),
              );
            }
          }
      ),
    );
  }

  Widget Home() {
    SizeConfig().init(context);
    initializeDateFormatting('id');
    // Get current time
    DateTime currentTime = DateTime.now().toUtc().add(const Duration(hours: 7));
    DateTime currentDate = DateTime.now();
    // Check if current time is between 11:00 and 14:00
    bool isDisabled = currentTime.hour >= 11 && currentTime.hour < 14;
    DateFormat dateFormatter = DateFormat('EEE, dd MMM yyyy', 'id');
    String date = dateFormatter.format(currentDate);

    return SingleChildScrollView(
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
                    ),
                    child: Center(
                        child: Column(
                          children: [
                            Container(
                              height: SizeConfig.blockSizeVertical! * 14,
                              width: SizeConfig.blockSizeVertical! * 14,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.black,
                                  width: SizeConfig.blockSizeHorizontal! * 1,
                                ),
                              ),
                              child: ClipOval(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                        builder: (context) => const Profile_page(),
                                      ),
                                    );
                                  },
                                  child: Image.network(
                                    fotoUrl,
                                    fit: BoxFit.cover,
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
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              nama,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(
                              height: SizeConfig.blockSizeVertical! * 1,
                            ),
                            RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 16,
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
            height: SizeConfig.blockSizeVertical! * 1,
          ),
          Row(
            children: [
              Container(
                height: SizeConfig.blockSizeVertical! * 15,
                width: SizeConfig.blockSizeHorizontal! * 50,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    right: BorderSide(color: Color.fromARGB(255, 134, 134, 134)),
                  ),
                ),
                child: Center(
                  child: Column(
                    children: [
                      SizedBox(
                        height: SizeConfig.blockSizeVertical! * 1.5,
                      ),
                      Text(
                        "Lokasi Terakhir",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                      SizedBox(
                        height: SizeConfig.blockSizeVertical! * 2,
                      ),
                      Text(
                        isPresent ? "$rfid_loc" : "-",
                        style: TextStyle(
                          fontSize: 20,
                        ),
                      )
                    ],
                  ),
                ),
              ),
              Container(
                height: SizeConfig.blockSizeVertical! * 15,
                width: SizeConfig.blockSizeHorizontal! * 50,
                decoration: const BoxDecoration(
                  color: Colors.white,
                ),
                child: Center(
                  child: Column(
                    children: [
                      SizedBox(
                        height: SizeConfig.blockSizeVertical! * 0.5,
                      ),
                      Text(
                        "Akses Lantai",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                      SizedBox(
                        height: SizeConfig.blockSizeVertical! * 1,
                      ),
                      Row(
                        children: [
                          Container(
                            height: SizeConfig.blockSizeVertical! * 10,
                            width: SizeConfig.blockSizeHorizontal! * 25,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              border: Border(
                                right: BorderSide(color: Color.fromARGB(255, 134, 134, 134)),
                              ),
                            ),
                            child: floorAccess(
                                "Lantai 1",
                                "Lantai 2",
                                "Lantai 3",
                                f1 ? Icons.check_box : Icons.do_not_disturb_on,
                                f2 ? Icons.check_box : Icons.do_not_disturb_on,
                                f3 ? Icons.check_box : Icons.do_not_disturb_on,
                                f1 ? Colors.green : Colors.red,
                                f2 ? Colors.green : Colors.red,
                                f3 ? Colors.green : Colors.red
                            ),
                          ),
                          Container(
                            height: SizeConfig.blockSizeVertical! * 10,
                            width: SizeConfig.blockSizeHorizontal! * 25,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                            ),
                            child: floorAccess(
                                "Lantai 4",
                                "Lantai 5",
                                "Lantai 6",
                                f4 ? Icons.check_box : Icons.do_not_disturb_on,
                                f5 ? Icons.check_box : Icons.do_not_disturb_on,
                                f6 ? Icons.check_box : Icons.do_not_disturb_on,
                                f4 ? Colors.green : Colors.red,
                                f5 ? Colors.green : Colors.red,
                                f6 ? Colors.green : Colors.red
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            height: SizeConfig.blockSizeVertical! * 1,
          ),
          Container(
            height: SizeConfig.blockSizeVertical! * 32,
            width: SizeConfig.blockSizeHorizontal! * 100,
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
            child: Column(
              children: [
                SizedBox(
                  height: SizeConfig.blockSizeVertical! * 1,
                ),
                Text(
                  "Kehadiran",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                SizedBox(
                  height: SizeConfig.blockSizeVertical! * 1,
                ),
                Container(
                  height: SizeConfig.blockSizeVertical! * 5,
                  width: SizeConfig.blockSizeHorizontal! * 90,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 239, 239, 239),
                    border: Border.all(
                      color: const Color.fromARGB(255, 134, 134, 134),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: SizeConfig.blockSizeHorizontal! * 3),
                        child: Row(
                          children: [
                            RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                                children: [
                                  const TextSpan(
                                    text: "Hariini ",
                                  ),
                                  TextSpan(
                                    text: "($date)",
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton(
                        icon: Icon(Icons.more_horiz),
                        itemBuilder: (BuildContext context) => <PopupMenuEntry>[
                          PopupMenuItem(
                            value: 1,
                            textStyle: TextStyle(
                              fontSize: 18,
                            ),
                            child: Text('Lihat Rekap Absensi'),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 1) {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => const absentRecap(),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
                Container(
                  height: SizeConfig.blockSizeVertical! * 18,
                  width: SizeConfig.blockSizeHorizontal! * 90,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color.fromARGB(255, 134, 134, 134),
                    ),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(5),
                    ),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        SizedBox(
                          height: SizeConfig.blockSizeVertical! * 1,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 1,
                              child: Text(
                                "Jam Masuk",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                "Jam Keluar",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 1,
                              child: Text(
                                isPresent ? "$jamMasuk" : "--:--:--",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 20,
                                  color: isPresent ? Colors.green : Colors.black,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                isPresent ? "$jamKeluar" : "--:--:--",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 20,
                                  color: isPresent ? Colors.red : Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: SizeConfig.blockSizeVertical! * 0.5,
                        ),
                        Text(
                          "Istirahat",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(
                          height: SizeConfig.blockSizeVertical! * 0.5,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 1,
                              child: Text(
                                "Keluar",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                "Masuk",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 1,
                              child: Text(
                                isPresent ? "$jamKeluarIstirahat" : "--:--:--",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 20,
                                  color: isPresent ? Colors.green : Colors.black,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                isPresent ? "$jamMasukIstirahat" : "--:--:--",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 20,
                                  color: isPresent ? Colors.red : Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
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
                  width: SizeConfig.blockSizeHorizontal! * 35,
                  height: SizeConfig.blockSizeVertical! * 6,
                  child: Center(
                    child: Text(
                      "Istirahat",
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
                  if (isDisabled) {
                    _showAttendanceButtonDialogFalse(context, "Belum waktunya untuk melakukan absensi");
                  } else {
                    _showAttendanceButtonDialogTrue("Pemberitahuan Absensi", "Apakah anda ingin melakukan absensi?");
                  }
                },
                child: SizedBox(
                  width: SizeConfig.blockSizeHorizontal! * 35,
                  height: SizeConfig.blockSizeVertical! * 6,
                  child: Center(
                    child: Text(
                      "Absensi Manual",
                      style: TextStyle(
                        fontSize: 20,
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
        ],
      ),
    );
  }

  Widget floorAccess(
      String message1,
      String message2,
      String message3,
      IconData icon1,
      IconData icon2,
      IconData icon3,
      Color color1,
      Color color2,
      Color color3
      ) {
    SizeConfig().init(context);

    return Column(
      children: [
        Row(
          children: [
            Padding(
              padding: EdgeInsets.only(left: SizeConfig.blockSizeHorizontal! * 1.5),
              child: Text(
                message1,
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
            ),
            SizedBox(
              width: SizeConfig.blockSizeHorizontal! * 2,
            ),
            Padding(
              padding: EdgeInsets.only(left: SizeConfig.blockSizeHorizontal! * 1.5),
              child: Icon(
                icon1,
                color: color1,
                size: SizeConfig.blockSizeHorizontal! * 5,
              ),
            ),
          ],
        ),
        SizedBox(
          height: SizeConfig.blockSizeHorizontal! * 1,
        ),
        Row(
          children: [
            Padding(
              padding: EdgeInsets.only(left: SizeConfig.blockSizeHorizontal! * 1.5),
              child: Text(
                message2,
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
            ),
            SizedBox(
              width: SizeConfig.blockSizeHorizontal! * 2,
            ),
            Padding(
              padding: EdgeInsets.only(left: SizeConfig.blockSizeHorizontal! * 1.5),
              child: Icon(
                icon2,
                color: color2,
                size: SizeConfig.blockSizeHorizontal! * 5,
              ),
            ),
          ],
        ),
        SizedBox(
          height: SizeConfig.blockSizeHorizontal! * 1,
        ),
        Row(
          children: [
            Padding(
              padding: EdgeInsets.only(left: SizeConfig.blockSizeHorizontal! * 1.5),
              child: Text(
                message3,
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
            ),
            SizedBox(
              width: SizeConfig.blockSizeHorizontal! * 2,
            ),
            Padding(
              padding: EdgeInsets.only(left: SizeConfig.blockSizeHorizontal! * 1.5),
              child: Icon(
                icon3,
                color: color3,
                size: SizeConfig.blockSizeHorizontal! * 5,
              ),
            ),
          ],
        ),
      ],
    );
  }
}