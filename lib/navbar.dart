import 'package:flutter/material.dart';
import 'package:muhammadiyah/navbar_content.dart';
import 'package:muhammadiyah/home.dart';
import 'package:muhammadiyah/menu.dart';
import 'package:muhammadiyah/schedule.dart';
import 'package:muhammadiyah/profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Navbar extends StatefulWidget {
  const Navbar({Key? key}) : super(key: key);

  @override
  State<Navbar> createState() => _NavbarState();
}

class _NavbarState extends State<Navbar> {
  int _currentIndex = 0;

  late SharedPreferences sharedPreferences;

  final List<Widget> _pages = const [
    Home(),
    Menu(),
    Schedule(),
    Profile(),
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentPage();
  }

  Future<void> _loadCurrentPage() async {
    sharedPreferences = await SharedPreferences.getInstance();
    setState(() {
      _currentIndex = sharedPreferences.getInt("page") ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Navbar_Content(
        currentIndex: _currentIndex,
        onTap: (index) async {
          setState(() {
            _currentIndex = index;
          });
          await sharedPreferences.setInt("page", index);
        },
      ),
    );
  }
}
