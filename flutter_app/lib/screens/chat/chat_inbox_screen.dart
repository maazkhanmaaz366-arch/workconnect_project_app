import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';


class ChatInboxScreen extends StatefulWidget {
  const ChatInboxScreen({super.key});

  @override
  State<ChatInboxScreen> createState() => _ChatInboxScreenState();
}

class _ChatInboxScreenState extends State<ChatInboxScreen> {
  String _filter = 'All Messages';

  Widget _buildFilterChip(String label) {
    bool isSelected = _filter == label;
    return GestureDetector(
      onTap: () => setState(() => _filter = label),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surfaceContainerHighest),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildChatTile(BuildContext context, {required String roomId, required String name, required String message, required String time, required int unread}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            child: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Theme.of(context).cardColor, width: 2)
              ),
            ),
          )
        ],
      ),
      title: Text(name, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, fontSize: 16)),
      subtitle: Text(message, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: unread > 0 ? (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white) : (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70), fontWeight: unread > 0 ? FontWeight.bold : FontWeight.normal)),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(time, style: TextStyle(fontSize: 12, color: unread > 0 ? Theme.of(context).colorScheme.secondaryContainer : Colors.grey, fontWeight: unread > 0 ? FontWeight.bold : FontWeight.normal)),
          if (unread > 0) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondaryContainer, shape: BoxShape.circle),
              child: Text(unread.toString(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            )
          ]
        ],
      ),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(chatRoomId: roomId, otherUserName: name)));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      
      body: Column(
        children: [
          // Header with AI System Alerts
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search conversations...',
                    prefixIcon: Icon(Icons.search, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70)),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All Messages'),
                      _buildFilterChip('Unread'),
                      _buildFilterChip('Active Jobs'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // AI Alert Glow Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.5), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.2),
                        blurRadius: 10,
                        spreadRadius: 2,
                      )
                    ]
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.secondaryContainer),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("System Alert", style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                            Text("You have a 98% match for a new Downtown job.", style: TextStyle(fontSize: 12, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70))),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, size: 14, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70))
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Dynamic Chat List
          Expanded(
            child: Container(color: Theme.of(context).cardColor,
              child: currentUser == null 
                ? const Center(child: Text("Please log in to view chats."))
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('chatRooms')
                        .where('participants', arrayContains: currentUser.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Error loading chats: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                      }
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data!.docs.toList();
                      docs.sort((a, b) {
                        final aData = a.data() as Map<String, dynamic>;
                        final bData = b.data() as Map<String, dynamic>;
                        final aTime = aData['lastTimestamp']?.toString() ?? '';
                        final bTime = bData['lastTimestamp']?.toString() ?? '';
                        return bTime.compareTo(aTime);
                      });

                      if (docs.isEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey),
                              SizedBox(height: 16),
                              Text("No active conversations.", style: TextStyle(color: Colors.grey, fontSize: 16)),
                            ],
                          )
                        );
                      }

                      return ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          
                          final myId = currentUser.uid;
                          final participantNames = data['participantNames'] as Map<String, dynamic>?;
                          String chatName = 'User';
                          if (participantNames != null) {
                             final otherId = participantNames.keys.firstWhere((id) => id != myId, orElse: () => '');
                             if (otherId.isNotEmpty) {
                                chatName = participantNames[otherId] ?? 'User';
                             }
                          } else {
                             chatName = data['otherUserName'] ?? 'User'; 
                          }

                          final lastMessage = data['lastMessage'] ?? '...';
                          
                          // Convert timestamp to time string
                          String timeStr = 'Recent';
                          if (data['lastTimestamp'] != null) {
                            try {
                              DateTime dt = (data['lastTimestamp'] as Timestamp).toDate();
                              timeStr = "${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
                            } catch (_) {}
                          }

                          return _buildChatTile(
                            context,
                            roomId: doc.id,
                            name: chatName,
                            message: lastMessage,
                            time: timeStr,
                            unread: 0, // In future, fetch unread count from 'messages' collection
                          );
                        },
                      );
                    },
                  ),
            )
          )
        ],
      ),
    );
  }
}
