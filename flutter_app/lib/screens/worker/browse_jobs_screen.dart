import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'public_employer_profile_screen.dart';


class BrowseJobsScreen extends StatefulWidget {
  const BrowseJobsScreen({super.key});

  @override
  State<BrowseJobsScreen> createState() => _BrowseJobsScreenState();
}

class _BrowseJobsScreenState extends State<BrowseJobsScreen> {
  String _searchQuery = "";
  String _selectedCategory = "All Jobs";
  String _sortBy = "Newest";
  final List<String> _categories = ["All Jobs", "Plumbing", "Electrical", "Carpentry", "Painting", "General Labor"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search jobs (e.g., Senior Carpenter)...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),

            // Category Filters
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedCategory = cat);
                      },
                      selectedColor: Theme.of(context).colorScheme.primary,
                      labelStyle: TextStyle(color: isSelected ? Colors.white : (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white)),
                      
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            
            // Sort Dropdown
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("$_sortBy Jobs", style: TextStyle(fontWeight: FontWeight.bold, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70))),
                  DropdownButton<String>(
                    value: _sortBy,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: "Newest", child: Text("Sort by: Newest")),
                      DropdownMenuItem(value: "Pay (High to Low)", child: Text("Sort by: Pay")),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _sortBy = val);
                    },
                  )
                ],
              )
            ),

            // Job Feed
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('jobs').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return const Center(child: Text("Error loading jobs"));
                  if (!snapshot.hasData) {
                     return ListView.builder(
                        itemCount: 5,
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) => Shimmer.fromColors(
                           baseColor: Colors.grey[300]!,
                           highlightColor: Colors.grey[100]!,
                           child: Container(
                             margin: const EdgeInsets.only(bottom: 16),
                             height: 150,
                             decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16)),
                           ),
                        )
                     );
                  }

                  // Filter logic
                  var docs = snapshot.data!.docs.where((doc) {
                     final data = doc.data() as Map<String, dynamic>;
                     if (data['status'] == 'Draft') return false;
                     if (_selectedCategory != "All Jobs") {
                         if ((data['category'] ?? '').toString().toLowerCase() != _selectedCategory.toLowerCase()) {
                            return false;
                         }
                     }
                     if (_searchQuery.isNotEmpty) {
                         if (!(data['title'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase())) {
                            return false;
                         }
                     }
                     return true;
                  }).toList();

                  // Sorting logic
                  if (_sortBy == "Newest") {
                    docs.sort((a, b) {
                      Timestamp parseTime(dynamic val) {
                        if (val is Timestamp) return val;
                        if (val is String) return Timestamp.fromDate(DateTime.tryParse(val) ?? DateTime.now());
                        return Timestamp.now();
                      }
                      final aTime = parseTime((a.data() as Map<String, dynamic>)['timestamp']);
                      final bTime = parseTime((b.data() as Map<String, dynamic>)['timestamp']);
                      return bTime.compareTo(aTime);
                    });
                  } else if (_sortBy == "Pay (High to Low)") {
                     docs.sort((a, b) {
                        final aPay = (a.data() as Map)['budget'] ?? 0.0;
                        final bPay = (b.data() as Map)['budget'] ?? 0.0;
                        return bPay.compareTo(aPay);
                     });
                  }

                  if (docs.isEmpty) {
                     return Center(child: Text("No jobs found.", style: TextStyle(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70))));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      // AI Match Simulation (random between 80 and 99 for demo, real app would calculate)
                      final matchScore = 80 + (index * 7 % 20); 

                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance.collection('users').doc(data['employerId']).get(),
                        builder: (context, empSnapshot) {
                          String companyName = 'Loading Company...';
                          String? photoUrl;
                          bool isVerified = false;
                          Map<String, dynamic> empData = {};
                          
                          if (empSnapshot.hasData && empSnapshot.data!.exists) {
                             empData = empSnapshot.data!.data() as Map<String, dynamic>;
                             companyName = empData['companyName'] ?? 'Unknown Company';
                             photoUrl = empData['photoUrl'];
                             isVerified = empData['isVerified'] == true;
                          }

                          return GestureDetector(
                            onTap: () {
                               if (empSnapshot.hasData && empSnapshot.data!.exists) {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => PublicEmployerProfileScreen(employer: {'uid': data['employerId'], ...empData})));
                               }
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                 color: Theme.of(context).cardColor, 
                                 border: Border.all(color: matchScore > 90 ? Theme.of(context).colorScheme.secondaryContainer : Theme.of(context).colorScheme.surfaceContainerHighest, width: matchScore > 90 ? 2 : 1), 
                                 borderRadius: BorderRadius.circular(16),
                                 boxShadow: [
                                   BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                                 ]
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (matchScore > 90)
                                    Container(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(colors: [Theme.of(context).colorScheme.secondary, Theme.of(context).colorScheme.secondaryContainer]),
                                        borderRadius: BorderRadius.vertical(top: Radius.circular(14))
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                                          const SizedBox(width: 8),
                                          Text("$matchScore% SMART MATCH", style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                                        ],
                                      ),
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 20,
                                              
                                              backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                                              child: photoUrl == null ? Icon(Icons.business, color: Theme.of(context).colorScheme.primary) : null,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Flexible(child: Text(companyName, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white)))),
                                                      if (isVerified) ...[
                                                        const SizedBox(width: 4),
                                                        const Icon(Icons.verified, color: Colors.green, size: 14),
                                                      ]
                                                    ],
                                                  ),
                                                  Text((data['category'] ?? 'General').toString().toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.secondary, letterSpacing: 1.2)),
                                                ],
                                              )
                                            )
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(data['title'] ?? 'Job Title', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.location_on, size: 14, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70)),
                                            const SizedBox(width: 4),
                                            Expanded(child: Text(data['location'] ?? 'Location', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70)))),
                                            const SizedBox(width: 8),
                                            Icon(Icons.access_time, size: 14, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70)),
                                            const SizedBox(width: 4),
                                            Text("Posted recently", style: TextStyle(fontSize: 12, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70))),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text("Suggested Rate", style: TextStyle(fontSize: 12, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70))),
                                                Text("PKR ${data['budget']}/hr", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                                              ],
                                            ),
                                            ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Theme.of(context).colorScheme.primary, 
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                elevation: 4,
                                                shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.5)
                                              ),
                                              onPressed: () async {
                                                  try {
                                                     await FirebaseFirestore.instance.collection('applications').add({
                                                        'jobId': doc.id,
                                                        'jobTitle': data['title'],
                                                        'workerId': FirebaseAuth.instance.currentUser?.uid,
                                                        'status': 'pending',
                                                        'timestamp': FieldValue.serverTimestamp(),
                                                     });
                                                     if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Applied successfully!'), backgroundColor: Colors.green));
                                                  } catch (e) {
                                                     if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
                                                  }
                                              },
                                              icon: const Icon(Icons.send, size: 16, color: Colors.white),
                                              label: const Text("Apply Now", style: TextStyle(color: Colors.white)),
                                            )
                                          ],
                                        )
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.1);
                        }
                      );
                    },
                  );
                }
              ),
            )
          ],
        ),
      )
    );
  }
}
