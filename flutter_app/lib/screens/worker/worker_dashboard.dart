import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../auth/splash_screen.dart';
import '../chat/chat_inbox_screen.dart';
import '../profile/worker_profile_screen.dart';
import '../employer/employer_dashboard.dart';
import 'browse_jobs_screen.dart';
import 'wallet_screen.dart';
import '../settings_screen.dart';
import '../help_support_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_animate/flutter_animate.dart';

// Color Palette based on Tailwind Design
const Color kErrorContainer = Color(0xFFFFDAD6);

class WorkerDashboard extends StatefulWidget {
  const WorkerDashboard({super.key});

  @override
  State<WorkerDashboard> createState() => _WorkerDashboardState();
}

class _WorkerDashboardState extends State<WorkerDashboard> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isClockingIn = false;

  Future<void> _handleClockIn() async {
    setState(() => _isClockingIn = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Location services are disabled.');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw Exception('Location permissions are denied');
      }
      if (permission == LocationPermission.deniedForever) throw Exception('Location permissions are permanently denied.');

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      
      // Simulating a job site location check
      double distanceInMeters = Geolocator.distanceBetween(position.latitude, position.longitude, position.latitude, position.longitude);

      if (distanceInMeters <= 100) {
        await FirebaseFirestore.instance.collection('time_logs').add({
           'workerId': FirebaseAuth.instance.currentUser?.uid,
           'action': 'Clock In',
           'lat': position.latitude,
           'lng': position.longitude,
           'timestamp': FieldValue.serverTimestamp(),
        });
        await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).update({
           'isClockedIn': true,
           'lastLat': position.latitude,
           'lastLng': position.longitude,
           'lastClockIn': FieldValue.serverTimestamp()
        });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Clocked in successfully! You are on-site.'), backgroundColor: Colors.green));
      } else {
        throw Exception('You are off-site. Must be within 100m.');
      }
    } catch (e) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
       if (mounted) setState(() => _isClockingIn = false);
    }
  }

  Future<void> _switchMode() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({'role': 'employer'});
        if (mounted) {
           Provider.of<AuthProvider>(context, listen: false).setRole('employer');
           Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const SplashScreen()), (route) => false);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to switch mode: $e"), backgroundColor: Colors.red));
        }
      }
    }
  }

  void _manageCertificates() {
    showDialog(
      context: context,
      builder: (ctx) {
        final nameCtrl = TextEditingController();
        return AlertDialog(
          title: const Text("Add Certificate"),
          content: TextField(
             controller: nameCtrl,
             decoration: const InputDecoration(labelText: "Certificate Name (e.g., OSHA 30)"),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                try {
                  await FirebaseFirestore.instance.collection('certificates').add({
                    'userId': FirebaseAuth.instance.currentUser?.uid,
                    'certificateName': nameCtrl.text.trim(),
                    'status': 'Active',
                    'timestamp': FieldValue.serverTimestamp(),
                  });
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Certificate Added!"), backgroundColor: Colors.green));
                } catch(e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
                }
              },
              child: const Text("Add"),
            )
          ],
        );
      }
    );
  }

  Widget _buildDrawer() {
    final user = FirebaseAuth.instance.currentUser;
    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
            builder: (context, snapshot) {
               String profilePic = '';
               String name = 'Worker';
               if (snapshot.hasData && snapshot.data!.exists) {
                 final data = snapshot.data!.data() as Map<String, dynamic>?;
                 name = data?['fullName'] ?? 'Worker';
                 profilePic = data?['profilePicture'] ?? '';
               }
               return DrawerHeader(
                 decoration: BoxDecoration(color: Theme.of(context).cardColor),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     CircleAvatar(
                       radius: 30,
                       backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                       backgroundImage: profilePic.isNotEmpty ? NetworkImage(profilePic) : null,
                       child: profilePic.isEmpty ? Icon(Icons.person, size: 30, color: Theme.of(context).colorScheme.onPrimaryContainer) : null,
                     ),
                     const SizedBox(height: 12),
                     Text(name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.titleLarge?.color)),
                     const SizedBox(height: 4),
                     Container(
                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                       decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondaryContainer, borderRadius: BorderRadius.circular(12)),
                       child: const Text("Worker Mode", style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                     )
                   ],
                 ),
               );
            }
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Theme.of(context).colorScheme.surfaceContainerHighest)),
              tileColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              leading: Icon(Icons.swap_horiz, color: Theme.of(context).colorScheme.primary),
              title: Text("Switch to Employer Mode", style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
              onTap: _switchMode,
            ),
          ),
          ListTile(
            leading: Icon(Icons.account_balance_wallet, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70)), 
            title: const Text("Wallet & Payments"), 
            onTap: () {
               Navigator.pop(context); // Close drawer
               Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()));
            }
          ),
          ListTile(leading: Icon(Icons.verified, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70)), title: Text("Certificates"), onTap: _manageCertificates),
          ListTile(leading: Icon(Icons.settings, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70)), title: Text("Settings"), onTap: () {
             Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
          }),
          ListTile(leading: Icon(Icons.help, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70)), title: Text("Help & Support"), onTap: () {
             Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportScreen()));
          }),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Logout", style: TextStyle(color: Colors.red)),
            onTap: () async {
               await Provider.of<AuthProvider>(context, listen: false).logout();
               if (context.mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const SplashScreen()), (route) => false);
            },
          )
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return RefreshIndicator(
      onRefresh: () async { setState(() {}); },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          // Welcome Section
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.orange, size: 16),
              SizedBox(width: 4),
              Text("AI SKILL MATCH", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.secondary, letterSpacing: 1.2)),
            ],
          ),
          const SizedBox(height: 8),
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).snapshots(),
            builder: (context, snapshot) {
              String name = 'Worker';
              bool isAvailable = true;
              if (snapshot.hasData && snapshot.data!.exists) {
                 final data = snapshot.data!.data() as Map<String, dynamic>?;
                 name = data?['fullName']?.split(' ')[0] ?? 'Worker';
                 isAvailable = data?['isAvailable'] ?? true;
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text("Good morning, $name.", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary), overflow: TextOverflow.ellipsis)),
                  Column(
                    children: [
                      Switch(
                        value: isAvailable, 
                        onChanged: (val) {
                          FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).update({'isAvailable': val});
                        },
                        activeColor: Colors.green,
                      ),
                      Text(isAvailable ? "Available" : "Offline", style: TextStyle(fontSize: 10, color: isAvailable ? Colors.green : Colors.grey, fontWeight: FontWeight.bold))
                    ],
                  )
                ]
              ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2);
            }
          ),
          const SizedBox(height: 16),
          
          // Geo-Fenced Clock In Button
          ElevatedButton.icon(
             onPressed: _isClockingIn ? null : _handleClockIn,
             style: ElevatedButton.styleFrom(
               padding: const EdgeInsets.symmetric(vertical: 16),
               backgroundColor: const Color(0xFF10B981), // Green color for Clock In
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
             ),
              icon: _isClockingIn ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.location_on, color: Colors.white),
             label: Text(_isClockingIn ? "Verifying Location..." : "Clock In (Geo-fenced)", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),
          const SizedBox(height: 24),

          // Wallet Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
               gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary, const Color(0xFF003B73)]),
               borderRadius: BorderRadius.circular(24),
               boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 8))]
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("EARNINGS THIS WEEK", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70, letterSpacing: 1.2)),
                    Icon(Icons.account_balance_wallet, color: Colors.white70),
                  ],
                ),
                const SizedBox(height: 16),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('payments').where('workerId', isEqualTo: FirebaseAuth.instance.currentUser?.uid).snapshots(),
                  builder: (context, snapshot) {
                     double total = 0.0;
                     if (snapshot.hasData) {
                        for (var doc in snapshot.data!.docs) {
                           final data = doc.data() as Map<String, dynamic>;
                           total += (data['amount'] ?? 0.0).toDouble();
                        }
                     }
                     return Text("PKR ${total.toStringAsFixed(0)}", style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white));
                  }
                ),
                const SizedBox(height: 12),
                const Row(
                  children: [
                    Icon(Icons.trending_up, color: Colors.greenAccent, size: 16),
                    SizedBox(width: 4),
                    Text("+12% from last week", style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(delay: 300.ms).scaleXY(begin: 0.9),
          const SizedBox(height: 16),
          // Find Jobs Quick Action
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, padding: EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            onPressed: () => setState(() => _currentIndex = 1), // Navigate to Browse Jobs tab
            child: const Text("Find New Jobs", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
          const SizedBox(height: 24),

          // Compliance Status
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Theme.of(context).cardColor, border: Border.all(color: Theme.of(context).colorScheme.surfaceContainerHighest), borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.verified, color: Colors.green)),
                    const SizedBox(width: 12),
                    Text("Compliance Status", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                  ],
                ),
                const SizedBox(height: 16),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('certificates').where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid).snapshots(),
                  builder: (context, snapshot) {
                     if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Text("No certificates found.", style: TextStyle(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70)));
                     }
                     return Column(
                       children: snapshot.data!.docs.map((doc) {
                         final data = doc.data() as Map<String, dynamic>;
                         return Padding(
                           padding: const EdgeInsets.only(bottom: 12.0),
                           child: Row(
                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
                             children: [
                               Text(data['certificateName'] ?? 'Certificate', style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color)),
                               Container(
                                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                 decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                                 child: const Text("Active", style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
                               )
                             ],
                           ),
                         );
                       }).toList(),
                     );
                  }
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton.icon(
                    onPressed: _manageCertificates, 
                    icon: const Icon(Icons.add), 
                    label: const Text("Manage Certificates"),
                  ),
                )
              ],
            ),
          ).animate().fadeIn(delay: 500.ms),
          const SizedBox(height: 24),

          // Jobs Near You
          Text("Jobs Near You", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('jobs').orderBy('timestamp', descending: true).snapshots(),
            builder: (context, snapshot) {
               if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
               if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
               
               // Filter out drafts locally to avoid needing compound indexes initially
               final docs = snapshot.data!.docs.where((d) => (d.data() as Map<String,dynamic>)['status'] != 'Draft').toList();
               
               if (docs.isEmpty) return const Center(child: Text("No jobs available right now."));

               return ListView.builder(
                 shrinkWrap: true,
                 physics: const NeverScrollableScrollPhysics(),
                 itemCount: docs.length,
                 itemBuilder: (context, index) {
                    final jobDoc = docs[index];
                    final data = jobDoc.data() as Map<String, dynamic>;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(color: Theme.of(context).cardColor, border: Border.all(color: Theme.of(context).colorScheme.surfaceContainerHighest), borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(height: 4, decoration: BoxDecoration(gradient: LinearGradient(colors: [Theme.of(context).colorScheme.secondaryContainer, Theme.of(context).colorScheme.primary]), borderRadius: BorderRadius.vertical(top: Radius.circular(16)))),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text((data['category'] ?? 'GENERAL').toString().toUpperCase() + ' • URGENT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70), letterSpacing: 1.2), overflow: TextOverflow.ellipsis),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                                      child: Row(
                                        children: const [
                                          Icon(Icons.verified, color: Colors.green, size: 14),
                                          SizedBox(width: 4),
                                          Text("Verified", style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold))
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(data['title'] ?? 'Job Title', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                                const SizedBox(height: 4),
                                FutureBuilder<DocumentSnapshot>(
                                  future: FirebaseFirestore.instance.collection('users').doc(data['employerId']).get(),
                                  builder: (context, empSnap) {
                                     String companyName = "Unknown Employer";
                                     String location = "Unknown Location";
                                     if (empSnap.hasData && empSnap.data!.exists) {
                                        final empData = empSnap.data!.data() as Map<String, dynamic>;
                                        companyName = empData['companyName'] ?? empData['fullName'] ?? "Employer";
                                        location = data['location'] ?? empData['city'] ?? "Location set";
                                     }
                                     return Row(
                                       children: [
                                          Icon(Icons.business, size: 14, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70)),
                                          const SizedBox(width: 4),
                                          Text(companyName, style: TextStyle(fontSize: 12, color: (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white), fontWeight: FontWeight.bold)),
                                          const SizedBox(width: 12),
                                          Icon(Icons.location_on, size: 14, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70)),
                                          const SizedBox(width: 4),
                                          Text(location, style: TextStyle(fontSize: 12, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70))),
                                       ],
                                     );
                                  }
                                ),
                                const SizedBox(height: 8),
                                Text(data['description'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70))),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text("Rate", style: TextStyle(fontSize: 12, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70))),
                                      Text("PKR ${data['budget']}", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                                    ]),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.secondary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                      onPressed: () async {
                                         try {
                                           final appRef = await FirebaseFirestore.instance.collection('applications').add({
                                              'jobId': jobDoc.id,
                                              'jobTitle': data['title'],
                                              'workerId': FirebaseAuth.instance.currentUser?.uid,
                                              'status': 'pending',
                                              'timestamp': FieldValue.serverTimestamp(),
                                           });
                                           final employerId = data['employerId'];
                                           if (employerId != null) {
                                               await FirebaseFirestore.instance.collection('notifications').add({
                                                  'userId': employerId,
                                                  'type': 'application',
                                                  'title': 'New Application Received',
                                                  'body': 'A worker has applied for: ${data['title']}',
                                                  'applicationId': appRef.id,
                                                  'workerId': FirebaseAuth.instance.currentUser?.uid,
                                                  'jobId': jobDoc.id,
                                                  'status': 'pending',
                                                  'timestamp': FieldValue.serverTimestamp(),
                                               });
                                           }
                                           if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Applied successfully!'), backgroundColor: Colors.green));
                                         } catch (e) {
                                           if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
                                         }
                                      },
                                      child: const Text("Apply Now", style: TextStyle(color: Colors.white)),
                                    )
                                  ],
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    ).animate().fadeIn(delay: 600.ms + (index * 100).ms).slideX(begin: 0.1);
                 }
               );
            }
          ),
          
          // Recent Activity
          const SizedBox(height: 16),
          Text("Recent History", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('applications').where('workerId', isEqualTo: FirebaseAuth.instance.currentUser?.uid).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Text("Error: ${snapshot.error}");
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                 return Padding(padding: EdgeInsets.all(16), child: Text("No recent activity.", style: TextStyle(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70))));
              }
              
              final sortedDocs = snapshot.data!.docs.toList();
              sortedDocs.sort((a, b) {
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
              final displayDocs = sortedDocs.take(5).toList();

              return Column(
                children: displayDocs.map((doc) {
                   final data = doc.data() as Map<String, dynamic>;
                   final status = data['status'] ?? 'pending';
                   IconData icon = Icons.pending_actions;
                   Color color = Theme.of(context).colorScheme.secondaryContainer;
                   if (status == 'accepted') { icon = Icons.check_circle; color = Colors.green; }
                   if (status == 'declined') { icon = Icons.cancel; color = Colors.red; }
                   
                   return Container(
                     margin: const EdgeInsets.only(bottom: 8),
                     padding: const EdgeInsets.all(16),
                     decoration: BoxDecoration(color: Theme.of(context).cardColor, border: Border.all(color: Theme.of(context).colorScheme.surfaceContainerHighest), borderRadius: BorderRadius.circular(12)),
                     child: Row(
                       children: [
                         Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color)),
                         const SizedBox(width: 16),
                         Expanded(
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               Text(data['jobTitle'] ?? 'Job Application', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                               Text("Status: ${status.toString().toUpperCase()}", style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
                             ],
                           ),
                         )
                       ],
                     ),
                   );
                }).toList(),
              );
            }
          ),
        ],
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomeTab(),
      const BrowseJobsScreen(),
      const ChatInboxScreen(),
      const WorkerProfileScreen(),
    ];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu, color: Theme.of(context).iconTheme.color),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Row(
          children: [
            Image.asset('assets/logo.png', width: 28, height: 28),
            const SizedBox(width: 8),
            Text('WorkConnect', style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications, color: Theme.of(context).iconTheme.color),
            onPressed: () {
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You have 0 new notifications.')));
            }, // Handled by backend/push in real app
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Theme.of(context).colorScheme.surfaceContainerHighest)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Theme.of(context).cardColor,
          items: [
            BottomNavigationBarItem(
              icon: Container(
                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                 decoration: BoxDecoration(color: _currentIndex == 0 ? Theme.of(context).colorScheme.secondaryContainer : Colors.transparent, borderRadius: BorderRadius.circular(20)),
                 child: Icon(Icons.home, color: _currentIndex == 0 ? Colors.white : (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70)),
              ), 
              label: 'Home'
            ),
            BottomNavigationBarItem(
              icon: Container(
                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                 decoration: BoxDecoration(color: _currentIndex == 1 ? Theme.of(context).colorScheme.secondaryContainer : Colors.transparent, borderRadius: BorderRadius.circular(20)),
                 child: Icon(Icons.work, color: _currentIndex == 1 ? Colors.white : (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70)),
              ), 
              label: 'Jobs'
            ),
            BottomNavigationBarItem(
              icon: Container(
                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                 decoration: BoxDecoration(color: _currentIndex == 2 ? Theme.of(context).colorScheme.secondaryContainer : Colors.transparent, borderRadius: BorderRadius.circular(20)),
                 child: Icon(Icons.chat, color: _currentIndex == 2 ? Colors.white : (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70)),
              ), 
              label: 'Messages'
            ),
            BottomNavigationBarItem(
              icon: Container(
                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                 decoration: BoxDecoration(color: _currentIndex == 3 ? Theme.of(context).colorScheme.secondaryContainer : Colors.transparent, borderRadius: BorderRadius.circular(20)),
                 child: Icon(Icons.person, color: _currentIndex == 3 ? Colors.white : (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70)),
              ), 
              label: 'Profile'
            ),
          ],
        ),
      ),
    );
  }
}
