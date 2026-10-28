import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final TextEditingController _disputeReasonController = TextEditingController();

  Future<void> _raiseDispute(BuildContext context, String jobId, double amount) async {
    _disputeReasonController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Raise Dispute'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('If you have an issue with this job or payment, please explain the situation. Our Admin team will review this and resolve the escrow.'),
            const SizedBox(height: 16),
            TextField(
              controller: _disputeReasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for dispute',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              if (_disputeReasonController.text.trim().isEmpty) return;
              try {
                final user = FirebaseAuth.instance.currentUser;
                String raisedByName = user?.displayName ?? 'Unknown';
                if (raisedByName == 'Unknown' && user != null) {
                    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
                    raisedByName = userDoc.data()?['fullName'] ?? 'Unknown';
                }
                
                String? fetchedJobTitle;
                if (jobId != null) {
                    final jobDoc = await FirebaseFirestore.instance.collection('jobs').doc(jobId).get();
                    if (jobDoc.exists) fetchedJobTitle = jobDoc.data()?['title'];
                }

                await FirebaseFirestore.instance.collection('disputes').add({
                  'jobId': jobId,
                  'jobTitle': fetchedJobTitle ?? 'Wallet Dispute',
                  'amount': amount,
                  'reason': _disputeReasonController.text.trim(),
                  'raisedByRole': 'worker',
                  'raisedByName': raisedByName,
                  'raisedById': user?.uid,
                  'status': 'open',
                  'timestamp': FieldValue.serverTimestamp()
                });
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dispute raised. Admin will review soon.'), backgroundColor: Colors.orange));
                }
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Submit Dispute', style: TextStyle(color: Colors.white)),
          )
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text("Please login")));

    return Scaffold(
      
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: const Text('Wallet & Payments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary], begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
        ),
        
        elevation: 10,
        shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.5),
      ),
      body: Column(
        children: [
          // Total Balance Card
          Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
               gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary, const Color(0xFF003B73)]),
               borderRadius: BorderRadius.circular(24),
               boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 8))]
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("TOTAL EARNINGS", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    const SizedBox(height: 8),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('payments').where('workerId', isEqualTo: user.uid).where('status', isEqualTo: 'released').snapshots(),
                      builder: (context, snapshot) {
                         double total = 0.0;
                         if (snapshot.hasData) {
                            for (var doc in snapshot.data!.docs) {
                               total += (doc.data() as Map<String, dynamic>)['amount'] ?? 0.0;
                            }
                         }
                         return Text("PKR $total", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold));
                      }
                    ),
                  ],
                ),
                const Icon(Icons.account_balance_wallet, color: Colors.white54, size: 48)
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Align(alignment: Alignment.centerLeft, child: Text('Transaction History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
          ),
          
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('payments')
                  .where('workerId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                 if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
                 if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                 final docs = snapshot.data!.docs.toList();
                 docs.sort((a, b) {
                    Timestamp? parseTime(dynamic val) {
                      if (val is Timestamp) return val;
                      if (val is String) return Timestamp.fromDate(DateTime.tryParse(val) ?? DateTime.now());
                      return null;
                    }
                    final aTime = parseTime((a.data() as Map<String, dynamic>)['timestamp']);
                    final bTime = parseTime((b.data() as Map<String, dynamic>)['timestamp']);
                    if (aTime == null && bTime == null) return 0;
                    if (aTime == null) return 1;
                    if (bTime == null) return -1;
                    return bTime.compareTo(aTime);
                 });

                 if (docs.isEmpty) return Center(child: Text("No transactions yet.", style: TextStyle(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70))));

                 return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                       final data = docs[index].data() as Map<String, dynamic>;
                       final amount = data['amount'] ?? 0.0;
                       final status = data['status'] ?? 'pending';
                       // status: held_in_escrow, released
                       
                       Color statusColor = Colors.grey;
                       IconData iconData = Icons.schedule;
                       String statusText = 'Pending';

                       if (status == 'held_in_escrow') {
                          statusColor = Colors.orange;
                          iconData = Icons.lock_clock;
                          statusText = 'Held in Escrow';
                       } else if (status == 'released' || status == 'completed') {
                          statusColor = Colors.green;
                          iconData = Icons.check_circle;
                          statusText = 'Paid';
                       }

                       return Card(
                         elevation: 0,
                         margin: const EdgeInsets.only(bottom: 12),
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Theme.of(context).colorScheme.surfaceContainerHighest)),
                         child: ListTile(
                           contentPadding: const EdgeInsets.all(16),
                           leading: CircleAvatar(
                             backgroundColor: statusColor.withOpacity(0.1),
                             child: Icon(iconData, color: statusColor),
                           ),
                           title: Text("PKR $amount", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                           subtitle: Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                           trailing: status == 'held_in_escrow'
                             ? IconButton(
                                 icon: const Icon(Icons.warning_amber_rounded, color: Colors.red),
                                 tooltip: 'Raise Dispute',
                                 onPressed: () => _raiseDispute(context, docs[index].id, amount),
                               )
                             : Text("Contract\nPayment", textAlign: TextAlign.right, style: TextStyle(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70), fontSize: 12)),
                         )
                       );
                    }
                 );
              }
            )
          )
        ],
      )
    );
  }
}
