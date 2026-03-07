import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminManageUsersScreen extends StatefulWidget {
  const AdminManageUsersScreen({super.key});

  @override
  State<AdminManageUsersScreen> createState() => _AdminManageUsersScreenState();
}

class _AdminManageUsersScreenState extends State<AdminManageUsersScreen> {
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
        title: const Text(
          'Manage Users',
          style: TextStyle(color: Colors.white, fontSize: 18),
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
                hintText: 'Search by Name',
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
                  .collection('users')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  );
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Error loading users',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                
                // Client-side search filtering
                final filteredDocs = docs.where((doc) {
                  if (_searchQuery.isEmpty) return true;
                  final data = doc.data();
                  final nameVal = (data['name'] ?? '').toString().toLowerCase();
                  return nameVal.contains(_searchQuery);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No users found.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final data = doc.data();
                    
                    final name = data['name'] ?? 'Unnamed Player';
                    final phone = data['phoneNumber'] ?? 'No Phone Provided';
                    final balanceRaw = data['balance'] ?? 0;
                    final balance = (balanceRaw is int)
                        ? balanceRaw.toDouble()
                        : (balanceRaw as num).toDouble();
                        
                    return Card(
                      color: const Color(0xFF1E1E1E),
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: primaryColor.withOpacity(0.2),
                          child: const Icon(Icons.account_circle, color: primaryColor),
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          'Phone: $phone\nID: ${doc.id}\nBalance: ₹${balance.toStringAsFixed(0)}',
                          style: const TextStyle(color: Colors.white54, fontSize: 13),
                        ),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: const Icon(Icons.edit, color: primaryColor),
                          onPressed: () {
                            _showEditBalanceDialog(context, doc.id, balance, phone);
                          },
                        ),
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

  Future<void> _showEditBalanceDialog(
    BuildContext context,
    String userId,
    double currentBalance,
    String phone,
  ) async {
    final balanceController = TextEditingController(text: currentBalance.toStringAsFixed(0));
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Text(
            'Edit Wallet: $phone',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: balanceController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'New Balance',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFF47B25)),
                ),
              ),
              validator: (val) {
                if (val == null || val.isEmpty) return 'Enter a value';
                if (double.tryParse(val) == null) return 'Enter a valid number';
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF47B25)),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                
                final newBalance = double.parse(balanceController.text.trim());
                
                await FirebaseFirestore.instance.collection('users').doc(userId).update({
                  'balance': newBalance,
                  'updatedAt': FieldValue.serverTimestamp(),
                });
                
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Balance updated successfully')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
