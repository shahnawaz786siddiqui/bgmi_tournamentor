import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/fcm_service.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _primaryColor = Color(0xFFF47B25);
  static const _darkBg = Color(0xFF0D0D0D);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Notifications & Room Info',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: _primaryColor),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _primaryColor,
          labelColor: _primaryColor,
          unselectedLabelColor: Colors.white38,
          tabs: const [
            Tab(icon: Icon(Icons.vpn_key), text: 'Room ID & Password'),
            Tab(icon: Icon(Icons.campaign), text: 'Broadcast'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _RoomIdTab(),
          _BroadcastTab(),
        ],
      ),
    );
  }
}

// ─── TAB 1: Room ID & Password ────────────────────────────────────────────────

class _RoomIdTab extends StatefulWidget {
  const _RoomIdTab();

  @override
  State<_RoomIdTab> createState() => _RoomIdTabState();
}

class _RoomIdTabState extends State<_RoomIdTab> {
  static const _primaryColor = Color(0xFFF47B25);
  static const _cardBg = Color(0xFF1A1A1A);

  String? _selectedTournamentId;
  String? _selectedTournamentTitle;

  final _roomIdCtrl = TextEditingController();
  final _roomPassCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _roomIdCtrl.dispose();
    _roomPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendRoomInfo() async {
    if (_selectedTournamentId == null) {
      _showSnack('Please select a tournament first', isError: true);
      return;
    }
    if (_roomIdCtrl.text.trim().isEmpty || _roomPassCtrl.text.trim().isEmpty) {
      _showSnack('Room ID and Password cannot be empty', isError: true);
      return;
    }

    setState(() => _sending = true);

    try {
      final firestore = FirebaseFirestore.instance;
      final title = '🎮 Room Info: ${_selectedTournamentTitle ?? 'Tournament'}';
      final message =
          'Room ID: ${_roomIdCtrl.text.trim()}\nPassword: ${_roomPassCtrl.text.trim()}';

      // 1. Store roomId + roomPassword directly on the tournament doc
      await firestore
          .collection('tournaments')
          .doc(_selectedTournamentId)
          .update({
        'roomId': _roomIdCtrl.text.trim(),
        'roomPassword': _roomPassCtrl.text.trim(),
        'roomSentAt': FieldValue.serverTimestamp(),
      });

      // 2. Write a notification doc (in-app notification bell)
      await firestore.collection('notifications').add({
        'title': title,
        'message': message,
        'type': 'room',
        'tournamentId': _selectedTournamentId,
        'tournamentTitle': _selectedTournamentTitle,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. Send real FCM push to all devices (background + killed state)
      if (FcmService.isConfigured) {
        await FcmService.sendToAllUsers(
          title: title,
          body: 'Room ID: ${_roomIdCtrl.text.trim()} | Password: ${_roomPassCtrl.text.trim()}',
          type: 'room',
        );
      }

      _showSnack('✅ Room info sent to all participants!');
      _roomIdCtrl.clear();
      _roomPassCtrl.clear();
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    } finally {
      setState(() => _sending = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: isError ? Colors.redAccent : Colors.green,
      content: Text(msg, style: const TextStyle(color: Colors.white)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _primaryColor.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: _primaryColor, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Room ID & Password will be visible to all players who joined this tournament in their "My Matches" screen.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          _sectionLabel('Select Tournament'),
          const SizedBox(height: 10),

          // Tournament Selector
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('tournaments')
                .orderBy('startTime', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Text('No tournaments found.',
                    style: TextStyle(color: Colors.white54));
              }
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: DropdownButton<String>(
                  isExpanded: true,
                  dropdownColor: const Color(0xFF252525),
                  underline: const SizedBox(),
                  hint: const Text('Select a tournament',
                      style: TextStyle(color: Colors.white38)),
                  value: _selectedTournamentId,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  items: docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final title = data['title'] ?? 'Tournament';
                    return DropdownMenuItem<String>(
                      value: doc.id,
                      child: Text(title,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedTournamentId = value;
                      final doc =
                          docs.firstWhere((d) => d.id == value);
                      final data = doc.data() as Map<String, dynamic>;
                      _selectedTournamentTitle = data['title'] ?? 'Tournament';
                    });
                    // Load existing room info for this tournament
                    _loadExistingRoomInfo(value!);
                  },
                ),
              );
            },
          ),

          // Show current room info if set
          if (_selectedTournamentId != null) ...[
            const SizedBox(height: 14),
            _CurrentRoomInfo(tournamentId: _selectedTournamentId!),
          ],

          const SizedBox(height: 24),
          _sectionLabel('Room ID'),
          const SizedBox(height: 8),
          _buildInputField(
            controller: _roomIdCtrl,
            hint: 'e.g. BGMI123456',
            icon: Icons.tag,
          ),

          const SizedBox(height: 16),
          _sectionLabel('Room Password'),
          const SizedBox(height: 8),
          _buildInputField(
            controller: _roomPassCtrl,
            hint: 'e.g. pass@789',
            icon: Icons.lock_outline,
            obscure: false,
          ),

          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 6,
                shadowColor: _primaryColor.withValues(alpha: 0.4),
              ),
              onPressed: _sending ? null : _sendRoomInfo,
              icon: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.send, size: 20),
              label: Text(
                _sending ? 'Sending...' : 'SEND ROOM INFO TO PARTICIPANTS',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, letterSpacing: 0.8),
              ),
            ),
          ),

          const SizedBox(height: 30),
          _sectionLabel('Recently Sent'),
          const SizedBox(height: 10),
          _RecentRoomNotifications(),
        ],
      ),
    );
  }

  void _loadExistingRoomInfo(String tournamentId) async {
    final doc = await FirebaseFirestore.instance
        .collection('tournaments')
        .doc(tournamentId)
        .get();
    final data = doc.data() ?? {};
    if (mounted) {
      _roomIdCtrl.text = data['roomId']?.toString() ?? '';
      _roomPassCtrl.text = data['roomPassword']?.toString() ?? '';
    }
  }

  Widget _sectionLabel(String text) {
    return Text(text,
        style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5));
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        filled: true,
        fillColor: _cardBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primaryColor, width: 1.5),
        ),
      ),
    );
  }
}

