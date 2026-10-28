import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../chat/chat_screen.dart';
import 'public_worker_profile_screen.dart';


class ViewApplicantsScreen extends StatelessWidget {
  final String jobId;
  final String jobTitle;

  const ViewApplicantsScreen({super.key, required this.jobId, required this.jobTitle});

  void _updateApplicationStatus(BuildContext context, String appId, String status) async {
    try {
      await FirebaseFirestore.instance.collection('applications').doc(appId).update({'status': status});
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Application $status!'), backgroundColor: status == 'accepted' ? Colors.green : Colors.orange));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error updating application: $e"), backgroundColor: Colors.red));
    }
  }

  void _startChat(BuildContext context, String workerId, String workerName) async {
    final employerId = FirebaseAuth.instance.currentUser?.uid;
    if (employerId == null) return;
    
    // Generate a unique chat ID
    final chatId = employerId.compareTo(workerId) > 0 ? '${employerId}_$workerId' : '${workerId}_$employerId';
    
    Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(
       chatRoomId: chatId,
       recipientId: workerId,
       otherUserName: workerName,
       jobId: jobId,
    )));
  }

  void _fundEscrowAndHire(BuildContext context, String workerId, String workerName) {
    final TextEditingController amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Fund Escrow for $workerName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the job amount to lock securely in escrow. This ensures the worker they will be paid, but funds are only released when you approve.'),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount (PKR)', prefixIcon: Icon(Icons.attach_money), border: OutlineInputBorder()),
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
            onPressed: () async {
              final double amount = double.tryParse(amountController.text.trim()) ?? 0.0;
              if (amount <= 0) return;
              
              Navigator.pop(dialogContext); // close input dialog
              
              // show processing
              showDialog(context: context, barrierDismissible: false, builder: (_) => AlertDialog(content: Row(children: const [CircularProgressIndicator(), SizedBox(width: 16), Text("Processing escrow...")])));
              
              try {
                final employerId = FirebaseAuth.instance.currentUser?.uid;
                if (employerId == null) throw Exception("Not logged in");

                final userDoc = await FirebaseFirestore.instance.collection('users').doc(employerId).get();
                final balance = (userDoc.data()?['balance'] as num?)?.toDouble() ?? 0.0;

                if (balance < amount) {
                   if (context.mounted) {
                     Navigator.pop(context); // close processing
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insufficient balance. Please Add Funds in Billing & Payments.'), backgroundColor: Colors.red));
                   }
                   return;
                }

                // Deduct balance and create escrow
                await FirebaseFirestore.instance.collection('users').doc(employerId).update({
                  'balance': FieldValue.increment(-amount)
                });

                await FirebaseFirestore.instance.collection('payments').add({
                  'employerId': employerId,
                  'workerId': workerId,
                  'jobId': jobId,
                  'title': jobTitle,
                  'amount': amount,
                  'status': 'held_in_escrow',
                  'type': 'escrow',
                  'timestamp': FieldValue.serverTimestamp()
                });

                // Update application to hired
                await FirebaseFirestore.instance.collection('applications')
                    .where('jobId', isEqualTo: jobId)
                    .where('workerId', isEqualTo: workerId)
                    .get()
                    .then((snap) {
                       for (var doc in snap.docs) {
                          doc.reference.update({'status': 'hired'});
                       }
                    });

                // Send notification to worker
                await FirebaseFirestore.instance.collection('notifications').add({
                   'userId': workerId,
                   'type': 'job_hired',
                   'title': 'You got Hired!',
                   'body': 'An employer hired you and funded escrow for: $jobTitle.',
                   'employerId': employerId,
                   'jobId': jobId,
                   'timestamp': FieldValue.serverTimestamp(),
                });

                if (context.mounted) {
                  Navigator.pop(context); // close processing
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Funds secured in Escrow! Worker is hired.'), backgroundColor: Colors.green));
                }

              } catch (e) {
                 if (context.mounted) {
                   Navigator.pop(context); // close processing
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                 }
              }
            },
            child: const Text('Fund Escrow', style: TextStyle(color: Colors.white))
          )
        ],
      )
    );
  }

  void _releasePayment(BuildContext context, String workerId, String workerName, String appId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Release Payment to $workerName?'),
        content: const Text('Are you sure the job is complete and you want to release the escrowed funds to the worker? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              Navigator.pop(dialogContext); // close prompt
              
              showDialog(context: context, barrierDismissible: false, builder: (_) => AlertDialog(content: Row(children: const [CircularProgressIndicator(), SizedBox(width: 16), Text("Releasing funds...!")])));
              await Future.delayed(const Duration(milliseconds: 300)); // ensure dialog is fully shown before any pop
              
              try {
                final employerId = FirebaseAuth.instance.currentUser?.uid;
                if (employerId == null) throw Exception("Not logged in");

                // Find the escrow payment
                final paymentSnap = await FirebaseFirestore.instance.collection('payments')
                    .where('jobId', isEqualTo: jobId)
                    .get();

                final targetDocs = paymentSnap.docs.where((d) {
                   final data = d.data();
                   return data['workerId'] == workerId && data['status'] == 'held_in_escrow';
                }).toList();

                if (targetDocs.isEmpty) {
                   throw Exception("No escrowed payment found for this job.");
                }

                final paymentDoc = targetDocs.first;
                final amount = (paymentDoc.data()['amount'] as num?)?.toDouble() ?? 0.0;

                // 1. Mark payment as released
                await paymentDoc.reference.update({'status': 'released', 'releasedAt': FieldValue.serverTimestamp()});

                // 2. Add funds to worker's balance
                await FirebaseFirestore.instance.collection('users').doc(workerId).update({
                  'balance': FieldValue.increment(amount)
                });

                // 3. Mark application as completed
                await FirebaseFirestore.instance.collection('applications').doc(appId).update({'status': 'completed'});

                // 4. Mark job as completed
                await FirebaseFirestore.instance.collection('jobs').doc(jobId).update({'status': 'Completed'});

                if (context.mounted) {
                  Navigator.pop(context); // close processing
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment successfully released to worker! Job marked as Completed.'), backgroundColor: Colors.green));
                }

              } catch (e) {
                 if (context.mounted) {
                   Navigator.pop(context); // close processing
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                 }
              }
            },
            child: const Text('Confirm Release', style: TextStyle(color: Colors.white))
          )
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: Text('Applicants: $jobTitle', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary], begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
        ),
        
        elevation: 10,
        shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.5),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('applications').where('jobId', isEqualTo: jobId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Error loading applicants."));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final apps = snapshot.data!.docs;
          if (apps.isEmpty) {
            return Center(child: Text("No applicants yet.", style: TextStyle(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70))));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: apps.length,
            itemBuilder: (context, index) {
               final appData = apps[index].data() as Map<String, dynamic>;
               final workerId = appData['workerId'];

               return FutureBuilder<DocumentSnapshot>(
                 future: FirebaseFirestore.instance.collection('users').doc(workerId).get(),
                 builder: (context, userSnap) {
                    if (!userSnap.hasData || !userSnap.data!.exists) return const SizedBox.shrink();
                    final workerData = userSnap.data!.data() as Map<String, dynamic>;
                    final photoUrl = workerData['photoUrl'];
                    final location = workerData['city'] ?? 'Unknown Location';
                    
                    final name = workerData['fullName'] ?? 'Worker';
                    final trade = workerData['trade'] ?? 'General';
                    final rate = workerData['hourlyRate'] ?? '0';
                    final exp = workerData['experience'] ?? '0';
                    final isVerified = workerData['isVerified'] == true;

                    return GestureDetector(
                      onTap: () {
                         Navigator.push(context, MaterialPageRoute(builder: (_) => PublicWorkerProfileScreen(worker: {'uid': workerId, ...workerData}, matchPercent: 100)));
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                          ],
                          border: Border.all(color: Colors.grey.shade100)
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              height: 6,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [Theme.of(context).colorScheme.secondary, Theme.of(context).colorScheme.primary]),
                                borderRadius: BorderRadius.vertical(top: Radius.circular(16))
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                   Row(
                                     crossAxisAlignment: CrossAxisAlignment.start,
                                     children: [
                                       CircleAvatar(
                                         radius: 30,
                                         
                                         backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                                         child: photoUrl == null ? Icon(Icons.person, color: Theme.of(context).colorScheme.primary, size: 30) : null,
                                       ),
                                       const SizedBox(width: 16),
                                       Expanded(
                                         child: Column(
                                           crossAxisAlignment: CrossAxisAlignment.start,
                                           children: [
                                              Row(
                                                children: [
                                                  Flexible(child: Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).colorScheme.primary), overflow: TextOverflow.ellipsis)),
                                                  if (isVerified) ...[
                                                    const SizedBox(width: 4),
                                                    const Icon(Icons.verified, color: Colors.green, size: 16),
                                                  ]
                                                ]
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(Icons.build, size: 12, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70)),
                                                  const SizedBox(width: 4),
                                                  Flexible(child: Text(trade, style: TextStyle(color: (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white), fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                                                  const SizedBox(width: 8),
                                                  Icon(Icons.location_on, size: 12, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70)),
                                                  const SizedBox(width: 4),
                                                  Flexible(child: Text(location, style: TextStyle(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70), fontSize: 12), overflow: TextOverflow.ellipsis)),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text("$exp Yrs Exp", style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 12, fontWeight: FontWeight.bold)),
                                           ],
                                         )
                                       ),
                                       Column(
                                         crossAxisAlignment: CrossAxisAlignment.end,
                                         children: [
                                            Text("PKR $rate/hr", style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, fontSize: 14)),
                                            const SizedBox(height: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                                              child: const Row(
                                                children: [
                                                  Icon(Icons.star, color: Colors.orange, size: 14),
                                                  SizedBox(width: 4),
                                                  Text("4.9", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange)),
                                                ],
                                              ),
                                            )
                                         ],
                                       )
                                     ],
                                   ),
                                   const SizedBox(height: 16),
                                   Container(
                                     padding: const EdgeInsets.all(12),
                                     decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(8)),
                                     child: Column(
                                       crossAxisAlignment: CrossAxisAlignment.start,
                                       children: [
                                         Row(
                                           children: [
                                             Icon(Icons.format_quote, size: 16, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70)),
                                             SizedBox(width: 8),
                                             Text("Cover Letter", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70))),
                                           ],
                                         ),
                                         const SizedBox(height: 8),
                                         Text(appData['coverLetter'] ?? 'No cover letter provided. Wants to discuss details in chat.', style: TextStyle(color: (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white), fontSize: 13, fontStyle: FontStyle.italic)),
                                       ],
                                     ),
                                   ),
                                   const SizedBox(height: 16),
                                   
                                   if (appData['status'] == 'pending') ...[
                                     Row(
                                       children: [
                                         Expanded(
                                           child: ElevatedButton.icon(
                                             onPressed: () => _updateApplicationStatus(context, apps[index].id, 'accepted'),
                                             style: ElevatedButton.styleFrom(backgroundColor: Colors.green,  padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                             icon: const Icon(Icons.check, size: 18),
                                             label: const Text("Accept")
                                           )
                                         ),
                                         const SizedBox(width: 12),
                                         Expanded(
                                           child: ElevatedButton.icon(
                                             onPressed: () => _updateApplicationStatus(context, apps[index].id, 'declined'),
                                             style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade100, foregroundColor: Colors.red, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0),
                                             icon: const Icon(Icons.close, size: 18),
                                             label: const Text("Decline")
                                           )
                                         )
                                       ],
                                     ),
                                     const SizedBox(height: 16),
                                   ],
                                   if (appData['status'] == 'accepted') ...[
                                      Center(child: Text("Application Accepted", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14))),
                                      const SizedBox(height: 16),
                                   ],
                                   if (appData['status'] == 'declined') ...[
                                      Center(child: Text("Application Declined", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14))),
                                      const SizedBox(height: 16),
                                   ],

                                   if (appData['status'] == 'hired') ...[
                                      Center(child: Text("Worker Hired & Escrow Funded", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14))),
                                      const SizedBox(height: 16),
                                   ],

                                   Row(
                                     children: [
                                       Expanded(
                                         child: Container(
                                           decoration: BoxDecoration(
                                             border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
                                             borderRadius: BorderRadius.circular(12),
                                           ),
                                           child: ElevatedButton.icon(
                                             onPressed: () => _startChat(context, workerId, name),
                                             style: ElevatedButton.styleFrom(
                                               backgroundColor: Colors.transparent,
                                               shadowColor: Colors.transparent,
                                               elevation: 0,
                                               minimumSize: const Size(double.infinity, 50),
                                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                                             ),
                                             icon: Icon(Icons.chat_bubble_outline, color: Theme.of(context).colorScheme.primary, size: 20),
                                             label: Text("Message", style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 16, fontWeight: FontWeight.bold)),
                                           ),
                                         ),
                                       ),
                                       const SizedBox(width: 12),
                                       if (appData['status'] == 'completed')
                                         Expanded(
                                           child: Container(
                                             padding: const EdgeInsets.symmetric(vertical: 14),
                                             decoration: BoxDecoration(
                                               color: Colors.green.withOpacity(0.1),
                                               borderRadius: BorderRadius.circular(12),
                                             ),
                                             child: const Center(
                                                child: Text("Payment Released ✓", style: TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.bold))
                                             ),
                                           ),
                                         )
                                       else if (appData['status'] == 'hired')
                                         Expanded(
                                           child: Container(
                                             decoration: BoxDecoration(
                                               color: Colors.green,
                                               borderRadius: BorderRadius.circular(12),
                                               boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                                             ),
                                             child: ElevatedButton.icon(
                                               onPressed: () => _releasePayment(context, workerId, name, apps[index].id),
                                               style: ElevatedButton.styleFrom(
                                                 backgroundColor: Colors.transparent,
                                                 shadowColor: Colors.transparent,
                                                 minimumSize: const Size(double.infinity, 50),
                                                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                                               ),
                                               icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                                               label: const Text("Release Payment", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                             ),
                                           ),
                                         )
                                       else
                                         Expanded(
                                           child: Container(
                                             decoration: BoxDecoration(
                                               gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary, Color(0xFF003B73)]),
                                               borderRadius: BorderRadius.circular(12),
                                               boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                                             ),
                                             child: ElevatedButton.icon(
                                               onPressed: () => _fundEscrowAndHire(context, workerId, name),
                                               style: ElevatedButton.styleFrom(
                                                 backgroundColor: Colors.transparent,
                                                 shadowColor: Colors.transparent,
                                                 minimumSize: const Size(double.infinity, 50),
                                                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                                               ),
                                               icon: const Icon(Icons.lock_outline, color: Colors.white, size: 20),
                                               label: const Text("Fund Escrow", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                             ),
                                           ),
                                         )
                                     ]
                                   )
                                ],
                              )
                            )
                          ],
                        ),
                      ),
                    ).animate().fadeIn(duration: 400.ms, delay: (index * 100).ms).slideY(begin: 0.1, duration: 400.ms, curve: Curves.easeOutQuad);
                 }
               );
            }
          );
        }
      )
    );
  }
}
