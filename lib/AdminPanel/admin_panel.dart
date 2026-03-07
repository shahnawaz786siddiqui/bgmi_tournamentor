import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'admin_manage_users_screen.dart';
import 'admin_payouts_screen.dart';
import 'admin_settings_screen.dart';
import 'admin_tournament_editor.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {

  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFF47B25);
    const darkBg = Color(0xFF121212);

    return Scaffold(
      backgroundColor: darkBg,

      // ================= PREMIUM APP BAR =================
      appBar: _currentIndex != 0 ? null : PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          padding: const EdgeInsets.only(top: 40, left: 16, right: 16),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E1E1E), Color(0xFF121212)],
            ),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 22,
                backgroundColor: primaryColor,
                child: Icon(Icons.admin_panel_settings,
                    color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Admin Console",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18)),
                  SizedBox(height: 2),
                  Text("Tournament Master",
                      style: TextStyle(
                          color: primaryColor,
                          fontSize: 12)),
                ],
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.notifications,
                    color: primaryColor),
                onPressed: () {},
              )
            ],
          ),
        ),
      ),

      body: IndexedStack(
        index: _currentIndex,
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [

            // ================= STATS =================
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, usersSnapshot) {
                final totalUsers = usersSnapshot.hasData ? usersSnapshot.data!.docs.length : 0;
                
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('tournaments').snapshots(),
                  builder: (context, tourneysSnapshot) {
                    final tourneyDocs = tourneysSnapshot.data?.docs ?? [];
                    final activeTourneys = tourneyDocs.length; // Simply counting all tournaments for now
                    
                    // Basic revenue calculation: sum of (joinedPlayers * entryFee)
                    double totalRevenue = 0;
                    for (var doc in tourneyDocs) {
                      final data = doc.data() as Map<String, dynamic>;
                      final joined = data['joinedPlayers'] ?? 0;
                      final entryRaw = data['entryFee']?.toString().replaceAll(RegExp(r'[^0-9.]'), '') ?? '0';
                      final entryFee = double.tryParse(entryRaw) ?? 0;
                      totalRevenue += (joined * entryFee);
                    }
                    
                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('payouts').where('status', isEqualTo: 'Pending').snapshots(),
                      builder: (context, payoutsSnapshot) {
                        final payoutDocs = payoutsSnapshot.data?.docs ?? [];
                        double pendingPayouts = 0;
                        for (var doc in payoutDocs) {
                          final data = doc.data() as Map<String, dynamic>;
                          final amountRaw = data['amount'] ?? 0;
                          final amount = (amountRaw is int) ? amountRaw.toDouble() : (amountRaw as num).toDouble();
                          pendingPayouts += amount;
                        }

                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 1.1,
                          children: [
                            GlowStatCard("Total Users", "$totalUsers", Icons.group),
                            GlowStatCard("Active Tourneys", "$activeTourneys", Icons.sports_esports),
                            GlowStatCard("Revenue", "₹${_formatCompactNumber(totalRevenue)}", Icons.payments),
                            GlowStatCard("Pending Payouts", "₹${_formatCompactNumber(pendingPayouts)}", Icons.account_balance_wallet),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 30),

            // ================= TOURNAMENT SECTION =================
            sectionTitle("Live Tournaments"),

            const SizedBox(height: 15),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('tournaments')
                  .orderBy('startTime', descending: true)
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFF47B25)),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Text(
                    "No Live Tournaments",
                    style: TextStyle(color: Colors.white70),
                  );
                }

                return Column(
                  children: docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final title = data['title'] ?? 'Tournament';
                    final slots = data['joinedPlayers'] ?? 0;
                    final totalSlots = data['totalSlots'] ?? 100;
                    final entry = data['entryFee'] ?? 'Free';
                    return PremiumTournamentCard(
                      title: title,
                      slots: slots,
                      totalSlots: totalSlots,
                      entry: entry,
                      status: "LIVE",
                      color: Colors.green,
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 30),

            // ================= QUICK ACTION =================
            sectionTitle("Quick Actions"),

            const SizedBox(height: 15),

            SizedBox(
              height: 110,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ActionCard(
                    Icons.add_circle,
                    "Create\nTournament",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminTournamentEditorScreen(),
                        ),
                      );
                    },
                  ),
                  ActionCard(
                    Icons.person_search,
                    "Manage\nUsers",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminManageUsersScreen(),
                        ),
                      );
                    },
                  ),
                  ActionCard(
                    Icons.payments,
                    "Approve\nPayouts",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminPayoutsScreen(),
                        ),
                      );
                    },
                  ),
                  ActionCard(
                    Icons.settings,
                    "Settings",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminSettingsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const AdminTournamentEditorScreen(),
      const AdminManageUsersScreen(),
      const AdminPayoutsScreen(),
    ],
  ),

      // ================= PREMIUM BOTTOM NAV =================
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E1E1E), Color(0xFF121212)],
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          backgroundColor: Colors.transparent,
          selectedItemColor: primaryColor,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.dashboard), label: "Home"),
            BottomNavigationBarItem(
                icon: Icon(Icons.sports_esports), label: "Tournaments"),
            BottomNavigationBarItem(
                icon: Icon(Icons.group), label: "Players"),
            BottomNavigationBarItem(
                icon: Icon(Icons.account_balance), label: "Finance"),
          ],
        ),
      ),
    );
  }

  Widget sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(title,
          style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18)),
    );
  }

  String _formatCompactNumber(double number) {
    if (number >= 100000) {
      return '${(number / 100000).toStringAsFixed(1)}L';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    } else {
      return number.toStringAsFixed(0);
    }
  }
}

// ================= GLOW STAT CARD =================

class GlowStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const GlowStatCard(this.title, this.value, this.icon, {super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFF47B25);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.4),
            blurRadius: 15,
            spreadRadius: 1,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primaryColor),
          const Spacer(),
          Text(title,
              style: const TextStyle(
                  color: Colors.white60, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ================= PREMIUM TOURNAMENT CARD =================

class PremiumTournamentCard extends StatelessWidget {
  final String title;
  final int slots;
  final int totalSlots;
  final String entry;
  final String status;
  final Color color;

  const PremiumTournamentCard({
    super.key,
    required this.title,
    required this.slots,
    required this.totalSlots,
    required this.entry,
    required this.status,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    double progress = slots / totalSlots;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events,
                  color: Color(0xFFF47B25)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(status,
                    style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const SizedBox(height: 12),
          Text("Entry: $entry",
              style: const TextStyle(
                  color: Colors.white60, fontSize: 12)),
          const SizedBox(height: 6),
          Text("Slots: $slots / $totalSlots",
              style: const TextStyle(
                  color: Colors.white60, fontSize: 12)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white12,
              color: const Color(0xFFF47B25),
            ),
          )
        ],
      ),
    );
  }
}

// ================= ACTION CARD =================

class ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const ActionCard(this.icon, this.label, {super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFF47B25);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.3),
              blurRadius: 10,
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: primaryColor, size: 30),
            const SizedBox(height: 10),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}