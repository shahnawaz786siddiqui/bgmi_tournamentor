import 'package:flutter/material.dart';
import '../services/tournament_service.dart';

class MyMatchesScreen extends StatefulWidget {
  const MyMatchesScreen({super.key});

  @override
  State<MyMatchesScreen> createState() => _MyMatchesScreenState();
}

class _MyMatchesScreenState extends State<MyMatchesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final Color primaryColor = const Color(0xFFf47b25);
  final Color darkBg = const Color(0xFF221710);

  @override
  void initState() {
    _tabController = TabController(length: 3, vsync: this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBg,
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: TournamentService.instance.myTournamentsStream(),
          builder: (context, snapshot) {
            final isLoading = snapshot.connectionState == ConnectionState.waiting;
            final matches = snapshot.data ?? [];

            final ongoingMatches = matches.where((m) => m['status'] == 'LIVE' || m['status'] == 'ONGOING').toList();
            // Defaulting unlabelled matches to upcoming if they aren't marked completed or ongoing.
            final upcomingMatches = matches.where((m) => m['status'] == null || m['status'] == 'UPCOMING' || m['status'] == 'PENDING').toList();
            final completedMatches = matches.where((m) => m['status'] == 'COMPLETED').toList();

            return Column(
              children: [

                /// HEADER
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  decoration: BoxDecoration(
                    color: darkBg,
                    border: Border(
                      bottom: BorderSide(color: primaryColor.withOpacity(.15)),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.arrow_back, color: Colors.white),
                          const SizedBox(width: 12),
                          const Text(
                            "My Matches",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const Icon(Icons.notifications, color: Colors.white)
                    ],
                  ),
                ),

                /// TABS
                TabBar(
                  controller: _tabController,
                  indicatorColor: primaryColor,
                  labelColor: primaryColor,
                  unselectedLabelColor: Colors.grey,
                  tabs: [
                    Tab(text: "Ongoing (${ongoingMatches.length})"),
                    Tab(text: "Upcoming (${upcomingMatches.length})"),
                    Tab(text: "Completed (${completedMatches.length})"),
                  ],
                ),

                /// BODY
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFFf47b25)))
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildMatchList(ongoingMatches, "No Ongoing Matches"),
                            _buildMatchList(upcomingMatches, "No Upcoming Matches"),
                            _buildMatchList(completedMatches, "No Completed Matches"),
                          ],
                        ),
                ),
              ],
            );
          }
        ),
      ),
    );
  }

  Widget _buildMatchList(List<Map<String, dynamic>> matches, String emptyMessage) {
    if (matches.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: matches.length,
      itemBuilder: (context, index) {
        final match = matches[index];
        final title = match['title'] ?? 'Tournament';
        final timeLabel = match['timeLabel'] ?? 'TBA';
        final prize = match['prize'] ?? '₹0';
        final entry = match['entryFee'] ?? 'Free';
        final perKill = match['perKill'] ?? '₹0';
        final type = match['type'] ?? 'Solo';
        final map = match['map'] ?? 'Erangel';
        final version = match['version'] ?? 'TPP';
        final totalSlots = match['totalSlots'] ?? 100;
        final joinedPlayers = match['joinedPlayers'] ?? 0;

        return _tournamentCard(
          title: title,
          time: timeLabel,
          prize: prize,
          entry: entry,
          perKill: perKill,
          type: type,
          map: map,
          version: version,
          totalSlots: totalSlots,
          joinedPlayers: joinedPlayers,
        );
      },
    );
  }

  /// TOURNAMENT STYLE CARD
  Widget _tournamentCard({
    required String title,
    required String time,
    required String prize,
    required String entry,
    required String perKill,
    required String type,
    required String map,
    required String version,
    required int totalSlots,
    required int joinedPlayers,
  }) {
    double progress = joinedPlayers / totalSlots;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF4C260A),
            Color(0xFF763C0E),
            Color(0xFF795720),
            Color(0xFF624916),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [

          /// BANNER
          ClipRRect(
            borderRadius:
            const BorderRadius.vertical(top: Radius.circular(14)),
            child: Image.asset(
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

                /// TITLE ROW
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
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          Text("Time: $time",
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12)),
                        ],
                      ),
                    )
                  ],
                ),

                const SizedBox(height: 14),

                /// PRIZE / PER KILL / ENTRY
                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: [
                    _info("PRIZE POOL", prize),
                    _info("PER KILL", perKill),
                    _info("ENTRY FEE", entry),
                  ],
                ),

                const SizedBox(height: 14),

                /// TYPE / VERSION / MAP
                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: [
                    _info("TYPE", type),
                    _info("VERSION", version),
                    _info("MAP", map),
                  ],
                ),

                const SizedBox(height: 14),

                /// PROGRESS
                Row(
                  children: [

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.white24,
                            valueColor:
                            const AlwaysStoppedAnimation(
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
                      style:
                      const TextStyle(color: Colors.white),
                    ),

                    const SizedBox(width: 12),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(2)
                        )
                      ),
                      onPressed: () {},
                      child: const Text("Joined",
                      style: TextStyle(color: Colors.white),),
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

  Widget _info(String title, String value) {
    return Column(
      children: [
        Text(title,
            style: const TextStyle(
                color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold)),
      ],
    );
  }
}