// Shows the currently set Room ID/Pass for selected tournament
class _CurrentRoomInfo extends StatelessWidget {
  final String tournamentId;
  const _CurrentRoomInfo({required this.tournamentId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tournaments')
          .doc(tournamentId)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox();
        final data = snap.data!.data() as Map<String, dynamic>? ?? {};
        final roomId = data['roomId']?.toString() ?? '';
        final roomPass = data['roomPassword']?.toString() ?? '';
        if (roomId.isEmpty && roomPass.isEmpty) return const SizedBox();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Currently Active Room Info',
                  style: TextStyle(
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
              const SizedBox(height: 6),
              Text('Room ID: $roomId',
                  style: const TextStyle(color: Colors.white, fontSize: 13)),
              Text('Password: $roomPass',
                  style: const TextStyle(color: Colors.white, fontSize: 13)),
            ],
          ),
        );
      },
    );
  }
}

// Recent room notifications list
class _RecentRoomNotifications extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('type', isEqualTo: 'room')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Text('No room notifications sent yet.',
              style: TextStyle(color: Colors.white38, fontSize: 13));
        }
        return Column(
          children: docs.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            final title = d['tournamentTitle'] ?? 'Tournament';
            final roomId = d['message']
                    ?.toString()
                    .split('\n')
                    .firstOrNull
                    ?.replaceAll('Room ID: ', '') ??
                '';
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.vpn_key, color: Color(0xFFF47B25), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                        if (roomId.isNotEmpty)
                          Text('Room ID: $roomId',
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ─── TAB 2: Broadcast ─────────────────────────────────────────────────────────

class _BroadcastTab extends StatefulWidget {
  const _BroadcastTab();

  @override
  State<_BroadcastTab> createState() => _BroadcastTabState();
}

class _BroadcastTabState extends State<_BroadcastTab> {
  static const _primaryColor = Color(0xFFF47B25);
  static const _cardBg = Color(0xFF1A1A1A);

  final _titleCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendBroadcast() async {
    if (_titleCtrl.text.trim().isEmpty) {
      _showSnack('Title cannot be empty', isError: true);
      return;
    }
    if (_messageCtrl.text.trim().isEmpty) {
      _showSnack('Message cannot be empty', isError: true);
      return;
    }

    setState(() => _sending = true);

    try {
      final title   = _titleCtrl.text.trim();
      final message = _messageCtrl.text.trim();

      // 1. Write to Firestore (in-app notification bell)
      await FirebaseFirestore.instance.collection('notifications').add({
        'title': title,
        'message': message,
        'type': 'general',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. Send real FCM push to all devices (background + killed state)
      if (FcmService.isConfigured) {
        await FcmService.sendToAllUsers(
          title: title,
          body: message,
          type: 'general',
        );
        _showSnack('✅ Push notification sent to all users!');
      } else {
        _showSnack('✅ In-app notification saved (push key not configured yet)');
      }

      _titleCtrl.clear();
      _messageCtrl.clear();
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    } finally {
      setState(() => _sending = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: isError ? Colors.redAccent : Colors.green,
      content: Text(msg, style: const TextStyle(color: Colors.white)),
    ));
  }

  Future<void> _deleteNotification(String docId) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(docId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.campaign, color: Colors.blueAccent, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'This will send an announcement to ALL users. They will see it in the Notifications section of the app.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),
          _label('Notification Title'),
          const SizedBox(height: 8),
          _buildField(
            controller: _titleCtrl,
            hint: 'e.g. Tournament Update!',
            icon: Icons.title,
            maxLines: 1,
          ),

          const SizedBox(height: 16),
          _label('Message'),
          const SizedBox(height: 8),
          _buildField(
            controller: _messageCtrl,
            hint:
                'Write your announcement here...',
            icon: Icons.message_outlined,
            maxLines: 5,
          ),

          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 6,
              ),
              onPressed: _sending ? null : _sendBroadcast,
              icon: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.campaign, size: 20),
              label: Text(
                _sending ? 'Broadcasting...' : 'BROADCAST TO ALL USERS',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, letterSpacing: 0.8),
              ),
            ),
          ),

          const SizedBox(height: 30),
          _label('Past Broadcasts'),
          const SizedBox(height: 10),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .orderBy('createdAt', descending: true)
                .limit(10)
                .snapshots(),
            builder: (context, snap) {
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Text('No notifications sent yet.',
                    style: TextStyle(color: Colors.white38, fontSize: 13));
              }
              return Column(
                children: docs.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  final title = d['title'] ?? '';
                  final message = d['message'] ?? '';
                  final type = d['type'] ?? 'general';
                  final isRoom = type == 'room';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isRoom
                                ? _primaryColor.withValues(alpha: 0.15)
                                : Colors.blue.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isRoom ? Icons.vpn_key : Icons.campaign,
                            color: isRoom ? _primaryColor : Colors.blueAccent,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(title,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13)),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isRoom
                                          ? _primaryColor.withValues(alpha: 0.2)
                                          : Colors.blue.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      isRoom ? 'ROOM' : 'GENERAL',
                                      style: TextStyle(
                                        color: isRoom
                                            ? _primaryColor
                                            : Colors.blueAccent,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(message,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.white54, fontSize: 12)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.white24, size: 18),
                          onPressed: () => _deleteNotification(doc.id),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(
          color: Colors.white70,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5));

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24),
        prefixIcon: maxLines == 1
            ? Icon(icon, color: Colors.white38, size: 20)
            : Padding(
                padding: const EdgeInsets.only(bottom: 60),
                child: Icon(icon, color: Colors.white38, size: 20),
              ),
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
        ),
      ),
    );
  }
}
