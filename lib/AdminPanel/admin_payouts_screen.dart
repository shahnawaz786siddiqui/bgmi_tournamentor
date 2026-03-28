import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminPayoutsScreen extends StatefulWidget {
  const AdminPayoutsScreen({super.key});

  @override
  State<AdminPayoutsScreen> createState() => _AdminPayoutsScreenState();
}

class _AdminPayoutsScreenState extends State<AdminPayoutsScreen> {
  String _filterStatus = 'Pending'; // Pending, Paid, Rejected

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFF47B25);
    const darkBg = Color(0xFF121212);

    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        backgroundColor: darkBg,
        title: const Text(
          'Approve Payouts',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          DropdownButton<String>(
            value: _filterStatus,
            dropdownColor: const Color(0xFF1E1E1E),
            style: const TextStyle(color: Colors.white),
            underline: const SizedBox(),
            items: ['Pending', 'Paid', 'Rejected'].map((status) {
              return DropdownMenuItem(
                value: status,
                child: Text(status),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _filterStatus = val;
                });
              }
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('payouts')
            .where('status', isEqualTo: _filterStatus)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryColor));
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Failed to load payouts.',
                style: TextStyle(color: Colors.white54),
                textAlign: TextAlign.center,
              ),
            );
          }

          // Sort client-side: newest first
          final docs = [...(snapshot.data?.docs ?? [])]
            ..sort((a, b) {
              final aTime = a.data()['requestedAt'];
              final bTime = b.data()['requestedAt'];
              if (aTime == null || bTime == null) return 0;
              return (bTime as Timestamp).compareTo(aTime as Timestamp);
            });

          if (docs.isEmpty) {
            return Center(
              child: Text(
                'No $_filterStatus payouts found.',
                style: const TextStyle(color: Colors.white70),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();

              final amountRaw = data['amount'] ?? 0;
              final amount = (amountRaw is int) ? amountRaw.toDouble() : (amountRaw as num).toDouble();
              final phone = data['phoneNumber'] ?? 'No Phone Provided';
              final userId = data['userId'] ?? 'Unknown User';
              final paymentMethod = data['paymentMethod'] ?? 'UPI / Paytm';
              
              String dateString = 'Unknown Date';
              if (data['requestedAt'] is Timestamp) {
                final dt = (data['requestedAt'] as Timestamp).toDate();
                dateString = '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
              }

              return Card(
                color: const Color(0xFF1E1E1E),
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '₹${amount.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(_filterStatus).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _getStatusColor(_filterStatus)),
                            ),
                            child: Text(
                              _filterStatus,
                              style: TextStyle(
                                color: _getStatusColor(_filterStatus),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                       Text('Method: $paymentMethod', style: const TextStyle(color: Colors.white70)),
                      if (paymentMethod == 'Bank Transfer') ...[
                        Text('Account No: ${data['accountNumber'] ?? 'N/A'}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('IFSC code: ${data['ifscCode'] ?? 'N/A'}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                        if (phone != 'No Phone Provided' && phone.isNotEmpty)
                          Text('Phone: $phone', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      ] else ...[
                        Text('Phone/UPI: $phone', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                      if ((data['userName'] ?? '').toString().isNotEmpty)
                        Text('Player: ${data['userName']}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 8),
                      Text('Requested: $dateString', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      Text('User ID: $userId', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                      
                      if (_filterStatus == 'Pending') ...[
                        const Divider(color: Colors.white24, height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => _updatePayoutStatus(context, doc.id, 'Rejected'),
                              child: const Text('Reject', style: TextStyle(color: Colors.redAccent)),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              onPressed: () => _updatePayoutStatus(context, doc.id, 'Paid'),
                              child: const Text('Mark as Paid'),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Paid':
        return Colors.green;
      case 'Rejected':
        return Colors.redAccent;
      default:
        return Colors.orangeAccent;
    }
  }

  Future<void> _updatePayoutStatus(BuildContext context, String docId, String newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('payouts').doc(docId).update({
        'status': newStatus,
        'processedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payout marked as $newStatus')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update payout status')),
        );
      }
    }
  }
}
