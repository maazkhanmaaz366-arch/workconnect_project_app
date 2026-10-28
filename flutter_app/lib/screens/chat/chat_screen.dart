import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatScreen extends StatefulWidget {
  final String chatRoomId;
  final String otherUserName;
  final String? recipientId;
  final String? jobId;

  const ChatScreen({super.key, required this.chatRoomId, required this.otherUserName, this.recipientId, this.jobId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  String? _currentUserRole;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && mounted) {
        setState(() {
          _currentUserRole = doc.data()?['role'] ?? 'worker';
        });
      }
    }
  }

  void _sendOffer() {
     showDialog(
       context: context,
       builder: (ctx) {
         final rateCtrl = TextEditingController();
         return AlertDialog(
           title: const Text("Send Digital Offer"),
           content: TextField(
             controller: rateCtrl,
             decoration: const InputDecoration(labelText: "Hourly Rate / Total Amount", prefixText: "\$"),
           ),
           actions: [
             TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
             ElevatedButton(
               onPressed: () async {
                 if (rateCtrl.text.trim().isEmpty) return;
                 Navigator.pop(ctx);
                 final user = FirebaseAuth.instance.currentUser;
                 await FirebaseFirestore.instance.collection('chatRooms').doc(widget.chatRoomId).collection('messages').add({
                   'text': 'I have sent you an official offer for \$${rateCtrl.text.trim()}.',
                   'isOffer': true,
                   'offerAmount': rateCtrl.text.trim(),
                   'offerStatus': 'pending',
                   'senderId': user?.uid ?? 'unknown',
                   'timestamp': FieldValue.serverTimestamp(),
                 });
                 Map<String, dynamic> updateData = {
                   'lastMessage': 'Sent a Digital Contract',
                   'lastTimestamp': FieldValue.serverTimestamp(),
                 };
                 if (widget.recipientId != null && user != null) {
                   updateData['participants'] = FieldValue.arrayUnion([user.uid, widget.recipientId!]);
                   updateData['participantNames'] = {
                       user.uid: user.displayName ?? 'User',
                       widget.recipientId!: widget.otherUserName,
                   };
                 }
                 await FirebaseFirestore.instance.collection('chatRooms').doc(widget.chatRoomId).set(updateData, SetOptions(merge: true));
               },
               child: const Text("Send Offer")
             )
           ]
         );
       }
     );
  }

  Future<void> _acceptOffer(String messageDocId, String? amount) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      try {
         await FirebaseFirestore.instance.collection('chatRooms').doc(widget.chatRoomId).collection('messages').doc(messageDocId).update({
            'offerStatus': 'accepted'
         });
         
         await FirebaseFirestore.instance.collection('chatRooms').doc(widget.chatRoomId).collection('messages').add({
            'text': 'Contract Accepted. Escrow authorized for \$${amount ?? "0"}.',
            'senderId': 'system',
            'timestamp': FieldValue.serverTimestamp(),
         });

         await FirebaseFirestore.instance.collection('payments').add({
            'chatRoomId': widget.chatRoomId,
            'workerId': user.uid,
            'amount': double.tryParse(amount ?? '0') ?? 0.0,
            'status': 'held_in_escrow',
            'timestamp': FieldValue.serverTimestamp()
         });

         if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Offer Accepted! Funds secured in Escrow."), backgroundColor: Colors.green));
      } catch(e) {
         if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
  }

  void _markJobComplete() {
     showDialog(
       context: context,
       builder: (ctx) {
         int selectedRating = 5;
         final reviewCtrl = TextEditingController();
         return StatefulBuilder(
           builder: (context, setState) {
             return AlertDialog(
               title: const Text("Rate Worker & Release Funds"),
               content: Column(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   const Text("Select Rating:", style: TextStyle(fontWeight: FontWeight.bold)),
                   const SizedBox(height: 8),
                   Row(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: List.generate(5, (index) {
                       return IconButton(
                         icon: Icon(
                           index < selectedRating ? Icons.star : Icons.star_border,
                           color: Colors.amber,
                           size: 32,
                         ),
                         onPressed: () {
                           setState(() {
                             selectedRating = index + 1;
                           });
                         },
                       );
                     }),
                   ),
                   const SizedBox(height: 16),
                   TextField(controller: reviewCtrl, maxLines: 3, decoration: const InputDecoration(labelText: "Written Review", hintText: "Great job on the pipes...")),
                 ]
               ),
               actions: [
                 TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                 ElevatedButton(
                   onPressed: () async {
                      Navigator.pop(ctx);
                      try {
                        // Release escrow payment (avoid composite index)
                        final paymentQuery = await FirebaseFirestore.instance.collection('payments')
                            .where('chatRoomId', isEqualTo: widget.chatRoomId)
                            .get();
                        
                        for (var doc in paymentQuery.docs) {
                           if (doc.data()['status'] == 'held_in_escrow') {
                              await doc.reference.update({'status': 'released'});
                           }
                        }

                        // Send system message
                        await FirebaseFirestore.instance.collection('chatRooms').doc(widget.chatRoomId).collection('messages').add({
                          'text': 'Job Completed. Escrow funds released to Worker. Rating: $selectedRating Stars.',
                          'senderId': 'system',
                          'timestamp': FieldValue.serverTimestamp(),
                        });
                        
                        if (widget.recipientId != null) {
                          // Update worker profile
                          await FirebaseFirestore.instance.collection('users').doc(widget.recipientId).update({
                             'rating': selectedRating.toString(),
                          });
                        }
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Job Completed! Funds released."), backgroundColor: Colors.green));
                      } catch (e) {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
                      }
                   },
                   child: const Text("Submit & Pay")
                 )
               ]
             );
           }
         );
       }
     );
  }

  void _raiseDispute() {
     showDialog(
       context: context,
       builder: (ctx) {
         final reasonCtrl = TextEditingController();
         return AlertDialog(
           title: const Text("Raise a Dispute"),
           content: TextField(
             controller: reasonCtrl,
             decoration: const InputDecoration(labelText: "Reason for dispute"),
             maxLines: 3,
           ),
           actions: [
             TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
             ElevatedButton(
               style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
               onPressed: () async {
                 if (reasonCtrl.text.trim().isEmpty) return;
                 Navigator.pop(ctx);
                 final user = FirebaseAuth.instance.currentUser;
                 try {
                   final paymentQuery = await FirebaseFirestore.instance.collection('payments')
                       .where('chatRoomId', isEqualTo: widget.chatRoomId)
                       .where('status', isEqualTo: 'held_in_escrow')
                       .get();
                       
                   double amount = 0;
                   String? paymentId;
                   if (paymentQuery.docs.isNotEmpty) {
                       amount = (paymentQuery.docs.first.data()['amount'] ?? 0.0).toDouble();
                       paymentId = paymentQuery.docs.first.id;
                   }

                   String? jobTitle;
                   if (widget.jobId != null) {
                       final jobDoc = await FirebaseFirestore.instance.collection('jobs').doc(widget.jobId).get();
                       if (jobDoc.exists) jobTitle = jobDoc.data()?['title'];
                   }
                   
                   String raisedByName = user?.displayName ?? 'Unknown';
                   if (raisedByName == 'Unknown' && user != null) {
                       final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
                       raisedByName = userDoc.data()?['fullName'] ?? 'Unknown';
                   }

                   await FirebaseFirestore.instance.collection('disputes').add({
                     'chatRoomId': widget.chatRoomId,
                     'jobId': paymentId ?? widget.jobId ?? widget.chatRoomId,
                     'jobTitle': jobTitle ?? 'Chat Dispute',
                     'amount': amount,
                     'raisedByRole': _currentUserRole ?? 'user',
                     'raisedByName': raisedByName,
                     'raisedById': user?.uid,
                     'reason': reasonCtrl.text.trim(),
                     'status': 'open',
                     'timestamp': FieldValue.serverTimestamp(),
                   });
                   if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dispute raised. Admin will review soon.'), backgroundColor: Colors.orange));
                 } catch (e) {
                   if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                 }
               },
               child: const Text("Submit", style: TextStyle(color: Colors.white))
             )
           ]
         );
       }
     );
  }

  void _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;
    
    final user = FirebaseAuth.instance.currentUser;
    final text = _controller.text.trim();
    _controller.clear();

    await FirebaseFirestore.instance.collection('chatRooms').doc(widget.chatRoomId).collection('messages').add({
      'text': text,
      'senderId': user?.uid ?? 'unknown',
      'timestamp': FieldValue.serverTimestamp(),
    });
    
    // Update the last message in the room
    Map<String, dynamic> updateData = {
      'lastMessage': text,
      'lastTimestamp': FieldValue.serverTimestamp(),
    };
    if (widget.recipientId != null && user != null) {
      updateData['participants'] = FieldValue.arrayUnion([user.uid, widget.recipientId!]);
      updateData['participantNames'] = {
          user.uid: user.displayName ?? 'User',
          widget.recipientId!: widget.otherUserName,
      };
    }
    await FirebaseFirestore.instance.collection('chatRooms').doc(widget.chatRoomId).set(updateData, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey[300],
              child: const Icon(Icons.person, color: Colors.grey),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.otherUserName, style: Theme.of(context).textTheme.titleSmall),
                const Text('Online', style: TextStyle(fontSize: 12, color: Colors.green)),
              ],
            )
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
            tooltip: "Raise Dispute",
            onPressed: _raiseDispute,
          ),
          if (_currentUserRole == 'employer')
            TextButton(
              onPressed: _markJobComplete,
              child: const Text("Release Escrow", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chatRooms')
                  .doc(widget.chatRoomId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('Firestore Permission Denied!\nEnsure your Firebase Rules allow read/write access to "chats".', textAlign: TextAlign.center, style: TextStyle(color: Colors.red)),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data = messages[index].data() as Map<String, dynamic>;
                    final docId = messages[index].id;
                    final isMe = data['senderId'] == currentUserId;
                    return _buildBubble(data, docId, isMe: isMe);
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: Theme.of(context).cardColor, boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.12), blurRadius: 4, offset: Offset(0, -2))]),
            child: SafeArea(
              child: Row(
                children: [
                  if (_currentUserRole == 'employer')
                    IconButton(
                      icon: const Icon(Icons.handshake, color: Color(0xFF112A46)),
                      onPressed: _sendOffer,
                      tooltip: "Send Contract",
                    ),
                  const Icon(Icons.attach_file, color: Colors.grey),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: Theme.of(context).scaffoldBackgroundColor,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: const CircleAvatar(
                      backgroundColor: Color(0xFFB85C19),
                      radius: 22,
                      child: Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBubble(Map<String, dynamic> data, String docId, {required bool isMe}) {
    final text = data['text'] ?? '';
    final isSystem = data['senderId'] == 'system';
    final isOffer = data['isOffer'] == true;
    final offerAmount = data['offerAmount'];
    final offerStatus = data['offerStatus'];

    if (isSystem) {
       return Center(
         child: Container(
           margin: const EdgeInsets.symmetric(vertical: 8),
           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
           decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
           child: Row(
             mainAxisSize: MainAxisSize.min,
             children: [
                const Icon(Icons.info_outline, color: Colors.green, size: 16),
                const SizedBox(width: 6),
                Text(text, style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
             ],
           ),
         )
       );
    }

    if (isOffer) {
       return Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            constraints: const BoxConstraints(maxWidth: 280),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFE9743), Color(0xFF944B00)]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.26), blurRadius: 4)]
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.description, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text("DIGITAL CONTRACT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
                Text("Offer Amount: \$${offerAmount ?? '0'}", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text("Status: ${(offerStatus ?? 'pending').toString().toUpperCase()}", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 12),
                if (!isMe && offerStatus == 'pending')
                  ElevatedButton(
                     style: ElevatedButton.styleFrom( foregroundColor: const Color(0xFF944B00)),
                     onPressed: () => _acceptOffer(docId, offerAmount),
                     child: const Text("E-Sign & Accept"),
                  )
              ]
            )
          )
       );
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF112A46) : Theme.of(context).cardColor,
          border: isMe ? null : Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.12)),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
          ),
          boxShadow: [
            if (!isMe) BoxShadow(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.12), blurRadius: 2, offset: Offset(0, 1))
          ]
        ),
        child: Text(text, style: TextStyle(color: isMe ? Colors.white : (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black), fontSize: 15, height: 1.3)),
      ),
    );
  }
}
