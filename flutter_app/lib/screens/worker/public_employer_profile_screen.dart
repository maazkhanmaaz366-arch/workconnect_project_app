import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class PublicEmployerProfileScreen extends StatelessWidget {
  final Map<String, dynamic> employer;

  const PublicEmployerProfileScreen({super.key, required this.employer});

  @override
  Widget build(BuildContext context) {
    final companyName = employer['companyName'] ?? 'Unknown Company';
    final industry = employer['industry'] ?? 'N/A';
    final companySize = employer['companySize'] ?? 'N/A';
    final location = employer['location'] ?? 'Unknown Location';
    final bio = employer['bio'] ?? 'No bio provided.';
    final website = employer['website'] ?? 'No website available.';
    final photoUrl = employer['photoUrl'];
    final isVerified = employer['isVerified'] == true;
    final employerId = employer['uid'] ?? employer['employerId'];

    return Scaffold(
      
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: Text(companyName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary], begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
        ),
        
        elevation: 10,
        shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.5),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [Theme.of(context).colorScheme.secondary, Theme.of(context).colorScheme.primary]),
                boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: CircleAvatar(
                radius: 60,
                
                backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                child: photoUrl == null ? Icon(Icons.business, size: 60, color: Theme.of(context).colorScheme.primary) : null,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(companyName, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                if (isVerified) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.verified, color: Colors.green, size: 28),
                ]
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on, size: 16, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70)),
                const SizedBox(width: 4),
                Text(location, style: TextStyle(fontSize: 14, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70), fontWeight: FontWeight.bold)),
              ],
            ),
            
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 4))],
                border: Border.all(color: Colors.grey.shade100)
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Company Overview", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                  const SizedBox(height: 16),
                  Text(bio, style: TextStyle(fontSize: 14, color: (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white), height: 1.5)),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  _buildDetailRow(context, Icons.category, "Industry", industry),
                  const SizedBox(height: 16),
                  _buildDetailRow(context, Icons.groups, "Company Size", companySize),
                  const SizedBox(height: 16),
                  _buildDetailRow(context, Icons.language, "Website", website),
                  const SizedBox(height: 16),
                  if (isVerified)
                    _buildDetailRow(context, Icons.verified, "Status", "Verified by WorkConnect", iconColor: Colors.green)
                  else
                    _buildDetailRow(context, Icons.warning_amber_rounded, "Status", "Unverified Employer", iconColor: Colors.orange),
                  const SizedBox(height: 16),
                  if (employerId != null)
                    FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance.collection('jobs').where('employerId', isEqualTo: employerId).get(),
                      builder: (context, snapshot) {
                         if (snapshot.connectionState == ConnectionState.waiting) return const CircularProgressIndicator();
                         int totalJobs = snapshot.data?.docs.length ?? 0;
                         return _buildDetailRow(context, Icons.work_history, "Platform Activity", "$totalJobs Jobs Posted", iconColor: Theme.of(context).colorScheme.primary);
                      }
                    ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String title, String value, {Color? iconColor}) {
    iconColor ??= Theme.of(context).colorScheme.secondary;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 12, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70), fontWeight: FontWeight.bold)),
            Text(value, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
          ],
        )
      ],
    );
  }
}
