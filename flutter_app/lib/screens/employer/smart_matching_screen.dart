import 'dart:convert';
import '../../services/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../chat/chat_screen.dart';
import 'public_worker_profile_screen.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SmartMatchingScreen extends StatefulWidget {
  final String jobId;
  final String jobTitle;
  final String jobDescription;

  const SmartMatchingScreen({super.key, required this.jobId, required this.jobTitle, required this.jobDescription});

  @override
  State<SmartMatchingScreen> createState() => _SmartMatchingScreenState();
}

class _SmartMatchingScreenState extends State<SmartMatchingScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _matchedWorkers = [];

  @override
  void initState() {
    super.initState();
    _fetchAndMatchWorkers();
  }

  Future<void> _fetchAndMatchWorkers() async {
    try {
      final jobDoc = await FirebaseFirestore.instance.collection('jobs').doc(widget.jobId).get();
      final jobData = jobDoc.data() ?? {};
      final jobLat = (jobData['latitude'] ?? 0.0).toDouble();
      final jobLng = (jobData['longitude'] ?? 0.0).toDouble();

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'worker')
          .get();
          
      if (snapshot.docs.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = "No workers found in your area.";
        });
        return;
      }

      List<Map<String, dynamic>> workersData = [];
      List<Map<String, dynamic>> payloadWorkers = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        workersData.add({'uid': doc.id, ...data});
        
        List<String> skills = [];
        if (data['skillsList'] != null) {
          skills = List<String>.from(data['skillsList']);
        }
        
        payloadWorkers.add({
          "uid": doc.id,
          "skillsList": skills,
          "averageRating": (data['averageRating'] ?? 0.0).toDouble(),
          "latitude": (data['latitude'] ?? 0.0).toDouble(),
          "longitude": (data['longitude'] ?? 0.0).toDouble()
        });
      }

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/ai/match'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "job_description": widget.jobDescription, // Dynamic Description
          "job_latitude": jobLat,
          "job_longitude": jobLng,
          "workers": payloadWorkers,
        }),
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        List<dynamic> scores = jsonDecode(response.body);
        
        for (var worker in workersData) {
          var match = scores.firstWhere(
            (s) => s['uid'] == worker['uid'], 
            orElse: () => {'match_score': 0.0, 'distance_km': 0.0}
          );
          worker['match_score'] = match['match_score'];
          worker['distance_km'] = match['distance_km'];
        }
        
        workersData.sort((a, b) {
           num scoreA = a['match_score'] ?? 0.0;
           num scoreB = b['match_score'] ?? 0.0;
           return scoreB.compareTo(scoreA);
        });

        setState(() {
          _matchedWorkers = workersData;
          _isLoading = false;
        });
      } else {
        throw Exception("Server Error: ${response.statusCode}");
      }
    } catch (e, stackTrace) {
      print("CRASH DETAILS: $e");
      print(stackTrace);
      setState(() {
        _isLoading = false;
        _errorMessage = "Failed to load matches. Error: $e";
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Request Failed: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleChatNow(Map<String, dynamic> worker) async {
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
    
    if (mounted) {
       Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(chatRoomId: roomId, otherUserName: workerName)));
    }
  }

  void _handleHireNow(Map<String, dynamic> worker) {
    final workerName = worker['fullName'] ?? 'Worker';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hire Confirmation"),
        content: Text("Are you sure you want to hire $workerName? A notification will be sent immediately."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              
              final employerId = FirebaseAuth.instance.currentUser?.uid;
              if (employerId == null) return;

              // Create hire request
              final requestRef = await FirebaseFirestore.instance.collection('hire_requests').add({
                  'employerId': employerId,
                  'workerId': worker['uid'],
                  'jobId': widget.jobId,
                  'jobTitle': widget.jobTitle,
                  'status': 'pending',
                  'timestamp': FieldValue.serverTimestamp(),
              });

              // Push real notification to worker
              await FirebaseFirestore.instance.collection('notifications').add({
                 'userId': worker['uid'],
                 'type': 'hire_request',
                 'title': 'New Hire Request!',
                 'body': 'An employer wants to hire you for: ${widget.jobTitle}.',
                 'requestId': requestRef.id,
                 'employerId': employerId,
                 'jobId': widget.jobId,
                 'status': 'pending',
                 'timestamp': FieldValue.serverTimestamp(),
              });

              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("$workerName has been sent a hire request!"), backgroundColor: Colors.green),
                );
              }
            }, 
            child: const Text("Send Request")
          ),
        ],
      )
    );
  }

  Widget _buildWorkerCard(Map<String, dynamic> worker) {
    String name = worker['fullName'] ?? 'Unknown Worker';
    String title = "VERIFIED PROFESSIONAL";
    
    num rawScore = worker['match_score'] ?? 0.0;
    String matchPercent = "${rawScore.toStringAsFixed(0)}%";
    num distance = worker['distance_km'] ?? 0.0;
    String distanceStr = "${distance.toStringAsFixed(1)} km away";
    
    double rating = (worker['averageRating'] ?? 0.0).toDouble();
    int reviews = worker['totalReviews'] ?? 0;
    
    List<String> skills = [];
    if (worker['skillsList'] != null) {
      skills = List<String>.from(worker['skillsList']);
    }
    
    return GestureDetector(
      onTap: () {
         Navigator.push(context, MaterialPageRoute(builder: (_) => PublicWorkerProfileScreen(worker: worker, matchPercent: worker['match_score'] ?? 0)));
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.12))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(width: 60, height: 60, color: Colors.grey[300], child: const Icon(Icons.person, color: Colors.grey)),
                      ),
                      Positioned(
                        bottom: -4, right: -4,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: const Icon(Icons.verified, color: Colors.green, size: 16),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF112A46))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: const Color(0xFFF97316), borderRadius: BorderRadius.circular(12)),
                              child: Text('AI Match: $matchPercent', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            )
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Color(0xFFB85C19), size: 14),
                            const SizedBox(width: 4),
                            Flexible(child: Text('$rating • ($reviews reviews)', style: TextStyle(fontSize: 12, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70)), overflow: TextOverflow.ellipsis)),
                            const SizedBox(width: 8),
                            Icon(Icons.location_on, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70), size: 14),
                            Flexible(child: Text(distanceStr, style: TextStyle(fontSize: 12, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70)), overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70))),
                      ],
                    ),
                  )
                ],
              ),
            ),
            
            if (skills.isNotEmpty) Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: skills.map((s) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
                  child: Text(s, style: TextStyle(fontSize: 10, color: (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white))),
                )).toList(),
              ),
            ),
            
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF7F9FA), borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline, color: Color(0xFFB85C19), size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text('"AI verified this worker based on matching specific plumbing criteria required for your task."', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70)))),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _handleChatNow(worker),
                      icon: const Icon(Icons.chat_bubble_outline, size: 16),
                      label: const Text('Chat'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _handleHireNow(worker),
                      child: const Text('Hire Now'),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WorkConnect', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          const Icon(Icons.swap_horiz, color: Color(0xFF112A46)),
          const SizedBox(width: 16),
          CircleAvatar(radius: 14, backgroundColor: Colors.black12, child: Icon(Icons.person, size: 16, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70))),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading 
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    const SpinKitRipple(color: Color(0xFFFE9743), size: 150),
                    const Icon(Icons.smart_toy, size: 60, color: Color(0xFF002045))
                       .animate(onPlay: (controller) => controller.repeat(reverse: true))
                       .scaleXY(end: 1.2, duration: 1000.ms)
                       .then()
                       .shimmer(duration: 1000.ms, color: Colors.orange),
                  ],
                ),
                const SizedBox(height: 32),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    'AI is scanning for the best verified trades...',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF002045)),
                    textAlign: TextAlign.center,
                  ),
                ).animate(onPlay: (controller) => controller.repeat(reverse: true)).fade(duration: 1500.ms),
              ],
            ),
          )
        : _errorMessage != null
          ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
          : ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Smart Matching Results', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF112A46))),
                      const SizedBox(height: 8),
                      Text('Showing ${_matchedWorkers.length} AI-matched candidates for your job.', style: TextStyle(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70), fontSize: 13)),
                      
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.12))),
                        child: Text('Sorted by AI Match Score', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Theme.of(context).colorScheme.primary)),
                      ),

                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: const Color(0xFF112A46), borderRadius: BorderRadius.circular(8)),
                        child: const Row(
                          children: [
                            Icon(Icons.auto_awesome, color: Color(0xFF4ADE80)),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'AI Matching Active\nWe\'ve analyzed skills, location, and previous reviews to find workers that specifically fit your project.',
                                style: TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                if (_matchedWorkers.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: Text("No workers available. Create a worker account to see them here!")),
                  ),

                ..._matchedWorkers.map((w) {
                   int index = _matchedWorkers.indexOf(w);
                   return _buildWorkerCard(w).animate().fadeIn(delay: (index * 200).ms).slideX(begin: 0.1);
                }).toList(),

                const SizedBox(height: 32),
              ],
            ),
    );
  }
}
