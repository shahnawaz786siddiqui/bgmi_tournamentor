import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const _primaryColor = Color(0xFFF47B25);
  static const _darkBg = Color(0xFF0D0D0D);

  /// Timestamp of when the user last opened the notifications screen.
  /// Notifications newer than this are considered "unread".
  DateTime _lastReadTime = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _loadAndMarkRead();
  }

  Future<void> _loadAndMarkRead() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt('notifications_last_read') ?? 0;
    setState(() {
      _lastReadTime = DateTime.fromMillisecondsSinceEpoch(ms);
    });
    // Mark all as read by saving current time
    await prefs.setInt(
        'notifications_last_read', DateTime.now().millisecondsSinceEpoch);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Notifications',
          style:
              TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: _primaryColor),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .orderBy('createdAt', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _primaryColor),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.redAccent)),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none,
                      color: Colors.white24, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'No notifications yet',
                    style: TextStyle(color: Colors.white38, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Room info and announcements will appear here.',
                    style: TextStyle(color: Colors.white24, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final d = doc.data() as Map<String, dynamic>;
              final title = d['title']?.toString() ?? '';
              final message = d['message']?.toString() ?? '';
              final type = d['type']?.toString() ?? 'general';
              final isRoom = type == 'room';
              final Timestamp? ts = d['createdAt'] as Timestamp?;
              final createdAt =
                  ts?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
              final isUnread = createdAt.isAfter(_lastReadTime);

              return _NotificationCard(
                title: title,
                message: message,
                isRoom: isRoom,
                createdAt: createdAt,
                isUnread: isUnread,
              );
            },
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final String title;
  final String message;
  final bool isRoom;
  final DateTime createdAt;
  final bool isUnread;

  static const _primaryColor = Color(0xFFF47B25);
  static const _cardBg = Color(0xFF1A1A1A);

  const _NotificationCard({
    required this.title,
    required this.message,
    required this.isRoom,
    required this.createdAt,
    required this.isUnread,
  });

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = isRoom ? _primaryColor : Colors.blueAccent;
    final typeLabel = isRoom ? 'ROOM INFO' : 'ANNOUNCEMENT';
    final icon = isRoom ? Icons.vpn_key : Icons.campaign;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isUnread
            ? _cardBg.withValues(alpha: 1.0)
            : _cardBg.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUnread
              ? accentColor.withValues(alpha: 0.5)
              : Colors.white10,
          width: isUnread ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon bubble
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row + type badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: isUnread
                              ? FontWeight.bold
                              : FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        typeLabel,
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),

                // Message
                Text(
                  message,
                  style: const TextStyle(
                      color: Colors.white60, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 6),

                // Time + unread dot
                Row(
                  children: [
                    if (isUnread) ...[
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: accentColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      _timeAgo(createdAt),
                      style: const TextStyle(
                          color: Colors.white30, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A helper widget that shows an unread notification badge count on a bell icon.
/// Use this wherever you need the bell + badge in a StreamBuilder context.
class NotificationBellButton extends StatelessWidget {
  const NotificationBellButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: _getLastReadMs(),
      builder: (context, snap) {
        final lastReadMs = snap.data ?? 0;
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('notifications')
              .orderBy('createdAt', descending: true)
              .limit(20)
              .snapshots(),
          builder: (context, notifSnap) {
            int unread = 0;
            if (notifSnap.hasData) {
              for (final doc in notifSnap.data!.docs) {
                final d = doc.data() as Map<String, dynamic>;
                final ts = d['createdAt'] as Timestamp?;
                if (ts != null &&
                    ts.millisecondsSinceEpoch > lastReadMs) {
                  unread++;
                }
              }
            }

            return Stack(
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.notifications_active_rounded,
                    color: Color(0xFFF47B25),
                  ),
                ),
                if (unread > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                          minWidth: 16, minHeight: 16),
                      child: Text(
                        unread > 9 ? '9+' : '$unread',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Future<int> _getLastReadMs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('notifications_last_read') ?? 0;
  }
}
