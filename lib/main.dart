import 'package:bgmi_tournamentor/AdminPanel/admin_login_screen.dart';
import 'package:bgmi_tournamentor/AdminPanel/admin_panel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'bottomnavigationbar/bottom_navigation_bar.dart';
import 'featureevent/feature_events.dart';
import 'featureevent/upcoming_tournament.dart';
import 'auth/login_screen.dart';
import 'firebase_options.dart';
import 'headersection/header_section.dart';
import 'herobanner/hero_banner.dart';

// ── Android notification channel ──────────────────────────────────────────────
const AndroidNotificationChannel _channel = AndroidNotificationChannel(
  'bgmi_tournament_channel',       // id — must match FCM channel_id in payload
  'BGMI Tournament Alerts',        // name shown in Android settings
  description: 'Notifications for BGMI tournament updates, room IDs and more.',
  importance: Importance.max,
  playSound: true,
  enableLights: true,
);

// ── Local notifications plugin instance ───────────────────────────────────────
final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

// ── BACKGROUND / TERMINATED handler — MUST be a top-level function ────────────
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialised by the OS before this runs.
  // We MUST initialize FlutterLocalNotificationsPlugin here because this
  // background isolate does not share the initialized instance from main().
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  await _localNotifications.initialize(
    const InitializationSettings(android: androidInit),
  );

  // Show a local notification so the user sees a banner even when the app
  // is completely killed and FCM delivers a *data-only* message.
  await _showLocalNotification(message);
}

// ── Helper: show a banner via flutter_local_notifications ─────────────────────
Future<void> _showLocalNotification(RemoteMessage message) async {
  final notification = message.notification;
  final title = notification?.title ?? message.data['title'] ?? 'BGMI Tournamentor';
  final body  = notification?.body  ?? message.data['body']  ?? '';

  await _localNotifications.show(
    message.hashCode,
    title,
    body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        channelDescription: _channel.description,
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFFF47B25),
        playSound: true,
        enableLights: true,
      ),
    ),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ── Register the background message handler ─────────────────────────────────
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // ── Initialise flutter_local_notifications ──────────────────────────────────
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  await _localNotifications.initialize(
    const InitializationSettings(android: androidInit),
  );

  // Create the high-importance channel on Android 8+
  await _localNotifications
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(_channel);

  // ── FCM: request permission ─────────────────────────────────────────────────
  final messaging = FirebaseMessaging.instance;
  
  // Do not await permission request to avoid blocking runApp() on a black screen.
  messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  ).then((_) {
    // ── Subscribe to broadcast topic so admin can push to all users ─────────────
    messaging.subscribeToTopic('all_users');
  });

  // ── FOREGROUND message handler — show a local notification banner ───────────
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    _showLocalNotification(message);
  });

  // ── Save / refresh FCM token in Firestore ───────────────────────────────────
  FirebaseAuth.instance.authStateChanges().listen((user) async {
    if (user != null) {
      final token = await messaging.getToken();
      if (token != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({'fcmToken': token}, SetOptions(merge: true));
      }
    }
  });

  messaging.onTokenRefresh.listen((newToken) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'fcmToken': newToken}, SetOptions(merge: true));
    }
  });

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
        fontFamily: "SpaceGrotesk",
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