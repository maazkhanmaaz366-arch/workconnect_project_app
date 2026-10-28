import 'package:flutter/material.dart';


class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: const Text('Help & Support', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.support_agent, size: 80, color: Theme.of(context).colorScheme.secondary),
            const SizedBox(height: 16),
            Text("How can we help you?", textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
            const SizedBox(height: 8),
            Text("We're here to assist you with any issues or questions.", textAlign: TextAlign.center, style: TextStyle(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70))),
            const SizedBox(height: 32),
            
            _buildFAQCard(context, "How do I get paid?", "Payments are held in escrow when a job starts and are released directly to your wallet once the employer approves the work."),
            const SizedBox(height: 12),
            _buildFAQCard(context, "How does AI Smart Matching work?", "Our AI analyzes your skills, location, and past reviews to suggest the best jobs or workers near you instantly."),
            const SizedBox(height: 12),
            _buildFAQCard(context, "Can I change my account type?", "Currently, you must create a separate account using a different email if you wish to switch between Employer and Worker permanently."),
            
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary, Color(0xFF003B73)]),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 8))]
              ),
              child: Column(
                children: [
                  const Text("Need Direct Support?", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text("Email our professional support team at:", style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(color: Theme.of(context).cardColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.email, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text("songhop757@gmail.com", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening email client...')));
                    },
                    style: ElevatedButton.styleFrom(
                      
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                    ),
                    child: const Text("Send us an Email", style: TextStyle(fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildFAQCard(BuildContext context, String question, String answer) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.grey.shade200)
      ),
      child: ExpansionTile(
        title: Text(question, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Theme.of(context).colorScheme.primary)),
        iconColor: Theme.of(context).colorScheme.secondary,
        collapsedIconColor: Theme.of(context).colorScheme.primary,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: Text(answer, style: TextStyle(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70), fontSize: 13, height: 1.5)),
          )
        ],
      ),
    );
  }
}
