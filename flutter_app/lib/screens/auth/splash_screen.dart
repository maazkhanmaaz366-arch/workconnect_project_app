import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'role_selection_screen.dart';
import 'package:flutter_animated_gradients/flutter_animated_gradients.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../worker/worker_dashboard.dart';
import '../employer/employer_dashboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user != null && authProvider.role != null) {
      if (authProvider.role == 'worker') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WorkerDashboard()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const EmployerDashboard()));
      }
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RoleSelectionScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedGradientBackground(
        gradientType: GradientType.linear,
        colors: const [
          Color(0xFF002045), // Theme.of(context).colorScheme.primary
          Color(0xFF003b7a), // Lighter primary
          Color(0xFFFE9743), // Theme.of(context).colorScheme.secondaryContainer
        ],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/logo.png', width: 120, height: 120)
                 .animate(onPlay: (controller) => controller.repeat(reverse: true))
                 .scaleXY(end: 1.1, duration: 1000.ms),
              const SizedBox(height: 16),
              const Text(
                'WorkConnect',
                style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
              )
              .animate()
              .fadeIn(duration: 600.ms)
              .slideY(begin: 0.3, end: 0),
              const SizedBox(height: 8),
              const Text(
                'Verified Skills. Fair Wages.',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              )
              .animate()
              .fadeIn(delay: 300.ms),
              const SizedBox(height: 48),
              const CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
