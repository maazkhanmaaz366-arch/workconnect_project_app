import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'package:flutter_animated_gradients/flutter_animated_gradients.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'login_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? _selectedRole; // 'worker' or 'employer'

  Widget _buildRoleCard({
    required String role,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withOpacity(isSelected ? 1.0 : 0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFFE9743) : Colors.transparent,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: const Color(0xFFFE9743).withOpacity(0.5), blurRadius: 15, spreadRadius: 2)]
              : [],
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: isSelected ? const Color(0xFFFE9743) : const Color(0xFF1E3A8A).withOpacity(0.1),
              child: Icon(icon, size: 40, color: isSelected ? Colors.white : const Color(0xFF1E3A8A)),
            ),
            const SizedBox(height: 16),
            Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isSelected ? const Color(0xFF002045) : const Color(0xFF1E3A8A))),
            const SizedBox(height: 8),
            Text(description, textAlign: TextAlign.center, style: TextStyle(color: (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white), fontSize: 14)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('WORKCONNECT', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: const [
          Center(child: Padding(padding: EdgeInsets.only(right: 16), child: Text('Step 1 of 3', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)))),
        ],
      ),
      body: AnimatedGradientBackground(
        gradientType: GradientType.linear,
        colors: const [
          Color(0xFF002045), // Theme.of(context).colorScheme.primary
          Color(0xFF003b7a), // Lighter primary
          Color(0xFFFE9743), // Theme.of(context).colorScheme.secondaryContainer
        ],
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                const Text('Welcome to WorkConnect', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white))
                    .animate().fadeIn(duration: 400.ms).slideY(begin: -0.2),
                const SizedBox(height: 8),
                const Text('Select how you want to use the platform to get started.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 16))
                    .animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 32),
                
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildRoleCard(
                          role: 'worker',
                          title: 'I am a Worker',
                          description: 'Find jobs, manage your schedule, and get paid securely for your skills.',
                          icon: Icons.engineering,
                        ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.2),
                        const SizedBox(height: 16),
                        _buildRoleCard(
                          role: 'employer',
                          title: 'I am a Business',
                          description: 'Hire verified pros, manage site tasks, and scale your operations.',
                          icon: Icons.storefront,
                        ).animate().fadeIn(delay: 500.ms).slideX(begin: 0.2),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _selectedRole == null ? null : () {
                    Provider.of<AuthProvider>(context, listen: false).setRole(_selectedRole!);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFE9743),
                    disabledBackgroundColor: Colors.white30,
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Continue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.2),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
