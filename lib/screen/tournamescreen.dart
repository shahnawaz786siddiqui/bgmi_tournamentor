import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/tournament_service.dart';

class TournamentScreen extends StatefulWidget {
  const TournamentScreen({super.key});

  @override
  State<TournamentScreen> createState() => _TournamentScreenState();
}

class _TournamentScreenState extends State<TournamentScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor:Color(0xFF221710),

      appBar: AppBar(
        backgroundColor: const Color(0xFF221710),
        title: const Text("BGMI",
        style: TextStyle(color: Colors.white),),
        centerTitle: true,
      ),

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: TournamentService.instance.tournamentsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load tournaments',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No tournaments yet.\nAdd some in Firestore (collection: tournaments).',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final id = docs[index].id;

              return TournamentCard(
                tournamentId: id,
                title: data['title'] ?? 'Tournament',
                time: data['timeLabel'] ?? '',
                prize: _formatCurrency(data['prize']),
                entry: _formatCurrency(data['entryFee'], isEntry: true),
                perKill: _formatCurrency(data['perKill']),
                type: data['type'] ?? 'Solo',
                map: data['map'] ?? 'Erangel',
                version: data['version'] ?? 'TPP',
                totalSlots: (data['totalSlots'] ?? 100) as int,
                joinedPlayers: (data['joinedPlayers'] ?? 0) as int,
                imageUrl: data['imageUrl'] as String? ?? '',
              );
            },
          );
        },
      ),
    );
  }

  String _formatCurrency(dynamic value, {bool isEntry = false}) {
    if (value == null || value.toString().trim().isEmpty) {
      return isEntry ? 'FREE' : '—';
    }
    String strVal = value.toString().trim();
    if (strVal.toUpperCase() == 'FREE') return 'FREE';
    // Remove if already has ₹ to avoid double
    if (strVal.startsWith('₹')) strVal = strVal.substring(1).trim();
    // Return with ₹ prefix
    return '₹$strVal';
  }
}

class TournamentCard extends StatelessWidget {
  final String tournamentId;
  final String title;
  final String time;
  final String prize;
  final String entry;
  final String perKill;
  final String type;
  final String map;
  final String version;
  final String imageUrl;

  final int totalSlots;
  final int joinedPlayers;

  const TournamentCard({
    super.key,
    required this.tournamentId,
    required this.title,
    required this.time,
    required this.prize,
    required this.entry,
    required this.perKill,
    required this.type,
    required this.map,
    required this.version,
    required this.totalSlots,
    required this.joinedPlayers,
    this.imageUrl = '',
  });

  @override
  Widget build(BuildContext context) {

    double progress = joinedPlayers / totalSlots;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF4C260F),
            Color(0xFF763C0E),
            Color(0xFF6E4B12),
            Color(0xFF624916),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),




      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// 🔥 Banner
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Image.asset(
                      "assets/images/my-match.jpg",
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        height: 120,
                        color: const Color(0xFF3B2314),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFF47B25),
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    },
                  )
                : Image.asset(
                    "assets/images/my-match.jpg",
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [

                /// TITLE
                Row(
                  children: [

                    Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          "BB",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          Text(
                            title,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            "Time: $time",
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  ],
                ),

                const SizedBox(height: 14),

                /// PRIZE / PER KILL / ENTRY
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [

                    _infoColumn("PRIZE POOL", prize),

                    _infoColumn("PER KILL", perKill),

                    _infoColumn("ENTRY FEE", entry),
                  ],
                ),

                const SizedBox(height: 14),

                /// TYPE / VERSION / MAP
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [

                    _infoColumn("TYPE", type),

                    _infoColumn("VERSION", version),

                    _infoColumn("MAP", map),
                  ],
                ),

                const SizedBox(height: 14),

                /// PROGRESS
                Row(
                  children: [

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation(
                                Colors.white),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            "Only ${totalSlots - joinedPlayers} Slots Left.",
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12),
                          )
                        ],
                      ),
                    ),

                    const SizedBox(width: 10),

                    Text(
                      "$joinedPlayers/$totalSlots",
                      style: const TextStyle(color: Colors.white),
                    ),

                    const SizedBox(width: 12),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF47B25),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () async {
                        final nameController = TextEditingController();
                        final phoneController = TextEditingController();
                        final result = await showDialog<Map<String, String>>(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              backgroundColor: const Color(0xFF221710),
                              title: const Text(
                                'Confirm Join',
                                style: TextStyle(color: Colors.white),
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Entry fee for this tournament is $entry.\nPlease enter your details to continue.',
                                    style: const TextStyle(color: Colors.white70),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: nameController,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      hintText: "In-Game Name",
                                      hintStyle: const TextStyle(color: Colors.white54),
                                      filled: true,
                                      fillColor: Colors.white10,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  TextField(
                                    controller: phoneController,
                                    style: const TextStyle(color: Colors.white),
                                    keyboardType: TextInputType.phone,
                                    decoration: InputDecoration(
                                      hintText: "Phone Number (For Payouts)",
                                      hintStyle: const TextStyle(color: Colors.white54),
                                      filled: true,
                                      fillColor: Colors.white10,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(null),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop({
                                        'name': nameController.text.trim(),
                                        'phone': phoneController.text.trim()
                                      }),
                                  child: const Text('Pay & Join'),
                                ),
                              ],
                            );
                          },
                        );
                        if (result == null) return;
                        final confirmName = result['name'] ?? '';
                        final confirmPhone = result['phone'] ?? '';

                        if (confirmName.isEmpty || confirmPhone.isEmpty) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter both In-Game Name and Phone Number')),
                            );
                          }
                          return;
                        }
                        if (confirmPhone.length < 10) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter a valid Phone Number')),
                            );
                          }
                          return;
                        }

                        try {
                          await TournamentService.instance
                              .joinTournament(tournamentId, confirmName, confirmPhone);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Joined tournament successfully'),
                              ),
                            );
                          }
                        } on FirebaseException catch (e) {
                          String msg = 'Failed to join tournament';
                          if (e.message == 'ALREADY_JOINED') {
                            msg = 'You have already joined this tournament.';
                          } else if (e.message == 'INSUFFICIENT_FUNDS' ||
                                  e.message?.contains('INSUFFICIENT_FUNDS') == true) {
                            msg = 'Not enough balance to join this tournament.';
                          }
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(msg)),
                            );
                          }
                        }
                      },
                      child: const Text("Join",style: TextStyle(color: Colors.white),),
                    )
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _infoColumn(String title, String value) {

    return Column(
      children: [

        Text(
          title,
          style: const TextStyle(
              color: Colors.white70,
              fontSize: 11),
        ),

        const SizedBox(height: 4),

        Text(
          value,
          style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold),
        )
      ],
    );
  }
}