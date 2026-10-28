import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../chat/chat_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  Future<void> _handleAccept(BuildContext context, String notifId, Map<String, dynamic> data) async {
     final type = data['type'];
     
     // Update notification itself
     await FirebaseFirestore.instance.collection('notifications').doc(notifId).update({'status': 'accepted'});

     String workerId = '';
     String employerId = '';
     
     if (type == 'hire_request') {
        final reqId = data['requestId'];
        if (reqId != null) {
           await FirebaseFirestore.instance.collection('hire_requests').doc(reqId).update({'status': 'accepted'});
        }
        workerId = FirebaseAuth.instance.currentUser!.uid;
        employerId = data['employerId'] ?? '';
     } else if (type == 'application') {
        final appId = data['applicationId'];
        if (appId != null) {
           await FirebaseFirestore.instance.collection('applications').doc(appId).update({'status': 'accepted'});
        }
        employerId = FirebaseAuth.instance.currentUser!.uid;
        workerId = data['workerId'] ?? '';
     }
     
     if (workerId.isNotEmpty && employerId.isNotEmpty) {
        // Provision chat room!
        final empDoc = await FirebaseFirestore.instance.collection('users').doc(employerId).get();
        final workerDoc = await FirebaseFirestore.instance.collection('users').doc(workerId).get();
        
        final empName = empDoc.data()?['fullName'] ?? 'Employer';
        final workerName = workerDoc.data()?['fullName'] ?? 'Worker';
        
        final roomId = employerId.compareTo(workerId) > 0 ? '${employerId}_$workerId' : '${workerId}_$employerId';
        final roomRef = FirebaseFirestore.instance.collection('chatRooms').doc(roomId);
        
        final roomSnap = await roomRef.get();
        if (!roomSnap.exists) {
           await roomRef.set({
             'participants': [employerId, workerId],
             'participantNames': {
                workerId: workerName,
                employerId: empName,
             },
             'lastMessage': 'Request Accepted! Chat started.',
             'lastTimestamp': FieldValue.serverTimestamp(),
           });
        }
        
        if (context.mounted) {
           final myId = FirebaseAuth.instance.currentUser!.uid;
           final otherName = myId == employerId ? workerName : empName;
           Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(chatRoomId: roomId, otherUserName: otherName)));
        }
     }
  }

  Future<void> _handleDecline(String notifId, Map<String, dynamic> data) async {
     final type = data['type'];
     await FirebaseFirestore.instance.collection('notifications').doc(notifId).update({'status': 'declined'});
     if (type == 'hire_request') {
        final reqId = data['requestId'];
        if (reqId != null) await FirebaseFirestore.instance.collection('hire_requests').doc(reqId).update({'status': 'declined'});
     } else if (type == 'application') {
        final appId = data['applicationId'];
        if (appId != null) await FirebaseFirestore.instance.collection('applications').doc(appId).update({'status': 'declined'});
     }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser == null) {
      return const Center(child: Text("Please log in to view notifications."));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: currentUser.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs.toList();
        docs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTime = aData['timestamp']?.toString() ?? '';
          final bTime = bData['timestamp']?.toString() ?? '';
          return bTime.compareTo(aTime);
        });

        if (docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_off, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text("You have no notifications.", style: TextStyle(color: Colors.grey, fontSize: 16)),
              ],
            )
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final type = data['type'] ?? 'info';
            final title = data['title'] ?? 'Notification';
            final body = data['body'] ?? '';
            final status = data['status']; 
            
            IconData icon = Icons.notifications;
            Color iconColor = Colors.grey;
            
            if (type == 'hire_request') {
              icon = Icons.handshake;
              iconColor = const Color(0xFFB85C19);
            } else if (type == 'application') {
              icon = Icons.description;
              iconColor = Colors.blue;
            } else if (type == 'hired') {
              icon = Icons.check_circle;
              iconColor = Colors.green;
            } else if (type == 'match') {
              icon = Icons.auto_awesome;
              iconColor = const Color(0xFFB85C19);
            }

            final isPending = status == 'pending';
            final isAccepted = status == 'accepted';
            final isDeclined = status == 'declined';

            Color dotColor = const Color(0xFF112A46);
            if (isAccepted) dotColor = Colors.green;
            if (isDeclined) dotColor = Colors.red;

            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: iconColor.withOpacity(0.1),
                      child: Icon(icon, color: iconColor),
                    ),
                    title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(body),
                    ),
                    trailing: Icon(Icons.circle, size: 12, color: dotColor),
                  ),
                  if (isPending && (type == 'hire_request' || type == 'application'))
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => _handleDecline(docs[index].id, data),
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                            child: const Text('Decline'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () => _handleAccept(context, docs[index].id, data),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            child: const Text('Accept', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  if (isAccepted && (type == 'hire_request' || type == 'application'))
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Text('Accepted', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    ),
                  if (isDeclined && (type == 'hire_request' || type == 'application'))
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Text('Declined', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
