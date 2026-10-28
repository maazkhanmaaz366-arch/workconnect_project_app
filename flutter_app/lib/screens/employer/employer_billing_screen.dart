import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';

class EmployerBillingScreen extends StatefulWidget {
  const EmployerBillingScreen({super.key});

  @override
  State<EmployerBillingScreen> createState() => _EmployerBillingScreenState();
}

class _EmployerBillingScreenState extends State<EmployerBillingScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();

  void _showAddFundsDialog(BuildContext context) {
    _amountController.clear();
    _cardNumberController.clear();
    _expiryController.clear();
    _cvvController.clear();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.credit_card, color: Colors.blueAccent),
              SizedBox(width: 10),
              Text('Add Funds to Balance'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Enter amount and simulated card details to fund your account.', style: TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 16),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount (PKR)',
                    prefixIcon: Icon(Icons.attach_money),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _cardNumberController,
                  keyboardType: TextInputType.number,
                  maxLength: 16,
                  decoration: const InputDecoration(
                    labelText: 'Card Number',
                    prefixIcon: Icon(Icons.payment),
                    border: OutlineInputBorder(),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _expiryController,
                        keyboardType: TextInputType.number,
                        maxLength: 5,
                        decoration: const InputDecoration(
                          labelText: 'MM/YY',
                          border: OutlineInputBorder(),
                          counterText: '',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _cvvController,
                        keyboardType: TextInputType.number,
                        maxLength: 3,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'CVV',
                          border: OutlineInputBorder(),
                          counterText: '',
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => _processMockPayment(context),
              child: const Text('Pay Now', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _processMockPayment(BuildContext dialogContext) async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) return;

    final double amount = double.tryParse(amountText) ?? 0.0;
    if (amount <= 0) return;

    // Show processing dialog
    Navigator.pop(dialogContext); // Close the input dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("Processing Payment securely..."),
          ],
        ),
      ),
    );

    // Simulate network delay for realistic UX
    await Future.delayed(const Duration(seconds: 2));

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Increment balance in Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'balance': FieldValue.increment(amount),
        }, SetOptions(merge: true));

        // Create a transaction record for 'deposit'
        await FirebaseFirestore.instance.collection('payments').add({
          'employerId': user.uid,
          'type': 'deposit',
          'amount': amount,
          'status': 'completed',
          'timestamp': FieldValue.serverTimestamp(),
          'title': 'Deposit to Wallet'
        });
      }

      if (mounted) {
        Navigator.pop(context); // Close processing dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Funds added successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Payment Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _releaseEscrow(String paymentId, double amount) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Release Escrow?"),
        content: Text("Are you sure you want to release PKR $amount to the worker? This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FirebaseFirestore.instance.collection('payments').doc(paymentId).update({
                  'status': 'released'
                });
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Payment Released successfully!")));
              } catch (e) {
                 if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
              }
            }, 
            child: const Text("Release", style: TextStyle(color: Colors.white))
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
        title: const Text('Billing & Payments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
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
          // Balance Card
          Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
               gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary, const Color(0xFF003B73)]),
               borderRadius: BorderRadius.circular(24),
               boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 8))]
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("AVAILABLE BALANCE", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                        const SizedBox(height: 8),
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
                          builder: (context, snapshot) {
                             double bal = 0.0;
                             if (snapshot.hasData && snapshot.data!.exists) {
                                bal = (snapshot.data!.data() as Map<String, dynamic>)['balance']?.toDouble() ?? 0.0;
                             }
                             return Text("PKR $bal", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold));
                          }
                        ),
                      ],
                    ),
                    const Icon(Icons.account_balance_wallet, color: Colors.white54, size: 48)
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddFundsDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text("Add Funds", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                )
              ],
            ),
          ).animate().slideY(begin: 0.2).fadeIn(),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Align(alignment: Alignment.centerLeft, child: Text('Transaction History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
          ),
          
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('payments')
                  .where('employerId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                 if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
                 if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                 final docs = snapshot.data!.docs.toList();
                 docs.sort((a, b) {
                    Timestamp? parseTime(dynamic val) {
                      if (val is Timestamp) return val;
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
                       final type = data['type'] ?? 'escrow';
                       final title = data['title'] ?? (type == 'deposit' ? 'Deposit' : 'Job Escrow');
                       
                       Color statusColor = Colors.grey;
                       IconData iconData = Icons.receipt;
                       String statusText = status.toUpperCase();

                       if (status == 'held_in_escrow') {
                          statusColor = Colors.orange;
                          iconData = Icons.lock_clock;
                          statusText = 'HELD IN ESCROW';
                       } else if (status == 'released' || status == 'completed') {
                          statusColor = Colors.green;
                          iconData = Icons.check_circle;
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
                           title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                           subtitle: Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                           trailing: Column(
                             mainAxisAlignment: MainAxisAlignment.center,
                             crossAxisAlignment: CrossAxisAlignment.end,
                             children: [
                               Text("PKR $amount", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                               if (status == 'held_in_escrow') 
                                 InkWell(
                                   onTap: () => _releaseEscrow(docs[index].id, amount),
                                   child: const Text("Release Funds", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12, decoration: TextDecoration.underline))
                                 )
                             ],
                           )
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
