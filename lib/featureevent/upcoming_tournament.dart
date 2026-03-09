
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
                  child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final allDocs = snapshot.data?.docs ?? [];
              final docs = allDocs.where((doc) {
                final data = doc.data();
                var isUpcoming = data['isUpcoming'];
                bool finalIsUpcoming = true; // default
                if(isUpcoming is bool) {
                  finalIsUpcoming = isUpcoming;
                } else if(isUpcoming is String) {
                  finalIsUpcoming = isUpcoming.toLowerCase() == 'true';
                }
                print("DEBUG: ${doc.id} -> isUpcoming: $finalIsUpcoming (Raw: $isUpcoming)");
                return finalIsUpcoming;
              }).toList();
              
              print("DEBUG: Total Upcoming Docs count: ${docs.length}");

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
                    prize: _formatCurrency(data['prize']),
                    entry: _formatCurrency(data['entryFee'], isEntry: true),
                    time: data['timeLabel'] ?? '',
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatCurrency(dynamic value, {bool isEntry = false}) {
    if (value == null || value.toString().trim().isEmpty) {
      return isEntry ? 'FREE' : '—';
    }
    String strVal = value.toString().trim();
    if (strVal.toUpperCase() == 'FREE') return 'FREE';
    if (strVal.startsWith('₹')) strVal = strVal.substring(1).trim();
    return '₹$strVal';
  }
}

class TournamentCard extends StatelessWidget {
  final String tournamentId;
  final String title;
  final String prize;
  final String entry;
  final String time;

  const TournamentCard({
    super.key,
    required this.tournamentId,
    required this.title,
    required this.prize,
    required this.entry,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(   // 🔥 Gradient added
          colors: [
            Color(0xFF3B2314),
        Color(0xFF5D412A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: const Color(0xFF3A2419),
        ),
      ),
      child: Row(
        children: [

          /// 🔥 Map Image Box
          Container(
            height: 70,
            width: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: const DecorationImage(
                image: AssetImage("assets/images/map.png"), // 👈 apni image lagao
                fit: BoxFit.cover,
              ),
            ),
          ),

          const SizedBox(width: 14),

          /// 🔥 Title + Prize + Entry
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// Title
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Row(
                  children: [

                    /// Prize
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "PRIZE POOL",
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        Text(
                          prize,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF8C42), // 🔥 Orange
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(width: 24),

                    /// Entry
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "ENTRY",
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        Text(
                          entry,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          /// 🔥 Time + Join Button
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [

              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF3A2419),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  time,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFFF8C42),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                height: 36,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8C42), // 🔥 Orange
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TournamentDetailsScreen(
                          tournamentId: tournamentId,
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    "Join",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
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