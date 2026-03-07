import 'package:bgmi_tournamentor/main.dart';
import 'package:bgmi_tournamentor/screen/my_match.dart';
import 'package:bgmi_tournamentor/screen/profile_page.dart';
import 'package:bgmi_tournamentor/screen/shop.dart';
import 'package:bgmi_tournamentor/screen/tournamescreen.dart';
import 'package:flutter/material.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {

  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    TournamentScreen(),
    MyMatchesScreen(),
    WarriorProfileScreen(),
    ShopScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF3B2314),
        selectedItemColor: const Color(0xFFFF8C42),
        unselectedItemColor: const Color(0xFF9CA3AF),
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events), label: "Tournaments"),
          BottomNavigationBarItem(
              icon: Icon(Icons.sports_martial_arts), label: "My Matches"),

          BottomNavigationBarItem(
              icon: Icon(Icons.person), label: "Profile"),
          BottomNavigationBarItem(
              icon: Icon(Icons.shop), label: "Shop"),

        ],
      ),
    );
  }
}