import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:muhammadiyah/navbar.dart';
import 'package:muhammadiyah/profile_sub/edit_password.dart';
import 'package:muhammadiyah/profile_sub/edit_profile.dart';
import 'package:muhammadiyah/size_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class Profile_page extends StatefulWidget {
  const Profile_page({super.key});

  @override
  State<Profile_page> createState() => _Profile_pageState();
}

class _Profile_pageState extends State<Profile_page> {
  double screenHeight = 0;
  double screenWidth = 0;
  double keyboardHeight = 0;

  Color bgPrimary = const Color.fromARGB(255, 230, 230, 230);

  late SharedPreferences sharedPreferences;
  String nama = '';
  String? idLogin = '';
  String idLog = '';
  String email = '';
  String password = '';
  String jabatan = '';
  String departemen = '';
  String fotoUrl = '';

  bool _dataFetched = false;

  late StreamSubscription<bool> _keyboardVisibilitySubscription;

  File? _imageFile;

  final picker = ImagePicker();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

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
  }

  Future<void> _showSuccessNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'success_channel_id',
      'Success notifications',
      // 'Notifications for successful operations',
      importance: Importance.high,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      'Upload Success',
      'Image uploaded successfully',
      platformChannelSpecifics,
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      File? croppedFile = await _cropImage(File(pickedFile.path));
      print("_cropImage available");
      if (croppedFile != null) {
        // Construct the new file path with the desired name
        String renamedFilePath = "${pickedFile.path.replaceAll(RegExp(r'\.[^\.]+$'), '')}_Profpic_$idLog.jpg";
        File renamedFile = await croppedFile.copy(renamedFilePath);
        setState(() {
          _imageFile = renamedFile;
        });
        _uploadImage();
      }
    } else {
      print('No image selected.');
    }
  }

  Future<File?> _cropImage(File imageFile) async {
    try {
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        aspectRatioPresets: [
          CropAspectRatioPreset.square,
        ],
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Cropper',
            toolbarColor: Colors.deepOrange,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Cropper',
          ),
        ],
      );

      if (croppedFile != null) {
        print('crop Success');
        return File(croppedFile.path);
      } else {
        print('crop Failed');
        return null;
      }
    } catch (e) {
      print('Error cropping image: $e');
      return null;
    }
  }

  Future<void> _uploadImage() async {
    sharedPreferences = await SharedPreferences.getInstance();
    final String? idLogin = sharedPreferences.getString('idLogin');

    if (idLogin != null && idLogin.isNotEmpty && _imageFile != null) {
      print('Image ready to be uploaded');

      final fileName = _imageFile;

      // Upload renamed image to Firebase Storage
      try {
        final storage = FirebaseStorage.instance;
        final imagePath = 'Foto_Profil/$fileName';
        final Reference ref = storage.ref().child(imagePath);
        final metadata = SettableMetadata(contentType: 'image/jpeg');
        final UploadTask uploadTask = ref.putFile(_imageFile!, metadata);
        await uploadTask.whenComplete(() => _showSuccessNotification());

        // Get download URL
        final imageUrl = await ref.getDownloadURL();

        FirebaseFirestore.instance
            .collection('Pegawai')
            .where('id_pegawai', isEqualTo: idLogin)
            .get()
            .then((QuerySnapshot querySnapshot) async {
          if (querySnapshot.docs.isNotEmpty) {
            String documentId = querySnapshot.docs.first.id;
            await FirebaseFirestore.instance
                .collection('Pegawai')
                .doc(documentId)
                .update({
              'foto': imageUrl,
            });
            setState(() {
              fotoUrl = imageUrl;
            });
            fetchData();
          }
        }).catchError((error) {
          // Error updating document
          print('Failed to update document: $error');
          // Close the dialog
          Navigator.pop(context);
        });
      } catch (e) {
        print('Error uploading image: $e');
      }
    } else {
      print('Image not available or user ID not found');
      // Handle case where image or user ID is missing
      // You can display an error message or take appropriate action here
    }
  }

  Future<void> fetchData() async {
    try {
      sharedPreferences = await SharedPreferences.getInstance();
      final String? idLogin = sharedPreferences.getString('idLogin');

      if (idLogin != null) {
        final QuerySnapshot<Map<String, dynamic>> snapshot =
        await FirebaseFirestore.instance.collection('Pegawai').where('id_pegawai', isEqualTo: idLogin).get();

        final DocumentSnapshot<Map<String, dynamic>> user = snapshot.docs.first;

        final String fetchNama = user.get('nama');
        final String fetchEmail = user.get('email');
        final String fetchIdLogin = user.get('id_pegawai');
        final String fetchJabatan = user.get('jabatan');
        final String fetchDepartemen = user.get('departemen');
        final String fetchFotoUrl = user.get('foto');

        setState(() {
          nama = fetchNama;
          email = fetchEmail;
          idLog = fetchIdLogin;
          jabatan = fetchJabatan;
          departemen = fetchDepartemen;
          fotoUrl = fetchFotoUrl;
        });

      } else {
        print('No data found for idLogin: $idLogin');
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
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const Navbar(), // Pass the page widget class itself
              ),
            );
          },
        ),
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
        title: const Text('Profil'),
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 30,
        ),
      ),
      body: _dataFetched
          ? profilePage()
          : FutureBuilder<void>(
          future: Future.wait([
            fetchData(),
          ]),
          builder: (context, AsyncSnapshot<void> snapshot) {
            if (snapshot.hasData) {
              _dataFetched = true;
              return profilePage();
            } else {
              return Center(
                child: CircularProgressIndicator(),
              );
            }
          }
      ),
   );
  }

  Widget profilePage() {
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: Column(
        children: [
          Container(
            height: SizeConfig.blockSizeVertical! * 25,
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
            child: Stack(
              children: [
                Center(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            height: SizeConfig.blockSizeVertical! * 15,
                            width: SizeConfig.blockSizeVertical! * 15,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: SizeConfig.blockSizeHorizontal! * 1,
                              ),
                            ),
                            child: ClipOval(
                              child: Image.network(
                                fotoUrl,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              height: SizeConfig.blockSizeVertical! * 5,
                              width: SizeConfig.blockSizeVertical! * 5,
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: SizeConfig.blockSizeHorizontal! * 1,
                                ),
                              ),
                              child: IconButton(
                                padding: EdgeInsets.only(left: 0),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            ListTile(
                                              title: Text(
                                                'Buka Kamera',
                                                style: TextStyle(
                                                  fontSize: 22,
                                                ),
                                              ),
                                              onTap: () {
                                                _pickImage(ImageSource.camera);
                                              }
                                            ),
                                            Divider(
                                              height: SizeConfig.blockSizeVertical! * 1,
                                            ),
                                            ListTile(
                                              title: Text(
                                                'Pilih Foto Dari Album',
                                                style: TextStyle(
                                                  fontSize: 22,
                                                ),
                                              ),
                                              onTap: () {
                                                _pickImage(ImageSource.gallery);
                                              }
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                                icon: Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: SizeConfig.blockSizeVertical! * 2.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: SizeConfig.blockSizeVertical! * 2,
                      ),
                      Text(
                        nama,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: SizeConfig.blockSizeVertical! * 2,
          ),
          customField(idLog, Icons.person),
          SizedBox(
            height: SizeConfig.blockSizeVertical! * 2,
          ),
          customField(email, Icons.email),
          SizedBox(
            height: SizeConfig.blockSizeVertical! * 2,
          ),
          customField(jabatan, Icons.school),
          SizedBox(
            height: SizeConfig.blockSizeVertical! * 2,
          ),
          customField(departemen, Icons.warehouse),
          SizedBox(
            height: SizeConfig.blockSizeVertical! * 1,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white60,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(30)),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const Edit_profile(), // Pass the page widget class itself
                    ),
                  );
                },
                child: SizedBox(
                  width: SizeConfig.blockSizeHorizontal! * 32,
                  height: SizeConfig.blockSizeVertical! * 8,
                  child: Center(
                    child: Text(
                      "Edit Profil",
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.black,
                        letterSpacing: 1,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: SizeConfig.blockSizeHorizontal! * 2,
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white60,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(30)),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const editPassword(), // Pass the page widget class itself
                    ),
                  );
                },
                child: SizedBox(
                  width: SizeConfig.blockSizeHorizontal! * 32,
                  height: SizeConfig.blockSizeVertical! * 8,
                  child: Center(
                    child: Text(
                      "Ganti Password",
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.black,
                        letterSpacing: 1,
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

  Widget customField(String hint, IconData iconData) {
    SizeConfig().init(context);

    return Container(
      width: SizeConfig.blockSizeHorizontal! * 90,
      height: SizeConfig.blockSizeVertical! * 8,
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
          SizedBox(
            width: SizeConfig.blockSizeHorizontal! * 5,
            child: Text(
              ":",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 20,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: SizeConfig.blockSizeHorizontal! * 7),
              child: Text(
                hint,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
