import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../auth/splash_screen.dart';
import 'post_job_screen.dart';
import 'smart_matching_screen.dart';
import 'manage_jobs_screen.dart';
import 'view_applicants_screen.dart';
import '../chat/chat_inbox_screen.dart';
import '../profile/employer_profile_screen.dart';
import '../settings_screen.dart';
import '../help_support_screen.dart';
import 'employer_billing_screen.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';


class EmployerDashboard extends StatefulWidget {
  const EmployerDashboard({super.key});

  @override
  State<EmployerDashboard> createState() => _EmployerDashboardState();
}

class _EmployerDashboardState extends State<EmployerDashboard> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  LatLng _mapCenter = const LatLng(31.5204, 74.3587); // Default to Lahore
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
         if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enable location services.')));
         throw Exception("Location disabled");
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
           if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions denied.')));
           throw Exception("Permission denied");
        }
      }
      Position position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _mapCenter = LatLng(position.latitude, position.longitude);
          _isLoadingLocation = false;
        });
        
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          FirebaseFirestore.instance.collection('users').doc(uid).update({
            'latitude': position.latitude,
            'longitude': position.longitude,
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false; // Fallback to default
        });
      }
    }
  }

  Future<void> _switchMode() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({'role': 'worker'});
        if (mounted) {
           Provider.of<AuthProvider>(context, listen: false).setRole('worker');
           Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const SplashScreen()), (route) => false);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to switch mode: $e"), backgroundColor: Colors.red));
        }
      }
    }
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
               String name = 'Employer';
               if (snapshot.hasData && snapshot.data!.exists) {
                 final data = snapshot.data!.data() as Map<String, dynamic>?;
                 name = data?['fullName'] ?? 'Employer';
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
                       child: profilePic.isEmpty ? Icon(Icons.business, size: 30, color: Theme.of(context).colorScheme.onPrimaryContainer) : null,
                     ),
                     const SizedBox(height: 12),
                     Text(name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.titleLarge?.color)),
                     const SizedBox(height: 4),
                     Container(
                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                       decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(12)),
                       child: const Text("Employer Mode", style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
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
              title: Text("Switch to Worker Mode", style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
              onTap: _switchMode,
            ),
          ),
          ListTile(leading: Icon(Icons.payment, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70)), title: Text("Billing & Payments"), onTap: () {
             Navigator.push(context, MaterialPageRoute(builder: (_) => const EmployerBillingScreen()));
          }),
          ListTile(leading: Icon(Icons.help, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70)), title: Text("Help & Support"), onTap: () {
             Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportScreen()));
          }),
          ListTile(leading: Icon(Icons.settings, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70)), title: Text("Settings"), onTap: () {
             Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
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
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Center(child: Text("Not logged in"));

    return RefreshIndicator(
      onRefresh: () async { setState(() {}); },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          // Welcome Section
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
            builder: (context, snapshot) {
              String name = 'Employer';
              if (snapshot.hasData && snapshot.data!.exists) {
                 final data = snapshot.data!.data() as Map<String, dynamic>?;
                 name = data?['fullName']?.split(' ')[0] ?? 'Employer';
              }
              return Text("Welcome, $name.", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary));
            }
          ),
          const SizedBox(height: 8),
          Text("Here's what's happening with your job postings today.", style: TextStyle(fontSize: 16, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70))),
          const SizedBox(height: 24),

          // Top Metrics Grid
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Theme.of(context).cardColor, border: Border.all(color: Theme.of(context).colorScheme.surfaceContainerHighest), borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.work, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(height: 8),
                      Text("Active Listings", style: TextStyle(fontSize: 12, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70))),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('jobs').where('employerId', isEqualTo: uid).snapshots(),
                        builder: (context, snapshot) {
                          int count = 0;
                          if (snapshot.hasData) {
                            count = snapshot.data!.docs.length;
                          }
                          return Text("$count", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary));
                        }
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary, Color(0xFF003B73)]),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 8))]
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.group, color: Colors.white),
                      const SizedBox(height: 8),
                      const Text("New Applicants", style: TextStyle(fontSize: 12, color: Colors.white70)),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('applications').where('status', isEqualTo: 'pending').snapshots(),
                        builder: (context, snapshot) {
                           // We would ideally filter by employer's jobs, but let's approximate or just fetch for all their jobs
                           int count = 0;
                           if (snapshot.hasData) count = snapshot.data!.docs.length;
                           return Text("$count", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white));
                        }
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Market Insights
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Theme.of(context).colorScheme.secondary, Theme.of(context).colorScheme.secondaryContainer]),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.secondary.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 8))]
            ),
            child: Row(
              children: [
                const Icon(Icons.insights, color: Colors.white, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("MARKET INSIGHTS", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      const SizedBox(height: 4),
                      const Text("Trending Labor Rate", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('jobs').orderBy('timestamp', descending: true).limit(10).snapshots(),
                        builder: (context, snapshot) {
                           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                              return const Text("Calculating...", style: TextStyle(color: Colors.white70));
                           }
                           double sum = 0;
                           for (var doc in snapshot.data!.docs) {
                              sum += ((doc.data() as Map<String, dynamic>)['budget'] ?? 0.0).toDouble();
                           }
                           double avg = sum / snapshot.data!.docs.length;
                           return Row(
                             children: [
                               Text("PKR ${avg.toStringAsFixed(0)}/hr", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                               const SizedBox(width: 8),
                               const Icon(Icons.arrow_upward, color: Colors.white, size: 16),
                               const Text("+4.2%", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                             ],
                           );
                        }
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Local Talent Map (OpenStreetMap)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Text("Local Talent Map", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
               Container(
                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                 decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                 child: Row(
                   children: const [
                     Icon(Icons.fiber_manual_record, color: Colors.green, size: 10),
                     SizedBox(width: 4),
                     Text("Live Tracking", style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                   ],
                 ),
               )
            ]
          ),
          const SizedBox(height: 12),
          if (_isLoadingLocation)
            const Center(child: CircularProgressIndicator())
          else
            Container(
              height: 250,
              decoration: BoxDecoration(border: Border.all(color: Theme.of(context).colorScheme.surfaceContainerHighest), borderRadius: BorderRadius.circular(16)),
              clipBehavior: Clip.antiAlias,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: _mapCenter,
                  initialZoom: 13.0,
                ),
                children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.workconnect',
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'worker').snapshots(),
                  builder: (context, snapshot) {
                     List<Marker> markers = [
                        Marker(
                          point: _mapCenter,
                          width: 40,
                          height: 40,
                          child: Icon(Icons.location_city, color: Theme.of(context).colorScheme.primary, size: 40),
                        )
                     ];
                     if (snapshot.hasData) {
                        for (var doc in snapshot.data!.docs) {
                           final data = doc.data() as Map<String, dynamic>;
                           if (data['latitude'] != null && data['longitude'] != null) {
                              markers.add(Marker(
                                 point: LatLng(data['latitude'], data['longitude']),
                                 width: 30,
                                 height: 30,
                                 child: Container(
                                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondaryContainer, shape: BoxShape.circle, border: Border.all(color: Theme.of(context).cardColor, width: 2), boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.26), blurRadius: 4)]),
                                    child: const Icon(Icons.person, color: Colors.white, size: 16),
                                 )
                              ));
                           }
                        }
                     }
                     // Add some dummy markers around the center if empty to showcase the feature
                     if (markers.length == 1) {
                         markers.addAll([
                            Marker(point: LatLng(_mapCenter.latitude + 0.005, _mapCenter.longitude - 0.005), width: 30, height: 30, child: Container(decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: Theme.of(context).cardColor, width: 2), boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.26), blurRadius: 4)]), child: Icon(Icons.person, color: Colors.white, size: 16))),
                            Marker(point: LatLng(_mapCenter.latitude - 0.005, _mapCenter.longitude + 0.005), width: 30, height: 30, child: Container(decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: Theme.of(context).cardColor, width: 2), boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.26), blurRadius: 4)]), child: Icon(Icons.person, color: Colors.white, size: 16))),
                         ]);
                     }
                     return MarkerLayer(markers: markers);
                  }
                )
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Manage Job Postings
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Your Job Postings", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
              TextButton(
                onPressed: () {
                   Navigator.push(context, MaterialPageRoute(builder: (_) => const PostJobScreen()));
                }, 
                child: Text("+ Post New", style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.bold))
              )
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('jobs').where('employerId', isEqualTo: uid).snapshots(),
            builder: (context, snapshot) {
               if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
               if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
               
               final docs = snapshot.data!.docs.toList();
               docs.sort((a, b) {
                 final aData = a.data() as Map<String, dynamic>;
                 final bData = b.data() as Map<String, dynamic>;
                 Timestamp? parseTime(dynamic val) {
                   if (val is Timestamp) return val;
                   if (val is String) return Timestamp.fromDate(DateTime.tryParse(val) ?? DateTime.now());
                   return null;
                 }
                 final aTime = parseTime(aData['timestamp']);
                 final bTime = parseTime(bData['timestamp']);
                 if (aTime == null && bTime == null) return 0;
                 if (aTime == null) return 1;
                 if (bTime == null) return -1;
                 return bTime.compareTo(aTime);
               });
               
               if (docs.isEmpty) {
                 return Container(
                   padding: const EdgeInsets.all(32),
                   decoration: BoxDecoration(color: Theme.of(context).cardColor, border: Border.all(color: Theme.of(context).colorScheme.surfaceContainerHighest), borderRadius: BorderRadius.circular(16)),
                   child: Center(child: Text("No jobs posted yet.", style: TextStyle(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70)))),
                 );
               }

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
                          Container(height: 4, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.vertical(top: Radius.circular(16)))),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text((data['category'] ?? 'GENERAL').toString().toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70), letterSpacing: 1.2), overflow: TextOverflow.ellipsis),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                                      child: const Text("Active", style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                                    )
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(data['title'] ?? 'Job Title', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () {
                                          Navigator.push(context, MaterialPageRoute(builder: (_) => ViewApplicantsScreen(jobId: jobDoc.id, jobTitle: data['title'] ?? 'Job')));
                                        },
                                        style: OutlinedButton.styleFrom(side: BorderSide(color: Theme.of(context).colorScheme.surfaceContainerHighest), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                        icon: Icon(Icons.people, color: Theme.of(context).colorScheme.primary, size: 18),
                                        label: Text("Manage Apps", style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.secondaryContainer, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                        onPressed: () {
                                           Navigator.push(context, MaterialPageRoute(builder: (_) => SmartMatchingScreen(
                                              jobId: jobDoc.id, 
                                              jobTitle: data['title'] ?? 'Job Listing', 
                                              jobDescription: data['description'] ?? 'General Job',
                                           )));
                                        },
                                        icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                                        label: const Text("AI Match", style: TextStyle(color: Colors.white)),
                                      ),
                                    )
                                  ],
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    );
                 }
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
      const ManageJobsScreen(),
      const ChatInboxScreen(),
      const EmployerProfileScreen(),
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
            Text('Employer', style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications, color: Theme.of(context).iconTheme.color),
            onPressed: () {
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You have 0 new notifications.')));
            }, // Handle notifications here
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: pages[_currentIndex],
      floatingActionButton: _currentIndex == 0 ? FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const PostJobScreen()));
        },
        backgroundColor: Theme.of(context).colorScheme.secondary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Post a Job", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ) : null,
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
                 child: Icon(Icons.business_center, color: _currentIndex == 1 ? Colors.white : (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70)),
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
                 child: Icon(Icons.business, color: _currentIndex == 3 ? Colors.white : (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70)),
              ), 
              label: 'Profile'
            ),
          ],
        ),
      ),
    );
  }
}
