import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminParticipantsScreen extends StatefulWidget {
  final String tournamentId;
  final String tournamentTitle;

  const AdminParticipantsScreen({
    super.key,
    required this.tournamentId,
    required this.tournamentTitle,
  });

  @override
  State<AdminParticipantsScreen> createState() => _AdminParticipantsScreenState();
}

class _AdminParticipantsScreenState extends State<AdminParticipantsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFF47B25);
    const darkBg = Color(0xFF121212);

    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        backgroundColor: darkBg,
        title: Text(
          'Participants: ${widget.tournamentTitle}',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim().toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search by Player Name',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
              .collection('tournaments')
              .doc(widget.tournamentId)
              .collection('registrations')
            .orderBy('joinedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: primaryColor),
            );
          }

            final docs = snapshot.data?.docs ?? [];

            // Client-side filtering by inGameName
            final filteredDocs = docs.where((doc) {
              if (_searchQuery.isEmpty) return true;
              final data = doc.data();
              final name = (data['inGameName'] ?? '').toString().toLowerCase();
              return name.contains(_searchQuery);
            }).toList();

            if (filteredDocs.isEmpty) {
              return const Center(
                child: Text(
                  'No participants found.',
                  style: TextStyle(color: Colors.white70),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredDocs.length,
              itemBuilder: (context, index) {
                final data = filteredDocs[index].data();
              final inGameName = data['inGameName'] ?? 'Unknown Player';
              final phoneNumber = data['phoneNumber'] ?? 'No Phone';
              
              // Handle Timestamp formatting safely
              String joinedDate = '';
              if (data['joinedAt'] is Timestamp) {
                final dt = (data['joinedAt'] as Timestamp).toDate();
                joinedDate = '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: primaryColor.withOpacity(0.2),
                      child: const Icon(Icons.person, color: primaryColor),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            inGameName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Joined: $joinedDate',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Phone: $phoneNumber',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    ),
        ],
      ),
    );
  }
}
