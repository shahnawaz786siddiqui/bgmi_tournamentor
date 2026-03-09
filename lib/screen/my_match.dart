import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
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
  Stream<List<Map<String, dynamic>>>? _stream;
  StreamSubscription<User?>? _authSub;

  final Color primaryColor = const Color(0xFFf47b25);
  final Color darkBg = const Color(0xFF221710);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initStream();

    // Re-init stream whenever auth state changes (login/logout)
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      _initStream();
    });
  }

  void _initStream() {
    if (mounted) {
      setState(() {
        _stream = TournamentService.instance.myTournamentsStream();
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBg,
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _stream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              );
            }

            final isLoading = snapshot.connectionState == ConnectionState.waiting;
            final matches = snapshot.data ?? [];

            final uid = FirebaseAuth.instance.currentUser?.uid ?? 'NOT LOGGED IN';

            String getStatus(Map<String, dynamic> m) =>
                (m['status'] ?? '').toString().toUpperCase().trim();

            final ongoingMatches = matches
                .where((m) =>
                    getStatus(m) == 'LIVE' || getStatus(m) == 'ONGOING')
                .toList();
            final upcomingMatches = matches
                .where((m) =>
                    getStatus(m) == 'UPCOMING' ||
                    getStatus(m) == 'PENDING' ||
                    getStatus(m).isEmpty)
                .toList();
            final completedMatches = matches
                .where((m) => getStatus(m) == 'COMPLETED')
                .toList();

            return Column(
              children: [
                /// HEADER
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  decoration: BoxDecoration(
                    color: darkBg,
                    border: Border(
                      bottom:
                          BorderSide(color: primaryColor.withValues(alpha: 0.15)),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.sports_martial_arts, color: Colors.white),
                          SizedBox(width: 12),
                          Text(
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

                /// DEBUG INFO (shows UID + total matches found)
                Container(
                  color: Colors.black26,
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Text(
                    isLoading
                        ? 'Loading your matches...'
                        : 'Found ${matches.length} registered match(es) • UID: ${uid.length > 10 ? uid.substring(0, 10) : uid}',
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                ),

                /// TABS
                TabBar(
                  controller: _tabController,
                  indicatorColor: primaryColor,
                  labelColor: primaryColor,
                  unselectedLabelColor: Colors.grey,
                  tabs: [
                    Tab(text: "Upcoming (${upcomingMatches.length})"),
                    Tab(text: "Ongoing (${ongoingMatches.length})"),
                    Tab(text: "Completed (${completedMatches.length})"),
                  ],
                ),

                /// BODY
                Expanded(
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFf47b25),
                          ),
                        )
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildMatchList(upcomingMatches, "No Upcoming Matches\nJoin a tournament to see it here."),
                            _buildMatchList(ongoingMatches, "No Ongoing Matches"),
                            _buildMatchList(completedMatches, "No Completed Matches"),
                          ],
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMatchList(List<Map<String, dynamic>> matches, String emptyMessage) {
    if (matches.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey, fontSize: 15),
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
        final prize = _formatCurrency(match['prize']);
        final entry = _formatCurrency(match['entryFee'], isEntry: true);
        final perKill = _formatCurrency(match['perKill']);
        final type = match['type'] ?? 'Solo';
        final mapName = match['map'] ?? 'Erangel';
        final version = match['version'] ?? 'TPP';
        final totalSlots = (match['totalSlots'] ?? 100) as int;
        final joinedPlayers = (match['joinedPlayers'] ?? 0) as int;
        final status = (match['status'] ?? 'UPCOMING').toString().toUpperCase();
        final roomId = match['roomId']?.toString() ?? '';
        final roomPassword = match['roomPassword']?.toString() ?? '';

        return _tournamentCard(
          title: title,
          time: timeLabel,
          prize: prize,
          entry: entry,
          perKill: perKill,
          type: type,
          mapName: mapName,
          version: version,
          totalSlots: totalSlots,
          joinedPlayers: joinedPlayers,
          status: status,
          roomId: roomId,
          roomPassword: roomPassword,
        );
      },
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

  Widget _tournamentCard({
    required String title,
    required String time,
    required String prize,
    required String entry,
    required String perKill,
    required String type,
    required String mapName,
    required String version,
    required int totalSlots,
    required int joinedPlayers,
    required String status,
    String roomId = '',
    String roomPassword = '',
  }) {
    final double progress =
        totalSlots > 0 ? (joinedPlayers / totalSlots).clamp(0.0, 1.0) : 0;

    Color statusColor = primaryColor;
    if (status == 'LIVE' || status == 'ONGOING') statusColor = Colors.green;
    if (status == 'COMPLETED') statusColor = Colors.grey;

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
              errorBuilder: (context, error, stackTrace) => Container(
                height: 120,
                color: const Color(0xFF3B2314),
                child: const Icon(Icons.sports_esports,
                    color: Colors.white54, size: 48),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                /// TITLE ROW + STATUS BADGE
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
                          Text(title,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                          Text("Time: $time",
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.2),
                        border: Border.all(color: statusColor),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                /// PRIZE / PER KILL / ENTRY
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _info("PRIZE POOL", prize),
                    _info("PER KILL", perKill),
                    _info("ENTRY FEE", entry),
                  ],
                ),

                const SizedBox(height: 14),

                /// TYPE / VERSION / MAP
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _info("TYPE", type),
                    _info("VERSION", version),
                    _info("MAP", mapName),
                  ],
                ),

                const SizedBox(height: 14),

                /// PROGRESS + JOINED BUTTON
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.white24,
                            valueColor:
                                const AlwaysStoppedAnimation(Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Only ${totalSlots - joinedPlayers} Slots Left",
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12),
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        "Joined ✓",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ─── ROOM INFO BOX (shows when admin has sent room details) ───
          if (roomId.isNotEmpty || roomPassword.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF0D0D0D),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: primaryColor.withValues(alpha: 0.7),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.vpn_key, color: primaryColor, size: 15),
                      const SizedBox(width: 6),
                      const Text(
                        'ROOM DETAILS',
                        style: TextStyle(
                          color: Color(0xFFF47B25),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (roomId.isNotEmpty)
                    _roomInfoRow('Room ID', roomId),
                  if (roomPassword.isNotEmpty)
                    _roomInfoRow('Password', roomPassword),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _roomInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Text('$label: ',
              style: const TextStyle(color: Colors.white54, fontSize: 13)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _info(String title, String value) {
    return Column(
      children: [
        Text(title,
            style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }
}