import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:muhammadiyah/navbar.dart';
import 'package:muhammadiyah/size_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

class absentRecap extends StatefulWidget {
  const absentRecap({super.key});

  @override
  State<absentRecap> createState() => _absentRecapState();
}

class _absentRecapState extends State<absentRecap> {
  double keyboardHeight = 0;

  Color bgPrimary = const Color.fromARGB(255, 230, 230, 230);

  late SharedPreferences sharedPreferences;
  String? nama = '';
  String? jabatan = '';
  String? departemen = '';

  late StreamSubscription<bool> _keyboardVisibilitySubscription;

  String? tanggal = '';
  String? jamMasuk = '--:--:--';
  String? jamKeluar = '--:--:--';
  String? jamKeluarIstirahat = '--:--:--';
  String? jamMasukIstirahat = '--:--:--';
  String? selectedDateString = "";

  late CalendarFormat _calendarFormat;
  late DateTime _focusedDay;
  late DateTime _selectedDay;

  List<DateTime> absentDates = [];

  @override
  void initState() {
    super.initState();
    initializeSharedPreferences();
    _calendarFormat = CalendarFormat.month;
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    fetchAllData();
    fetchData(_selectedDay);
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

  Future<void> fetchData(DateTime _selectedDay) async {
    try {
      sharedPreferences = await SharedPreferences.getInstance();
      final String? idLogin = sharedPreferences.getString('idLogin');

      if (idLogin != null) {
        final DateFormat dateFormatter = DateFormat('yyyy-MM-dd');
        final DateFormat timeFormatter = DateFormat('HH:mm:ss');
        final String selectedDateString = dateFormatter.format(_selectedDay);

        final QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
            .collection('Absensi')
            .where('id_pegawai', isEqualTo: idLogin)
            .where('scan_jam', isGreaterThanOrEqualTo: _selectedDay) // Query data for selected day and onwards
            .where('scan_jam', isLessThan: _selectedDay.add(const Duration(days: 1))) // Query data until the end of selected day
            .get();

        if (snapshot.docs.isNotEmpty) {
          final doc = snapshot.docs.first;
          final data = doc.data();
          if (data.containsKey('scan_jam')) {
            final dynamic scanJamData = data['scan_jam'];
            if (scanJamData is Timestamp) {
              // Process single timestamp
              final Timestamp timestamp = scanJamData;
              final DateTime dateTime = timestamp.toDate();
              final time = timeFormatter.format(dateTime);
              // Process time as needed
              final timeComponents = time.split(':');
              final hour = int.parse(timeComponents[0]);
              final minute = int.parse(timeComponents[1]);
              final scanTime = TimeOfDay(hour: hour, minute: minute);

              if (scanTime.hour >= 4 && scanTime.hour <= 10) {
                setState(() {
                  jamMasuk = time;
                });
              } else if (scanTime.hour == 11) {
                setState(() {
                  jamKeluarIstirahat = time;
                });
              } else if (scanTime.hour == 12) {
                setState(() {
                  jamMasukIstirahat = time;
                });
              } else if (scanTime.hour >= 16 && scanTime.hour <= 23) {
                setState(() {
                  jamKeluar = time;
                });
              }
              print('Date: $selectedDateString, Time: $time');
            }
          }
        } else {
          print('No data found for idLogin: $idLogin and date: $selectedDateString');
          setState(() {
            tanggal = selectedDateString;
            jamMasuk = '--:--:--';
            jamKeluar = '--:--:--';
            jamKeluarIstirahat = '--:--:--';
            jamMasukIstirahat = '--:--:--';
          });
        }
      } else {
        print('idLogin is null');
        setState(() {
          tanggal = selectedDateString;
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

  Future<List<DateTime>> fetchAllData() async {
    try {
      sharedPreferences = await SharedPreferences.getInstance();
      final String? idLogin = sharedPreferences.getString('idLogin');

      if (idLogin != null) {
        final QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
            .collection('Absensi')
            .where('id_pegawai', isEqualTo: idLogin)
            .get();

        if (snapshot.docs.isNotEmpty) {
          List<DateTime> tempAbsentDates = []; // Temporary list to store absent dates
          snapshot.docs.forEach((doc) {
            final data = doc.data();
            if (data.containsKey('scan_jam')) {
              final dynamic scanJamData = data['scan_jam'];
              if (scanJamData is Timestamp) {
                final Timestamp timestamp = scanJamData;
                final DateTime dateTime = timestamp.toDate();
                tempAbsentDates.add(dateTime); // Add absent date to the temporary list
              } else if (scanJamData is List<dynamic>) {
                scanJamData.forEach((item) {
                  final Timestamp timestamp = item['date'] as Timestamp;
                  final DateTime dateTime = timestamp.toDate();
                  tempAbsentDates.add(dateTime); // Add absent date to the temporary list
                });
              }
            }
          });
          // Update the state variable with the new list of absent dates
          setState(() {
            absentDates = tempAbsentDates;
          });
          print("setState complete");
        }
      }
      return absentDates; // Return the absent dates list
    } catch (error) {
      print('Error fetching absent dates: $error');
      return []; // Return an empty list in case of error
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    initializeDateFormatting('id');
    DateFormat dateFormatter = DateFormat('EEE, dd MMM yyyy', 'id');
    String date = dateFormatter.format(_selectedDay);

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
              fetchAllData();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Data Anda Telah Diperbaharui'),
                ),
              );
            },
          ),
        ],
        title: const Text('Rekap Absensi'),
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black,
          fontSize: 30,
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: keyboardHeight),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TableCalendar(
              firstDay: DateTime.utc(1800),
              lastDay: DateTime.utc(2200),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                  fetchData(_selectedDay);
                });
              },
              calendarStyle: CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                headerPadding: EdgeInsets.symmetric(vertical: 10),
              ),
              onHeaderTapped: (focusedDay) async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: focusedDay,
                  firstDate: DateTime.utc(1800),
                  lastDate: DateTime.utc(2200),
                );
                if (picked != null && picked != _focusedDay) {
                  setState(() {
                    _focusedDay = picked;
                    _selectedDay = picked;
                  });
                }
              },
              calendarBuilders: CalendarBuilders(
                // Customize the UI for absent dates
                markerBuilder: (context, date, events) {
                  final isAbsentDate = absentDates.any((dateTime) => dateTime.day == date.day);
                  if (isAbsentDate) {
                    return Positioned(
                      right: 1,
                      bottom: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 12.0,
                        ),
                      ),
                    );
                  }
                  return null;
                },
              ),
            ),
            SizedBox(
              height: SizeConfig.blockSizeVertical! * 1,
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
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
                      ],
                    ),
                  ),
                  Container(
                    height: SizeConfig.blockSizeVertical! * 17,
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
                                  "$jamMasuk",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  "$jamKeluar",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: SizeConfig.blockSizeVertical! * 1,
                          ),
                          Text(
                            "Istirahat",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(
                            height: SizeConfig.blockSizeVertical! * 1,
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
                                  "$jamKeluarIstirahat",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  "$jamMasukIstirahat",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.black,
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
          ],
        ),
      ),
    );
  }
}
