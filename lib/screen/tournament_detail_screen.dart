import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../services/tournament_service.dart';

class TournamentDetailsScreen extends StatefulWidget {
  const TournamentDetailsScreen({super.key, this.tournamentId});

  final String? tournamentId;

  @override
  State<TournamentDetailsScreen> createState() =>
      _TournamentDetailsScreenState();
}

class _TournamentDetailsScreenState extends State<TournamentDetailsScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFF47B25);
    const darkBg = Color(0xFF221710);

    return Scaffold(
      backgroundColor: darkBg,

      body: Stack(
        children: [

          // ================= MAIN CONTENT =================
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ================= HERO SECTION =================
                Stack(
                  children: [
                    Container(
                      height: 320,
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(
                              "https://lh3.googleusercontent.com/aida-public/AB6AXuDiK1f3holxL6zMj_laVC4yJnSQ4EDDsUulyRJRc17pQ2Ke_cE-XRa8fBmizk9s5cpA80Ad6L5tq9rdr32JdF78QWpxxgEypEnOmuocafi2sCqzk_xPvyAh2BplZl_06iFz0gFD05rHtfBn2ZpiKQd8F-PZqtS4YvdM0Fis7q0xPPi_rKgx-oIr-0YSWZKy5hmtnAALaUmdUj00PnnW37kTHwKWGiBcYbvhHq4e682BWB72ZTQ1VNBFGnX8dvmeaul4Hti0KlfnjhCe"),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    // Gradient overlay
                    Container(
                      height: 320,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            darkBg.withOpacity(0.9)
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),

                    // Content
                    Positioned(
                      bottom: 30,
                      left: 20,
                      right: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Chip(
                            backgroundColor: primaryColor,
                            label: Text(
                              "LIVE REGISTRATION",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            "ELITE SCRIMS",
                            style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          SizedBox(height: 6),
                          Text(
                            "Oct 24, 2024 • 08:00 PM IST",
                            style: TextStyle(
                                color: Colors.white70, fontSize: 12),
                          )
                        ],
                      ),
                    ),

                    // Back Button
                    Positioned(
                      top: 50,
                      left: 16,
                      child: CircleAvatar(
                        backgroundColor: Colors.black45,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back,
                              color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ================= QUICK STATS =================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      statCard("Prize Pool", "₹50,000",
                          primaryColor.withOpacity(0.15), primaryColor),
                      const SizedBox(width: 10),
                      statCard("Slots", "20 / 25",
                          Colors.white10, Colors.white),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ================= PRIZE DISTRIBUTION =================
                sectionTitle("Prize Distribution"),

                const SizedBox(height: 10),

                prizeRow("#1 Winner", "₹25,000", highlight: true),
                prizeRow("#2 Runner Up", "₹12,000"),
                prizeRow("#3 Third Place", "₹8,000"),
                prizeRow("MVP", "₹5,000"),

                const SizedBox(height: 20),

                // ================= RULES =================
                sectionTitle("Tournament Rules"),

                const SizedBox(height: 10),

                ruleItem("No emulators allowed. Only mobile devices."),
                ruleItem("All players must be Level 30+."),
                ruleItem("Hacks or scripts = instant ban."),
                ruleItem("Official ESports point system."),

                const SizedBox(height: 20),

                // ================= MAP SECTION =================
                sectionTitle("Map Details"),

                const SizedBox(height: 10),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Stack(
                    children: [
                      Container(
                        height: 150,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          image: const DecorationImage(
                            image: NetworkImage(
                                "https://lh3.googleusercontent.com/aida-public/AB6AXuBNkF-8IWEVpCxMFSvtNCdKURRNbC0gORmcmkxY2472qZYcvw8U9Bm2-yPki23ZoNBCQtHErJR6L7-c4RNjBlOW95E0k1irk6dFD2UnU8l0M1H9mCkUuzYuD87NK6hZjZtdgdVbQse0d20kvN38_atagDOoOXsSGxAcAIuCqvMPmIvGySl5ifVQFoAs97D_F8-47n1snlv3bLBHkQM40woc1o8zP5yjunsjOF4q5C6Wz6OAR-YaP45eMStRcSD3Lu8iSjPuRziempFp"),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Container(
                        height: 150,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.black45,
                        ),
                        child: const Center(
                          child: Text(
                            "ERANGEL",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 3),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          // ================= IN-GAME NAME INPUT =================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                sectionTitle("Registration Details"),
                const SizedBox(height: 10),
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Enter your In-Game Name",
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white10,
                    prefixIcon: const Icon(Icons.person, color: Colors.white54),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: primaryColor),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Enter Phone Number (For Payouts)",
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white10,
                    prefixIcon: const Icon(Icons.phone, color: Colors.white54),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: primaryColor),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    ),

          // ================= BOTTOM JOIN BAR =================
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                color: darkBg,
                border: Border(
                    top: BorderSide(color: Colors.white12)),
              ),
              child: Row(
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("ENTRY FEE",
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.white60)),
                      Text("FREE",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding:
                        const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(14)),
                      ),
                      onPressed: () async {
                        if (widget.tournamentId == null) return;
                        final inGameName = _nameController.text.trim();
                        final phoneStr = _phoneController.text.trim();

                        if (inGameName.isEmpty || phoneStr.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter both In-Game Name and Phone Number'),
                            ),
                          );
                          return;
                        }
                        if (phoneStr.length < 10) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a valid Phone Number'),
                            ),
                          );
                          return;
                        }

                        try {
                          await TournamentService.instance
                              .joinTournament(widget.tournamentId!, inGameName, phoneStr);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Joined tournament successfully!'),
                              ),
                            );
                            Navigator.pop(context); // Optional: go back after joining
                          }
                        } on FirebaseException catch (e) {
                          String msg = 'Failed to join tournament';
                          if (e.message == 'ALREADY_JOINED') {
                            msg = 'You have already joined this tournament.';
                          } else if (e.message == 'INSUFFICIENT_FUNDS' ||
                                  e.message?.contains('INSUFFICIENT_FUNDS') == true) {
                            msg = 'Not enough balance to join this tournament.';
                          }
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(msg)),
                            );
                          }
                        }
                      },
                      child: const Row(
                        mainAxisAlignment:
                        MainAxisAlignment.center,
                        children: [
                          Text("JOIN TOURNAMENT",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold)),
                          SizedBox(width: 6),
                          Icon(Icons.bolt)
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= REUSABLE WIDGETS =================

  Widget statCard(String title, String value,
      Color bgColor, Color textColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white60)),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor)),
          ],
        ),
      ),
    );
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(title,
          style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white)),
    );
  }

  Widget prizeRow(String rank, String prize,
      {bool highlight = false}) {
    return Container(
      margin:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlight
            ? const Color(0xFFF47B25).withOpacity(0.15)
            : Colors.white10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment:
        MainAxisAlignment.spaceBetween,
        children: [
          Text(rank,
              style: TextStyle(
                  color: highlight
                      ? const Color(0xFFF47B25)
                      : Colors.white)),
          Text(prize,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: highlight
                      ? const Color(0xFFF47B25)
                      : Colors.white)),
        ],
      ),
    );
  }

  Widget ruleItem(String text) {
    return Padding(
      padding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          const Text("• ",
              style: TextStyle(
                  color: Color(0xFFF47B25),
                  fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13)),
          )
        ],
      ),
    );
  }
}