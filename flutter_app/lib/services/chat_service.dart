import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  FirebaseFirestore? _firestore;

  ChatService() {
    try {
      _firestore = FirebaseFirestore.instance;
    } catch (e) {
      print("CRITICAL: Firestore not initialized.");
      rethrow;
    }
  }

  String getChatRoomId(String user1, String user2) {
    if (user1.compareTo(user2) > 0) {
      return "${user1}_$user2";
    } else {
      return "${user2}_$user1";
    }
  }

  Future<void> sendMessage(String chatRoomId, String senderId, String message) async {
    
    await _firestore
        ?.collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .add({
      'senderId': senderId,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await _firestore?.collection('chatRooms').doc(chatRoomId).set({
      'lastMessage': message,
      'lastTimestamp': FieldValue.serverTimestamp(),
      'participants': FieldValue.arrayUnion([senderId])
    }, SetOptions(merge: true));
  }

  Stream<QuerySnapshot> getMessages(String chatRoomId) {
    return _firestore!
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }
}
