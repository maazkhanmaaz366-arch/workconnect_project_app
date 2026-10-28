import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'post_job_screen.dart';
import 'smart_matching_screen.dart';
import 'view_applicants_screen.dart';


class ManageJobsScreen extends StatelessWidget {
  const ManageJobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    
    return Scaffold(
      
      body: SafeArea(
        child: Column(
          children: [
             Padding(
               padding: const EdgeInsets.all(16.0),
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   Text("Manage Jobs", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                   ElevatedButton.icon(
                     style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.secondary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                     onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PostJobScreen())),
                     icon: const Icon(Icons.add, color: Colors.white, size: 18),
                     label: const Text("Post New Job", style: TextStyle(color: Colors.white)),
                   )
                 ],
               ),
             ),
             
             // List of jobs
             Expanded(
               child: StreamBuilder<QuerySnapshot>(
                 stream: FirebaseFirestore.instance.collection('jobs').where('employerId', isEqualTo: uid).snapshots(),
                 builder: (context, snapshot) {
                    if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    
                    final docs = snapshot.data!.docs.toList();
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

                    if (docs.isEmpty) {
                       return Center(child: Text("No jobs posted yet.", style: TextStyle(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70))));
                    }
                    
                    return ListView.builder(
                       padding: const EdgeInsets.symmetric(horizontal: 16),
                       itemCount: docs.length,
                       itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final status = data['status'] ?? 'Active';
                          
                          return Container(
                             margin: const EdgeInsets.only(bottom: 16),
                             decoration: BoxDecoration(color: Theme.of(context).cardColor, border: Border.all(color: Theme.of(context).colorScheme.surfaceContainerHighest), borderRadius: BorderRadius.circular(16)),
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.stretch,
                               children: [
                                  Container(height: 4, decoration: BoxDecoration(color: status == 'Active' ? Colors.green : Colors.grey, borderRadius: const BorderRadius.vertical(top: Radius.circular(16)))),
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                             Expanded(child: Text((data['category'] ?? 'GENERAL').toString().toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70), letterSpacing: 1.2), overflow: TextOverflow.ellipsis)),
                                             Container(
                                               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                               decoration: BoxDecoration(color: status == 'Active' ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                                               child: Text(status.toString().toUpperCase(), style: TextStyle(fontSize: 10, color: status == 'Active' ? Colors.green : Colors.grey, fontWeight: FontWeight.bold)),
                                             )
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(data['title'] ?? 'Job Title', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text("Rate: \$${data['budget']}/hr", style: TextStyle(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70))),
                                            StreamBuilder<QuerySnapshot>(
                                              stream: FirebaseFirestore.instance.collection('applications').where('jobId', isEqualTo: doc.id).snapshots(),
                                              builder: (ctx, appSnap) {
                                                int count = 0;
                                                if (appSnap.hasData) count = appSnap.data!.docs.length;
                                                return GestureDetector(
                                                  onTap: () {
                                                    Navigator.push(context, MaterialPageRoute(builder: (_) => ViewApplicantsScreen(jobId: doc.id, jobTitle: data['title'] ?? 'Job')));
                                                  },
                                                  child: Text("$count Applicants", style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.secondary, decoration: TextDecoration.underline)),
                                                );
                                              }
                                            )
                                          ]
                                        ),
                                        const SizedBox(height: 16),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                onPressed: () {
                                                  Navigator.push(context, MaterialPageRoute(builder: (_) => PostJobScreen(jobId: doc.id, initialData: data)));
                                                },
                                                style: OutlinedButton.styleFrom(side: BorderSide(color: Theme.of(context).colorScheme.surfaceContainerHighest), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                                icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.primary, size: 18),
                                                label: Text("Edit", style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: ElevatedButton.icon(
                                                style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.secondaryContainer, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                                onPressed: () {
                                                   Navigator.push(context, MaterialPageRoute(builder: (_) => SmartMatchingScreen(
                                                      jobId: doc.id, 
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
                                      ]
                                    )
                                  )
                               ]
                             )
                          );
                       }
                    );
                 }
               )
             )
          ]
        )
      )
    );
  }
}
