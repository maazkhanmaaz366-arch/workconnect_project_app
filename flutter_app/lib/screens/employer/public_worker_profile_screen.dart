import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../chat/chat_screen.dart';


class PublicWorkerProfileScreen extends StatelessWidget {
  final Map<String, dynamic> worker;
  final num matchPercent;

  const PublicWorkerProfileScreen({super.key, required this.worker, required this.matchPercent});

  Future<void> _handleChatNow(BuildContext context) async {
    final employerId = FirebaseAuth.instance.currentUser?.uid;
    if (employerId == null) return;
    
    final workerId = worker['uid'];
    final workerName = worker['fullName'] ?? 'Worker';
    
    final empDoc = await FirebaseFirestore.instance.collection('users').doc(employerId).get();
    final empName = empDoc.data()?['fullName'] ?? 'Employer';

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
         'lastMessage': 'Chat started',
         'lastTimestamp': FieldValue.serverTimestamp(),
       });
    }
    
    if (context.mounted) {
       Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(chatRoomId: roomId, otherUserName: workerName)));
    }
  }

  @override
  Widget build(BuildContext context) {
    String name = worker['fullName'] ?? 'Unknown Worker';
    double rating = (worker['averageRating'] ?? 0.0).toDouble();
    int reviews = worker['totalReviews'] ?? 0;
    
    List<String> skills = [];
    if (worker['skillsList'] != null) {
      skills = List<String>.from(worker['skillsList']);
    }
    
    bool isVerified = worker['isVerified'] == true;
    String bio = worker['bio'] ?? 'No bio provided.';
    String phone = worker['phoneNumber'] ?? 'No phone provided.';
    String location = worker['city'] ?? worker['location'] ?? 'Unknown location';
    double hourlyRate = (worker['hourlyRate'] ?? 0.0).toDouble();
    
    List<String> portfolioUrls = [];
    if (worker['portfolioUrls'] != null) {
      portfolioUrls = List<String>.from(worker['portfolioUrls']);
    }

    return Scaffold(
      
      appBar: AppBar(
        
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.primary),
        title: Text('Worker Profile', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Profile Section
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.surfaceContainerHighest)),
              ),
              child: Column(
                children: [
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(color: Theme.of(context).colorScheme.surfaceContainerHighest, width: 2)
                          ),
                          child: Icon(Icons.person, size: 80, color: Theme.of(context).colorScheme.primary),
                        ),
                        if (isVerified)
                          Positioned(
                            bottom: -4, right: -4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              child: const Icon(Icons.verified, color: Colors.green, size: 32),
                            ),
                          )
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(name, textAlign: TextAlign.center, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, letterSpacing: -0.5)),
                  const SizedBox(height: 8),
                  Text(isVerified ? 'Certified Professional' : 'Unverified Worker', style: TextStyle(fontSize: 16, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70))),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star, color: Theme.of(context).colorScheme.secondaryContainer, size: 20),
                      const SizedBox(width: 4),
                      Text('$rating • $reviews Reviews', style: TextStyle(fontSize: 14, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70), fontWeight: FontWeight.bold)),
                      const SizedBox(width: 16),
                      Icon(Icons.payments, color: Theme.of(context).colorScheme.secondary, size: 20),
                      const SizedBox(width: 4),
                      Text('₹${hourlyRate.toStringAsFixed(0)}/day', style: TextStyle(fontSize: 14, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70), fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // AI Match Container
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Theme.of(context).colorScheme.secondaryContainer, Theme.of(context).colorScheme.secondary]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.12), blurRadius: 8, offset: Offset(0, 4))]
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: Colors.white, size: 32),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('AI MATCH SCORE', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                              Text('${matchPercent.toStringAsFixed(0)}% Match for your Job', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  Text('Verified Skills', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: skills.map((s) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor, 
                        border: Border.all(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                        borderRadius: BorderRadius.circular(12)
                      ),
                      child: Text(s, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                    )).toList(),
                  ),

                  const SizedBox(height: 32),
                  Text('About Me', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                  const SizedBox(height: 16),
                  Text(bio, style: TextStyle(fontSize: 14, color: (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white), height: 1.5)),
                  
                  if (portfolioUrls.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    Text('Portfolio & Past Work', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: portfolioUrls.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.only(right: 12),
                            width: 120,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(image: NetworkImage(portfolioUrls[index]), fit: BoxFit.cover),
                              boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.12), blurRadius: 4)]
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 32),
                  Text('Certificates', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                  const SizedBox(height: 16),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('certificates').where('userId', isEqualTo: worker['uid']).snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                         return Text("No certificates found.", style: TextStyle(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70)));
                      }
                      return Container(
                        decoration: BoxDecoration(color: Theme.of(context).cardColor, border: Border.all(color: Theme.of(context).colorScheme.surfaceContainerHighest), borderRadius: BorderRadius.circular(16)),
                        child: Column(
                          children: snapshot.data!.docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return ListTile(
                              leading: const Icon(Icons.verified, color: Colors.green),
                              title: Text(data['title'] ?? 'Certificate', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Issued: ${data['issuer'] ?? 'Unknown'}'),
                              trailing: data['fileUrl'] != null 
                                ? Icon(Icons.open_in_new, color: Theme.of(context).colorScheme.primary)
                                : null,
                              onTap: data['fileUrl'] != null ? () {
                                // Normally opens url with url_launcher
                              } : null,
                            );
                          }).toList(),
                        ),
                      );
                    }
                  ),
                  
                  const SizedBox(height: 32),
                  Text('Contact & Location', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.phone, color: Theme.of(context).colorScheme.secondary),
                      const SizedBox(width: 8),
                      Text(phone, style: TextStyle(fontSize: 16, color: (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Theme.of(context).colorScheme.secondary),
                      const SizedBox(width: 8),
                      Text(location, style: TextStyle(fontSize: 16, color: (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white))),
                    ],
                  ),

                  const SizedBox(height: 40),
                  ElevatedButton.icon(
                    onPressed: () => _handleChatNow(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                    ),
                    icon: const Icon(Icons.chat, color: Colors.white),
                    label: const Text('Message Worker', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
