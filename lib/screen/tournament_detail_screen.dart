import 'package:cloud_firestore/cloud_firestore.dart';
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

  String _formatCurrency(dynamic value, {bool isEntry = false}) {
    if (value == null || value.toString().trim().isEmpty) {
      return isEntry ? 'FREE' : '—';
    }
    final str = value.toString().trim();
    if (str.toUpperCase() == 'FREE') return 'FREE';
    if (str.startsWith('₹')) return str;
    return '₹$str';
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFF47B25);
    const darkBg = Color(0xFF221710);

    if (widget.tournamentId == null) {
      return const Scaffold(
        backgroundColor: darkBg,
        body: Center(
          child: Text('Tournament not found',
              style: TextStyle(color: Colors.white70)),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('tournaments')
          .doc(widget.tournamentId)
          .snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data() ?? {};

        // ── Pull all fields from Firestore ──
        final title      = data['title']    as String? ?? 'Tournament';
        final prize      = _formatCurrency(data['prize']);
        final entryFee   = _formatCurrency(data['entryFee'], isEntry: true);
        final mapName    = data['map']       as String? ?? 'Erangel';
        final version    = data['version']   as String? ?? 'TPP';
        final type       = data['type']      as String? ?? 'Solo';
        final timeLabel  = data['timeLabel'] as String? ?? '';
        final joinedPlayers = data['joinedPlayers'] as int? ?? 0;
        final totalSlots    = data['totalSlots']    as int? ?? 0;
        final bannerUrl  = data['imageUrl']    as String? ?? '';
        final mapImgUrl  = data['mapImageUrl'] as String? ?? '';

        return Scaffold(
          backgroundColor: darkBg,
          body: Stack(
            children: [

              // ═══════════════════════════════ MAIN CONTENT ═══════════════════════════════
              SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ───── HERO BANNER ─────
                    Stack(
                      children: [
                        Container(
                          height: 320,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: bannerUrl.isNotEmpty
                                  ? NetworkImage(bannerUrl) as ImageProvider
                                  : const NetworkImage(
                                      'https://images.unsplash.com/photo-1542751371-adc38448a05e'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),

                        // Gradient overlay
                        Container(
                          height: 320,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.transparent, darkBg.withValues(alpha: 0.9)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),

                        // Title / time overlay
                        Positioned(
                          bottom: 30,
                          left: 20,
                          right: 20,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Chip(
                                backgroundColor: primaryColor,
                                label: Text(
                                  'LIVE REGISTRATION',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                title.toUpperCase(),
                                style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                              if (timeLabel.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  timeLabel,
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Back button
                        Positioned(
                          top: 50,
                          left: 16,
                          child: CircleAvatar(
                            backgroundColor: Colors.black45,
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ───── QUICK STATS ─────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          statCard('Prize Pool', prize,
                              primaryColor.withValues(alpha: 0.15), primaryColor),
                          const SizedBox(width: 10),
                          statCard('Slots', '$joinedPlayers / $totalSlots',
                              Colors.white10, Colors.white),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ───── MATCH INFO CHIPS ─────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _infoBadge(Icons.sports_esports, type),
                          _infoBadge(Icons.map_outlined, mapName),
                          _infoBadge(Icons.videocam_outlined, version),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ───── PRIZE DISTRIBUTION ─────
                    sectionTitle('Prize Distribution'),
                    const SizedBox(height: 10),
                    prizeRow('#1 Winner', prize, highlight: true),

                    const SizedBox(height: 20),

                    // ───── RULES ─────
                    sectionTitle('Tournament Rules'),
                    const SizedBox(height: 10),
                    ruleItem('No emulators allowed. Only mobile devices.'),
                    ruleItem('All players must be Level 30+.'),
                    ruleItem('Hacks or scripts = instant ban.'),
                    ruleItem('Official ESports point system.'),

                    const SizedBox(height: 20),

                    // ───── MAP SECTION ─────
                    sectionTitle('Map Details'),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Stack(
                        children: [
                          Container(
                            height: 150,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              image: DecorationImage(
                                image: mapImgUrl.isNotEmpty
                                    ? NetworkImage(mapImgUrl) as ImageProvider
                                    : const AssetImage('assets/images/map.png'),
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
                            child: Center(
                              child: Text(
                                mapName.toUpperCase(),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 3),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ───── REGISTRATION DETAILS ─────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          sectionTitle('Registration Details'),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _nameController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Enter your In-Game Name',
                              hintStyle: const TextStyle(color: Colors.white54),
                              filled: true,
                              fillColor: Colors.white10,
                              prefixIcon:
                                  const Icon(Icons.person, color: Colors.white54),
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
                              hintText: 'Enter Phone Number (For Payouts)',
                              hintStyle: const TextStyle(color: Colors.white54),
                              filled: true,
                              fillColor: Colors.white10,
                              prefixIcon:
                                  const Icon(Icons.phone, color: Colors.white54),
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

              // ═══════════════════════════════ BOTTOM JOIN BAR ═══════════════════════════════
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: const BoxDecoration(
                    color: darkBg,
                    border: Border(top: BorderSide(color: Colors.white12)),
                  ),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('ENTRY FEE',
                              style: TextStyle(
                                  fontSize: 10, color: Colors.white60)),
                          Text(
                            entryFee,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              // Highlight paid entries in orange, free in white
                              color: entryFee == 'FREE'
                                  ? Colors.white
                                  : primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () async {
                            if (widget.tournamentId == null) return;
                            final inGameName = _nameController.text.trim();
                            final phoneStr = _phoneController.text.trim();

                            if (inGameName.isEmpty || phoneStr.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Please enter both In-Game Name and Phone Number'),
                                ),
                              );
                              return;
                            }
                            if (phoneStr.length < 10) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Please enter a valid Phone Number'),
                                ),
                              );
                              return;
                            }

                            try {
                              await TournamentService.instance.joinTournament(
                                  widget.tournamentId!, inGameName, phoneStr);
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Joined tournament successfully!'),
                                ),
                              );
                              Navigator.pop(context);
                            } on FirebaseException catch (e) {
                              String msg = 'Failed to join tournament';
                              if (e.message == 'ALREADY_JOINED') {
                                msg = 'You have already joined this tournament.';
                              } else if (e.message == 'INSUFFICIENT_FUNDS' ||
                                  e.message?.contains('INSUFFICIENT_FUNDS') ==
                                      true) {
                                msg =
                                    'Not enough balance to join this tournament.';
                              }
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(msg)),
                              );
                            }
                          },
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('JOIN TOURNAMENT',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              SizedBox(width: 6),
                              Icon(Icons.bolt),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ═══════════ REUSABLE WIDGETS ═══════════

  Widget _infoBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFFF47B25), size: 14),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget statCard(String title, String value, Color bgColor, Color textColor) {
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
                style:
                    const TextStyle(fontSize: 10, color: Colors.white60)),
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

  Widget prizeRow(String rank, String prize, {bool highlight = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlight
            ? const Color(0xFFF47B25).withValues(alpha: 0.15)
            : Colors.white10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          const Text('• ',
              style: TextStyle(
                  color: Color(0xFFF47B25), fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(text,
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}