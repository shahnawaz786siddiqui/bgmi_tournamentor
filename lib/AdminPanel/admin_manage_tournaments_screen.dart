import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/tournament_service.dart';

class AdminManageTournamentsScreen extends StatelessWidget {
  const AdminManageTournamentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFF47B25);
    const darkBg = Color(0xFF121212);

    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        title: const Text("Manage Tournaments",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E1E1E),
        iconTheme: const IconThemeData(color: primaryColor),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tournaments')
            .orderBy('startTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: primaryColor),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "No Tournaments Found",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final title = data['title'] ?? 'Tournament';
              final entry = _formatCurrency(data['entryFee'], isEntry: true);
              final slots = data['joinedPlayers'] ?? 0;
              final totalSlots = data['totalSlots'] ?? 100;
              final isMega = data['isMega'] ?? false;
              final isFeatured = data['isFeatured'] ?? false;
              
              String flags = "";
              if (isMega) flags += " MEGA";
              if (isFeatured) flags += (flags.isEmpty ? "FEATURED" : " | FEATURED");

              return Card(
                color: const Color(0xFF1E1E1E),
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.white12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Entry: $entry • Slots: $slots/$totalSlots",
                            style: const TextStyle(color: Colors.white70)),
                        if (flags.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(flags, style: const TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
                        ]
                      ],
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => _confirmDelete(context, doc.id, title),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, String tournamentId, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Delete Tournament", style: TextStyle(color: Colors.white)),
        content: Text("Are you sure you want to delete '$title'? This cannot be undone.",
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await TournamentService.instance.deleteTournament(tournamentId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Tournament deleted")),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error deleting tournament: $e")),
                  );
                }
              }
            },
            child: const Text("Delete"),
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
