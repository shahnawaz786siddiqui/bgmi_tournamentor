import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:bgmi_tournamentor/screen/tournament_detail_screen.dart';
import 'package:bgmi_tournamentor/screen/tournamescreen.dart';

class FeaturedSection extends StatelessWidget {
  const FeaturedSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Featured Events",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: "SpaceGrotesk",
                      color: Colors.white),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TournamentScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    "View All ",
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF47B25),
                        fontFamily: "SpaceGrotesk"),
                  ),
                )
              ],
            ),
          ),
        ),
        SizedBox(
          height: 185,
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('tournaments')
                .where('isFeatured', isEqualTo: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Center(
                  child: Text(
                    'No featured events',
                    style: TextStyle(color: Colors.white70),
                  ),
                );
              }
              return ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: docs.map((doc) {
                  final data = doc.data();
                  final title = data['title'] ?? 'Tournament';
                  final subtitle = data['timeLabel'] ?? '';
                  final imageUrl = data['imageUrl'] ??
                      'https://images.unsplash.com/photo-1511512578047-dfb367046420';
                  return FeaturedCard(
                    tournamentId: doc.id,
                    title: title,
                    subtitle: subtitle,
                    imageUrl: imageUrl,
                  );
                }).toList(),
              );
            },
          ),
        )
      ],
    );
  }
}

class FeaturedCard extends StatelessWidget {
  final String tournamentId;
  final String title;
  final String subtitle;
  final String imageUrl;

  const FeaturedCard({
    super.key,
    required this.tournamentId,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TournamentDetailsScreen(
              tournamentId: tournamentId,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 250,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              height: 130,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: "SpaceGrotesk",
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                color: Color(0xFFF47B25),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                fontFamily: "SpaceGrotesk",
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
