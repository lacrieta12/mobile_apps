import 'dart:async';

import 'package:bcrypt/bcrypt.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:muhammadiyah/profile_sub/profile_page.dart';
import 'package:muhammadiyah/size_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Edit_profile extends StatefulWidget {
  const Edit_profile({super.key});

  @override
  State<Edit_profile> createState() => _Edit_profileState();
}

class _Edit_profileState extends State<Edit_profile> {
  TextEditingController emailController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController jabatanController = TextEditingController();
  TextEditingController departemenController = TextEditingController();
  TextEditingController passController = TextEditingController();
  double keyboardHeight = 0;

  Color bgPrimary = const Color.fromARGB(255, 230, 230, 230);

  late SharedPreferences sharedPreferences;
  String? nama = '';
  String? idLogin = '';
  String? email = '';
  String? password = '';
  String? jabatan = '';
  String? departemen = '';

  late StreamSubscription<bool> _keyboardVisibilitySubscription;

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
    setState(() {
      nama = sharedPreferences.getString("nama");
      jabatan = sharedPreferences.getString("jabatan");
      departemen = sharedPreferences.getString("departemen");
      email = sharedPreferences.getString("email");

      // Set the text controllers with shared preferences data
      nameController.text = nama ?? '';
      emailController.text = email ?? '';
      jabatanController.text = jabatan ?? '';
      departemenController.text = departemen ?? '';
    });
  }

  void _showBackDialog() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pemberitahuan'),
          content: const Text(
            'Apakah anda yakin ingin meninggalkan halaman ini?',
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
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Profile_page(),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> editData(BuildContext context) async {
    try {
      sharedPreferences = await SharedPreferences.getInstance();
      String? idLogin = sharedPreferences.getString("idLogin");
      final String password = passController.text;

      final QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
          .collection('Pegawai')
          .where('id_pegawai', isEqualTo: idLogin)
          .limit(1)
          .get();

      if (snapshot.size == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ID Tidak Ditemukan.'),
          ),
        );
        return;
      }

      final DocumentSnapshot<Map<String, dynamic>> user = snapshot.docs.first;
      final String correctPasswordHash = user.get('password');

      final bool isPasswordCorrect = BCrypt.checkpw(password, correctPasswordHash);

      // Check if the entered password matches the stored hashed password
      if (password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Silahkan Masukkan Password Anda!'),
          ),
        );
      } else if (!isPasswordCorrect) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password Salah'),
          ),
        );
      } else {
        showDialog<void>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Pemberitahuan'),
              content: const Text(
                'Apakah anda yakin dengan data yang diubah?',
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
                    // Get the values from the controllers
                    String newName = nameController.text;
                    String newEmail = emailController.text;
                    String newJabatan = jabatanController.text;
                    String newDepartemen = departemenController.text;

                    // Query Firestore to find the document with matching idLogin
                    FirebaseFirestore.instance
                        .collection('Pegawai')
                        .where('id_pegawai', isEqualTo: idLogin)
                        .get()
                        .then((QuerySnapshot querySnapshot) async {
                      // Update Firestore document if the document exists
                      if (querySnapshot.docs.isNotEmpty) {
                        String documentId = querySnapshot.docs.first.id;
                        await FirebaseFirestore.instance
                            .collection('Pegawai')
                            .doc(documentId)
                            .update({
                          'nama': newName,
                          'email': newEmail,
                          'jabatan': newJabatan,
                          'departemen': newDepartemen,
                        });

                        // Update SharedPreferences with the new data
                        sharedPreferences.setString("nama", newName);
                        sharedPreferences.setString("email", newEmail);
                        sharedPreferences.setString("jabatan", newJabatan);
                        sharedPreferences.setString("departemen", newDepartemen);

                        // Close the dialog
                        Navigator.pop(context);

                        // Show success dialog
                        showDialog<void>(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Berhasil'),
                              content: const Text('Profil Berhasil diperbaharui!'),
                              actions: <Widget>[
                                TextButton(
                                  child: const Text('OK'),
                                  onPressed: () {
                                    // Navigate back to the profile page
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(builder: (context) => const Profile_page()),
                                    );
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      } else {
                        // Document with the provided idLogin not found
                        print('Document with idLogin $idLogin not found');
                        // Close the dialog
                        Navigator.pop(context);
                      }
                    }).catchError((error) {
                      // Error updating document
                      print('Failed to update document: $error');
                      // Close the dialog
                      Navigator.pop(context);
                    });
                  },
                ),
              ],
            );
          },
        );
      }
    } catch (error) {
      print("Error signing in: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Terjadi Kesalahan Saat Mengganti Data.'),
        ),
      );
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
            _showBackDialog();
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
        title: const Text('Edit Profil'),
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 30,
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: keyboardHeight),
        child: Column(
          children: [
            Container(
              height: SizeConfig.blockSizeVertical! * 20,
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
              child: Center(
                child: Column(
                  children: [
                    Container(
                      height: SizeConfig.blockSizeHorizontal! * 30,
                      width: SizeConfig.blockSizeHorizontal! * 30,
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
                  ],
                ),
              ),
            ),
            SizedBox(
              height: SizeConfig.blockSizeVertical! * 2,
            ),
            customField("Nama", nameController , Icons.person, FontWeight.w600),
            SizedBox(
              height: SizeConfig.blockSizeVertical! * 2,
            ),
            customField("Email", emailController , Icons.email, FontWeight.w600),
            SizedBox(
              height: SizeConfig.blockSizeVertical! * 2,
            ),
            customField("Jabatan", jabatanController , Icons.school, FontWeight.w600),
            SizedBox(
              height: SizeConfig.blockSizeVertical! * 2,
            ),
            customField("Departemen", departemenController , Icons.warehouse, FontWeight.w600),
            SizedBox(
              height: SizeConfig.blockSizeVertical! * 1,
            ),
            customField("Silahkan Masukkan Password Anda!", passController, Icons.key, FontWeight.normal, obscure: true),
            SizedBox(
              height: SizeConfig.blockSizeVertical! * 2,
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white60,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(30)),
                ),
              ),
              onPressed: () {
                editData(context);
              },
              child: SizedBox(
                width: SizeConfig.blockSizeHorizontal! * 65,
                height: SizeConfig.blockSizeVertical! * 8,
                child: Center(
                  child: Text(
                    "Edit Profil",
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.black,
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            PopScope(
              canPop: false,
              onPopInvoked: (bool didPop) {
                if (didPop) {
                  return;
                }
                _showBackDialog();
              },
              child: TextButton(
                onPressed: () {
                  _showBackDialog();
                },
                child: const Text(" "),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget customField(
      String hint,
      TextEditingController controller,
      IconData iconData,
      FontWeight weight,
      {bool obscure = false}
      ) {
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
              padding: EdgeInsets.only(
                  right: SizeConfig.blockSizeHorizontal! * 7
              ),
              child: TextFormField(
                controller: controller,
                enableSuggestions: false,
                autocorrect: false,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    vertical: SizeConfig.blockSizeVertical! * 2,
                  ),
                  border: InputBorder.none,
                  hintText: hint,
                ),
                maxLines: 1,
                obscureText: obscure,
                style: TextStyle(
                  fontWeight: weight,
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
