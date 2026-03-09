import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/tournament_service.dart';
import '../AdminPanel/admin_login_screen.dart';
import 'shop.dart';

class WarriorProfileScreen extends StatefulWidget {
  const WarriorProfileScreen({super.key});

  @override
  State<WarriorProfileScreen> createState() => _WarriorProfileScreenState();
}

class _WarriorProfileScreenState extends State<WarriorProfileScreen> {
  @override
  void initState() {
    super.initState();
    TournamentService.instance.ensureUser();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFf47b25);
    const darkBg = Color(0xFF221710);

    return Scaffold(
      backgroundColor: darkBg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              /// HEADER
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.arrow_back, color: Colors.white),

                    const Expanded(
                      child: Center(
                        child: Text(
                          "Warrior Profile",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const Icon(Icons.settings, color: Colors.white),
                  ],
                ),
              ),

              /// PROFILE SECTION
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    /// Wallet balance card
                    StreamBuilder<double>(
                      stream: TournamentService.instance.balanceStream(),
                      builder: (context, snapshot) {
                        final balance = snapshot.data ?? 0.0;
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B2314),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: primaryColor.withOpacity(0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Wallet Balance",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "₹${balance.toStringAsFixed(0)}",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              TextButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const ShopScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.add_circle_outline,
                                  color: primaryColor,
                                  size: 20,
                                ),
                                label: const Text(
                                  "Top up",
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    Container(
                      height: 120,
                      width: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: primaryColor, width: 4),
                        image: const DecorationImage(
                          image: NetworkImage(
                            "https://images.unsplash.com/photo-1542751371-adc38448a05e",
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).get(),
                      builder: (context, snapshot) {
                        String userName = "Warrior";
                        if (snapshot.hasData && snapshot.data!.exists) {
                          final data = snapshot.data!.data() as Map<String, dynamic>;
                          userName = data['name'] ?? "Warrior";
                        }
                        return Text(
                          userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }
                    ),

                    const SizedBox(height: 6),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.military_tech,
                          color: primaryColor,
                          size: 18,
                        ),
                        SizedBox(width: 6),
                        Text(
                          "CONQUEROR",
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        minimumSize: const Size(double.infinity, 45),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Profile editing coming soon!')),
                        );
                      },
                      child: const Text("Edit Profile"),
                    ),

                    const SizedBox(height: 12),

                    /// ⭐ EARN BUTTON (NEW)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        minimumSize: const Size(double.infinity, 45),
                      ),
                      icon: const Icon(Icons.currency_rupee),
                      label: const Text("Earn Money"),
                      onPressed: () {
                        /// NAVIGATE TO EARN SCREEN
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EarnScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    /// ADMIN PANEL BUTTON
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A1A1A),
                        minimumSize: const Size(double.infinity, 45),
                        side: const BorderSide(color: Color(0xFFF47B25), width: 1.2),
                      ),
                      icon: const Icon(Icons.admin_panel_settings,
                          color: Color(0xFFF47B25), size: 20),
                      label: const Text(
                        "Admin Panel",
                        style: TextStyle(
                          color: Color(0xFFF47B25),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () => openAdminPanel(context),
                    ),

                    const SizedBox(height: 12),

                    /// LOGOUT BUTTON
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B2314),
                        minimumSize: const Size(double.infinity, 45),
                        side: const BorderSide(color: primaryColor),
                      ),
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        // AuthGate in main.dart listens to auth changes and
                        // will automatically show the login screen.
                      },
                      child: const Text(
                        "Logout",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EarnScreen extends StatelessWidget {
  const EarnScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF221710),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3B2314),
        elevation: 0,
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                "BB",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "BGMI Tournamentor",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Your First Step To Esports",
                    style: TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const Spacer(),
            const Icon(Icons.notifications, color: Colors.white),
            const SizedBox(width: 12),
            StreamBuilder<double>(
              stream: TournamentService.instance.balanceStream(),
              builder: (context, snapshot) {
                final balance = snapshot.data ?? 0.0;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "₹${balance.toStringAsFixed(0)}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GestureDetector(
            onTap: () => _showComingSoon(context),
            child: _earnCard(
              title: "Refer and Earn",
              subtitle: "Invite to your friends to this app and Earn Huge!",
              icon: Icons.people,
              colors: [const Color(0xFF3AC569), const Color(0xFF1C7C54)],
            ),
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: () => _showComingSoon(context),
            child: _earnCard(
              title: "Watch and Earn",
              subtitle: "Watch reward video and Earn!",
              icon: Icons.play_circle_fill,
              colors: [const Color(0xFF2F6BFF), const Color(0xFF3B82F6)],
            ),
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: () => _showComingSoon(context),
            child: _earnCard(
              title: "Lucky Draw",
              subtitle: "Buy lottery ticket and try your luck!",
              icon: Icons.emoji_events,
              colors: [const Color(0xFF6A11CB), const Color(0xFFCB218E)],
            ),
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: () => _showComingSoon(context),
            child: _earnCard(
              title: "Play and Earn",
              subtitle: "Join Tournament and Earn Real Cash!",
              icon: Icons.sports_esports,
              colors: [const Color(0xFF2196F3), const Color(0xFF6A11CB)],
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('This feature is coming soon!')),
    );
  }

  Widget _earnCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> colors,
  }) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              height: 70,
              width: 70,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 36),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
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
