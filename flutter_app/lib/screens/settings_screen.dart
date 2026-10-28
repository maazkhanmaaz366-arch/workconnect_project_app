import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';


class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _locationTracking = true;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final primary = isDark ? Colors.white : Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary], begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
        ),
        
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 10,
        shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.5),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("PREFERENCES", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          _buildSettingsCard([
            SwitchListTile(
              activeColor: Theme.of(context).colorScheme.primary,
              title: const Text("Push Notifications", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("Receive alerts for jobs & messages", style: Theme.of(context).textTheme.labelSmall),
              value: _notificationsEnabled,
              onChanged: (v) => setState(() => _notificationsEnabled = v),
              secondary: Icon(Icons.notifications_active, color: Theme.of(context).colorScheme.primary),
            ),
            const Divider(height: 1),
            SwitchListTile(
              activeColor: const Color(0xFFFE9743),
              title: Text("Dark Mode", style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
              subtitle: Text("Use dark theme across the app", style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color)),
              value: isDark,
              onChanged: (v) {
                Provider.of<ThemeProvider>(context, listen: false).toggleTheme(v);
              },
              secondary: Icon(Icons.dark_mode, color: primary),
            ),
            const Divider(height: 1),
            SwitchListTile(
              activeColor: Theme.of(context).colorScheme.primary,
              title: const Text("Location Tracking", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("Required for Smart Matching", style: Theme.of(context).textTheme.labelSmall),
              value: _locationTracking,
              onChanged: (v) => setState(() => _locationTracking = v),
              secondary: Icon(Icons.location_on, color: Theme.of(context).colorScheme.primary),
            ),
          ], isDark),
          
          const SizedBox(height: 24),
          const Text("ACCOUNT", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          _buildSettingsCard([
            ListTile(
              leading: Icon(Icons.lock, color: Theme.of(context).colorScheme.primary),
              title: const Text("Change Password", style: TextStyle(fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset email sent!')));
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text("Delete Account", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
              trailing: const Icon(Icons.chevron_right, color: Colors.red),
              onTap: () {
                showDialog(context: context, builder: (_) => AlertDialog(
                  title: const Text("Delete Account?"),
                  content: const Text("This action cannot be undone. Are you sure?"),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                    ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text("Delete", style: TextStyle(color: Colors.white))),
                  ],
                ));
              },
            ),
          ], isDark)
        ],
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? [] : [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200)
      ),
      child: Column(children: children),
    );
  }
}
