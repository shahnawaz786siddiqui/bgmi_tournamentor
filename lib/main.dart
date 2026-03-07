
import 'package:bgmi_tournamentor/AdminPanel/admin_panel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'bottomnavigationbar/bottom_navigation_bar.dart';
import 'featureevent/feature_events.dart';
import 'featureevent/upcoming_tournament.dart';
import 'auth/login_screen.dart';
import 'firebase_options.dart';
import 'headersection/header_section.dart';
import 'herobanner/hero_banner.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

const primaryColor = Color(0xFFF47B25);
const backgroundDark = Color(0xFFF8F7F5);
const backgroundLight = Color(0xFF221710);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: backgroundLight,
        fontFamily:  "SpaceGrotesk",
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: backgroundLight,
            body: Center(
              child: CircularProgressIndicator(color: primaryColor),
            ),
          );
        }
        if (snapshot.hasData) {
          return const BottomNav();
        }
        return const LoginScreen();
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const HeaderSection(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: const [
                    HeroBanner(),
                    FeaturedSection(),
                    UpcomingSection(),

                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}