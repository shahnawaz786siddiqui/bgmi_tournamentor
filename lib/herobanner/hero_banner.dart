import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import 'package:bgmi_tournamentor/screen/tournament_detail_screen.dart';

class HeroBanner extends StatelessWidget {
  const HeroBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('tournaments')
          .where('isMega', isEqualTo: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        final doc = snapshot.data?.docs.isNotEmpty == true
            ? snapshot.data!.docs.first
            : null;

        final data = doc?.data() ?? {};
        final id = doc?.id;
        final title = data['title'] ?? 'Mega Tournament';
        final prize = data['prize'] ?? 'Win Big Prize Pool';
        final imageUrl = data['imageUrl'] ??
            'https://images.unsplash.com/photo-1542751371-adc38448a05e';

        return Container(
          margin: const EdgeInsets.all(16),
          height: 220,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(0),
            image: DecorationImage(
              image: NetworkImage(imageUrl),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.8),
                  Colors.transparent
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  "Mega Tournament",
                  style: TextStyle(
                      color: primaryColor,
                      fontFamily: "SpaceGrotesk",
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  prize,
                  style: const TextStyle(
                      color: Colors.white,
                      fontFamily: "SpaceGrotesk",
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontFamily: "SpaceGrotesk",
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(2)),
                      ),
                      onPressed: id == null
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TournamentDetailsScreen(
                                    tournamentId: id,
                                  ),
                                ),
                              );
                            },
                      child: const Text(
                        "Register",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(2))),
                      onPressed: id == null
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TournamentDetailsScreen(
                                    tournamentId: id,
                                  ),
                                ),
                              );
                            },
                      child: const Text("Details"),
                    )
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }
}