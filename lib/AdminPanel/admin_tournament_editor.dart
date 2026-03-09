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
  final _bannerImageUrlController = TextEditingController();
  final _mapImageUrlController = TextEditingController();

  bool _isMega = false;
  bool _isFeatured = false;
  bool _isUpcoming = true;
  String _status = 'UPCOMING';
  bool _saving = false;

  // For live preview of newly typed URLs
  String _bannerPreviewUrl = '';
  String _mapPreviewUrl = '';

  @override
  void initState() {
    super.initState();
    _bannerImageUrlController.addListener(() {
      setState(() => _bannerPreviewUrl = _bannerImageUrlController.text.trim());
    });
    _mapImageUrlController.addListener(() {
      setState(() => _mapPreviewUrl = _mapImageUrlController.text.trim());
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _prizeController.dispose();
    _entryController.dispose();
    _perKillController.dispose();
    _typeController.dispose();
    _mapController.dispose();
    _versionController.dispose();
    _slotsController.dispose();
    _timeLabelController.dispose();
    _bannerImageUrlController.dispose();
    _mapImageUrlController.dispose();
    super.dispose();
  }

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
        status: _status,
        imageUrl: _bannerImageUrlController.text.trim(),
        mapImageUrl: _mapImageUrlController.text.trim(),
      );
      _titleController.clear();
      _prizeController.clear();
      _entryController.clear();
      _bannerImageUrlController.clear();
      _mapImageUrlController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tournament saved')),
        );
      }
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

                  // ─────── BANNER IMAGE URL ───────
                  const SizedBox(height: 8),
                  _buildSectionLabel('Tournament Banner Image', Icons.image),
                  _buildTextField(
                    _bannerImageUrlController,
                    'Banner Image URL (used in Mega Banner & Featured Cards)',
                  ),
                  if (_bannerPreviewUrl.isNotEmpty)
                    _buildImagePreview(_bannerPreviewUrl, label: 'Banner Preview'),

                  // ─────── MAP IMAGE URL ───────
                  const SizedBox(height: 8),
                  _buildSectionLabel('Match Map Image', Icons.map),
                  _buildTextField(
                    _mapImageUrlController,
                    'Map Image URL (shown in match cards)',
                  ),
                  if (_mapPreviewUrl.isNotEmpty)
                    _buildImagePreview(_mapPreviewUrl, label: 'Map Preview', height: 100),

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
                  DropdownButtonFormField<String>(
                    value: _status,
                    dropdownColor: const Color(0xFF1E1E1E),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Tournament Status',
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: primaryColor),
                      ),
                    ),
                    items: ['UPCOMING', 'LIVE', 'ONGOING', 'COMPLETED']
                        .map((status) => DropdownMenuItem(
                              value: status,
                              child: Text(status),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _status = val);
                    },
                  ),
                  const SizedBox(height: 16),
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
                    final status = data['status'] ?? 'UPCOMING';
                    final existingBannerUrl = data['imageUrl'] as String? ?? '';
                    final existingMapUrl = data['mapImageUrl'] as String? ?? '';
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

                          // Show current image thumbnails if set
                          if (existingBannerUrl.isNotEmpty || existingMapUrl.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                children: [
                                  if (existingBannerUrl.isNotEmpty) ...[
                                    _miniImageThumb(existingBannerUrl, label: 'Banner'),
                                    const SizedBox(width: 8),
                                  ],
                                  if (existingMapUrl.isNotEmpty)
                                    _miniImageThumb(existingMapUrl, label: 'Map'),
                                ],
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
                            children: [
                              const Text('Status: ', style: TextStyle(color: Colors.white70)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: DropdownButton<String>(
                                  value: ['UPCOMING', 'LIVE', 'ONGOING', 'COMPLETED'].contains(status) ? status : 'UPCOMING',
                                  isExpanded: true,
                                  dropdownColor: const Color(0xFF1E1E1E),
                                  style: const TextStyle(color: Colors.white),
                                  underline: Container(height: 1, color: Colors.white24),
                                  items: ['UPCOMING', 'LIVE', 'ONGOING', 'COMPLETED']
                                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      TournamentService.instance.updateTournamentFlags(
                                        doc.id,
                                        status: val,
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Edit Images button
                              TextButton.icon(
                                onPressed: () => _showEditImagesDialog(
                                  context,
                                  doc.id,
                                  existingBannerUrl,
                                  existingMapUrl,
                                ),
                                icon: const Icon(Icons.image_outlined, color: Colors.blueAccent, size: 20),
                                label: const Text(
                                  'Edit Images',
                                  style: TextStyle(color: Colors.blueAccent),
                                ),
                              ),
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

  // ─────────────────────── HELPERS ───────────────────────

  /// Small label with icon above an image URL section
  Widget _buildSectionLabel(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, color: primaryColor, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  /// Live preview box shown below a URL field
  Widget _buildImagePreview(String url, {required String label, double height = 140}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12, top: 4),
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.black26,
        border: Border.all(color: Colors.white12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Image.network(
            url,
            width: double.infinity,
            height: height,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, color: Colors.white30, size: 32),
                  SizedBox(height: 4),
                  Text('Invalid URL', style: TextStyle(color: Colors.white30, fontSize: 12)),
                ],
              ),
            ),
            loadingBuilder: (_, child, progress) {
              if (progress == null) return child;
              return const Center(child: CircularProgressIndicator(color: primaryColor, strokeWidth: 2));
            },
          ),
          Positioned(
            bottom: 6,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
            ),
          ),
        ],
      ),
    );
  }

  /// Mini thumbnail shown on existing tournament cards
  Widget _miniImageThumb(String url, {required String label}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
        const SizedBox(height: 2),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.network(
            url,
            width: 60,
            height: 40,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 60,
              height: 40,
              color: Colors.white10,
              child: const Icon(Icons.broken_image, color: Colors.white30, size: 16),
            ),
          ),
        ),
      ],
    );
  }

  /// Dialog to edit only the image URLs of an existing tournament
  void _showEditImagesDialog(
    BuildContext context,
    String docId,
    String currentBannerUrl,
    String currentMapUrl,
  ) {
    final bannerCtrl = TextEditingController(text: currentBannerUrl);
    final mapCtrl = TextEditingController(text: currentMapUrl);
    String bannerPreview = currentBannerUrl;
    String mapPreview = currentMapUrl;
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          bannerCtrl.addListener(() => setDialogState(() => bannerPreview = bannerCtrl.text.trim()));
          mapCtrl.addListener(() => setDialogState(() => mapPreview = mapCtrl.text.trim()));

          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Edit Images', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banner image
                  _buildSectionLabel('Tournament Banner Image', Icons.image),
                  _buildDialogTextField(bannerCtrl, 'Banner Image URL'),
                  if (bannerPreview.isNotEmpty)
                    _buildImagePreview(bannerPreview, label: 'Banner Preview'),

                  // Map image
                  _buildSectionLabel('Match Map Image', Icons.map),
                  _buildDialogTextField(mapCtrl, 'Map Image URL'),
                  if (mapPreview.isNotEmpty)
                    _buildImagePreview(mapPreview, label: 'Map Preview', height: 90),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                onPressed: saving
                    ? null
                    : () async {
                        setDialogState(() => saving = true);
                        await TournamentService.instance.updateTournamentFlags(
                          docId,
                          imageUrl: bannerCtrl.text.trim(),
                          mapImageUrl: mapCtrl.text.trim(),
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Images updated')),
                          );
                        }
                      },
                child: saving
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDialogTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
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
