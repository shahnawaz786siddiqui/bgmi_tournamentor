import 'package:bgmi_tournamentor/screen/tournament_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/tournament_service.dart';

class UpcomingSection extends StatelessWidget {
  const UpcomingSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "UPCOMING TOURNAMENTS",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 20,
              fontFamily: "SpaceGrotesk",
            ),
          ),
          const SizedBox(height: 10),

          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: TournamentService.instance.tournamentsStream(),
            builder: (context, snapshot) {

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data?.docs ?? [];

              if (docs.isEmpty) {
                return const Text(
                  'No upcoming tournaments',
                  style: TextStyle(color: Colors.white70),
                );
              }

              return Column(
                children: docs.take(3).map((doc) {

                  final data = doc.data();

                  return TournamentCard(
                    tournamentId: doc.id,
                    title: data['title'] ?? 'Tournament',
                    prize: data['prize']?.toString() ?? '0',
                    entry: data['entryFee']?.toString() ?? 'FREE',
                    time: data['timeLabel'] ?? '',
                    mapImageUrl: data['mapImageUrl'] ?? '',
                  );

                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class TournamentCard extends StatelessWidget {

  final String tournamentId;
  final String title;
  final String prize;
  final String entry;
  final String time;
  final String mapImageUrl;

  const TournamentCard({
    super.key,
    required this.tournamentId,
    required this.title,
    required this.prize,
    required this.entry,
    required this.time,
    this.mapImageUrl = '',
  });

  @override
  Widget build(BuildContext context) {

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF3B2314),
            Color(0xFF5D412A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFF3A2419)),
      ),

      child: Row(
        children: [

          /// MAP IMAGE
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image(
              height: 65,
              width: 65,
              fit: BoxFit.cover,
              image: mapImageUrl.isNotEmpty
                  ? NetworkImage(mapImageUrl)
                  : const AssetImage('assets/images/map.png')
              as ImageProvider,
            ),
          ),

          const SizedBox(width: 12),

          /// CENTER CONTENT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// TITLE
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                /// PRIZE + ENTRY (AUTO RESPONSIVE)
                Wrap(
                  spacing: 18,
                  runSpacing: 4,
                  children: [

                    /// PRIZE
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [

                        const Text(
                          "Prize: ",
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF94A3B8),
                          ),
                        ),

                        Text(
                          "₹$prize",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF8C42),
                          ),
                        ),
                      ],
                    ),

                    /// ENTRY
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [

                        const Text(
                          "Entry: ",
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF94A3B8),
                          ),
                        ),

                        Text(
                          entry == "FREE" ? "FREE" : "₹$entry",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          /// RIGHT SIDE
          Column(
            children: [

              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF3A2419),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  time,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFFF8C42),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 6),

              SizedBox(
                height: 30,
                width: 70,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8C42),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  onPressed: () {

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            TournamentDetailsScreen(
                              tournamentId: tournamentId,
                            ),
                      ),
                    );

                  },
                  child: const Text(
                    "Join",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}