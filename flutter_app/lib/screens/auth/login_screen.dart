import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'signup_screen.dart';
import 'package:flutter_animated_gradients/flutter_animated_gradients.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../worker/worker_dashboard.dart';
import '../employer/employer_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isPasswordVisible = false;
  String? _errorMessage;

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
    });
  }

  Future<void> _login() async {
    setState(() {
      _errorMessage = null;
    });
    
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      _showError('Please enter a valid email address.');
      return;
    }
    if (password.isEmpty) {
      _showError('Please enter your password.');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      await authProvider.login(email, password);
      if (!mounted) return;
      
      // If successful, route to dashboard
      if (authProvider.role == 'worker') {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const WorkerDashboard()), (r) => false);
      } else {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const EmployerDashboard()), (r) => false);
      }
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = Provider.of<AuthProvider>(context).isLoading;
    final role = Provider.of<AuthProvider>(context, listen: false).role;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Login as ${role == "worker" ? "Worker" : "Employer"}', style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: AnimatedGradientBackground(
        gradientType: GradientType.linear,
        colors: const [
          Color(0xFF002045), // Theme.of(context).colorScheme.primary
          Color(0xFF003b7a), // Lighter primary
          Color(0xFFFE9743), // Theme.of(context).colorScheme.secondaryContainer
        ],
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  Icon(
                    role == 'worker' ? Icons.engineering : Icons.business_center,
                    size: 80,
                    color: const Color(0xFF1E3A8A),
                  ).animate().scale(duration: 400.ms),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _emailCtrl,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passCtrl,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    obscureText: !_isPasswordVisible,
                  ).animate().fadeIn(delay: 300.ms),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () async {
                         final email = _emailCtrl.text.trim();
                         if (email.isEmpty || !email.contains('@')) {
                           _showError('Please enter your email above to reset password.');
                           return;
                         }
                         try {
                           await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                           if (mounted) {
                             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset email sent! Check your inbox/spam folder.'), backgroundColor: Colors.green));
                           }
                         } catch (e) {
                           _showError(e.toString().replaceAll('Exception: ', '').replaceAll('[firebase_auth/user-not-found]', ''));
                         }
                      },
                      child: const Text('Forgot Password?'),
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn().slideY(begin: -0.1),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF002045),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isLoading 
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                      : const Text('Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ).animate().fadeIn(delay: 400.ms),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: isLoading ? null : () async {
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      try {
                        await authProvider.signInWithGoogle();
                        if (!mounted) return;
                        if (authProvider.role == 'worker') {
                          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const WorkerDashboard()), (r) => false);
                        } else if (authProvider.role == 'employer') {
                          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const EmployerDashboard()), (r) => false);
                        }
                      } catch (e) {
                         _showError(e.toString().replaceAll('Exception: ', ''));
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFF002045)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: Image.network(
                      'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/24px-Google_%22G%22_logo.svg.png', 
                      height: 24,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata, size: 24, color: Colors.blue),
                    ),
                    label: const Text('Sign in with Google', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF002045))),
                  ).animate().fadeIn(delay: 450.ms),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SignupScreen())),
                    child: const Text('Don\'t have an account? Sign Up', style: TextStyle(color: Color(0xFF002045))),
                  ).animate().fadeIn(delay: 500.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
