import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'admin_participants_screen.dart';
import '../main.dart';
import '../services/tournament_service.dart';

class AdminTournamentEditorScreen extends StatefulWidget {
  const AdminTournamentEditorScreen({super.key});

  @override
  State<AdminTournamentEditorScreen> createState() =>
      _AdminTournamentEditorScreenState();
}

class _AdminTournamentEditorScreenState
    extends State<AdminTournamentEditorScreen> {
  final _titleController = TextEditingController();
  final _prizeController = TextEditingController();
  final _entryController = TextEditingController();
  final _perKillController = TextEditingController(text: '₹0');
  final _typeController = TextEditingController(text: 'Solo');
  final _mapController = TextEditingController(text: 'Erangel');
  final _versionController = TextEditingController(text: 'TPP');
  final _slotsController = TextEditingController(text: '100');
  final _timeLabelController =
      TextEditingController(text: 'Tonight 8:00 PM IST');

  bool _isMega = false;
  bool _isFeatured = false;
  bool _isUpcoming = true;
  bool _saving = false;

  Future<void> _saveTournament() async {
    if (_titleController.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final slots = int.tryParse(_slotsController.text.trim()) ?? 100;
      await TournamentService.instance.createOrUpdateTournament(
        title: _titleController.text.trim(),
        prize: _prizeController.text.trim(),
        entryFee: _entryController.text.trim(),
        perKill: _perKillController.text.trim(),
        type: _typeController.text.trim(),
        map: _mapController.text.trim(),
        version: _versionController.text.trim(),
        totalSlots: slots,
        timeLabel: _timeLabelController.text.trim(),
        isMega: _isMega,
        isFeatured: _isFeatured,
        isUpcoming: _isUpcoming,
      );
      _titleController.clear();
      _prizeController.clear();
      _entryController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tournament saved')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const darkBg = Color(0xFF121212);
    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        backgroundColor: darkBg,
        title: const Text(
          'Admin - Tournaments',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create / Update Tournament',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'SpaceGrotesk',
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(_titleController, 'Title'),
                  _buildTextField(_prizeController, 'Prize (e.g. ₹10,000)'),
                  _buildTextField(_entryController, 'Entry Fee (e.g. ₹50)'),
                  _buildTextField(_perKillController, 'Per Kill Reward'),
                  _buildTextField(_typeController, 'Type (Solo/Duo/Squad)'),
                  _buildTextField(_mapController, 'Map'),
                  _buildTextField(_versionController, 'Version (TPP/FPP)'),
                  _buildTextField(_slotsController, 'Total Slots',
                      keyboardType: TextInputType.number),
                  _buildTextField(
                      _timeLabelController, 'Time Label (shown to users)'),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    value: _isMega,
                    onChanged: (v) => setState(() => _isMega = v),
                    title: const Text(
                      'Mark as Mega Tournament (hero banner)',
                      style: TextStyle(color: Colors.white),
                    ),
                    activeColor: primaryColor,
                  ),
                  SwitchListTile(
                    value: _isFeatured,
                    onChanged: (v) => setState(() => _isFeatured = v),
                    title: const Text(
                      'Show in Featured Events',
                      style: TextStyle(color: Colors.white),
                    ),
                    activeColor: primaryColor,
                  ),
                  SwitchListTile(
                    value: _isUpcoming,
                    onChanged: (v) => setState(() => _isUpcoming = v),
                    title: const Text(
                      'Show in Upcoming Tournaments',
                      style: TextStyle(color: Colors.white),
                    ),
                    activeColor: primaryColor,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _saving ? null : _saveTournament,
                      child: _saving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Save Tournament',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Existing Tournaments',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'SpaceGrotesk',
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: TournamentService.instance.tournamentsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(color: primaryColor),
                    ),
                  );
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text(
                      'No tournaments yet.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }
                return Column(
                  children: docs.map((doc) {
                    final data = doc.data();
                    final title = data['title'] ?? 'Tournament';
                    final isMega = (data['isMega'] ?? false) as bool;
                    final isFeatured = (data['isFeatured'] ?? false) as bool;
                    final isUpcoming = (data['isUpcoming'] ?? true) as bool;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              FilterChip(
                                label: const Text('Mega'),
                                selected: isMega,
                                onSelected: (v) {
                                  TournamentService.instance
                                      .updateTournamentFlags(
                                    doc.id,
                                    isMega: v,
                                  );
                                },
                              ),
                              FilterChip(
                                label: const Text('Featured'),
                                selected: isFeatured,
                                onSelected: (v) {
                                  TournamentService.instance
                                      .updateTournamentFlags(
                                    doc.id,
                                    isFeatured: v,
                                  );
                                },
                              ),
                              FilterChip(
                                label: const Text('Upcoming'),
                                selected: isUpcoming,
                                onSelected: (v) {
                                  TournamentService.instance
                                      .updateTournamentFlags(
                                    doc.id,
                                    isUpcoming: v,
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AdminParticipantsScreen(
                                        tournamentId: doc.id,
                                        tournamentTitle: title,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.people, color: primaryColor, size: 20),
                                label: const Text(
                                  'View Participants',
                                  style: TextStyle(color: primaryColor),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white24),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: primaryColor),
          ),
        ),
      ),
    );
  }
}

