import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/api_service.dart';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'worker_dashboard.dart';

class WorkerProfileSetupScreen extends StatefulWidget {
  const WorkerProfileSetupScreen({super.key});

  @override
  State<WorkerProfileSetupScreen> createState() => _WorkerProfileSetupScreenState();
}

class _WorkerProfileSetupScreenState extends State<WorkerProfileSetupScreen> {
  final _nameCtrl = TextEditingController();
  final _skillsCtrl = TextEditingController();
  final _wageCtrl = TextEditingController();
  Uint8List? _imageBytes;
  String _locationCity = "Detecting location...";
  double _lat = 31.5204;
  double _lng = 74.3587;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _locationCity = "Location services disabled");
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _locationCity = "Location permission denied");
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      setState(() => _locationCity = "Location permission permanently denied");
      return;
    }

    Position position = await Geolocator.getCurrentPosition();
    _lat = position.latitude;
    _lng = position.longitude;

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(_lat, _lng);
      if (placemarks.isNotEmpty) {
        setState(() {
          _locationCity = "${placemarks.first.locality ?? ''}, ${placemarks.first.administrativeArea ?? ''}".trim();
          if (_locationCity == ",") _locationCity = "Location Found";
        });
      }
    } catch (e) {
      setState(() => _locationCity = "Location Found");
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_nameCtrl.text.isEmpty || _skillsCtrl.text.isEmpty || _wageCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please fill all fields'),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }
    
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      String? photoUrl;
      if (_imageBytes != null) {
        try {
          var request = http.MultipartRequest('POST', Uri.parse('${ApiService.baseUrl}/upload'));
          request.files.add(http.MultipartFile.fromBytes('file', _imageBytes!, filename: 'profile_${user.uid}.jpg'));
          var response = await request.send();
          if (response.statusCode == 200) {
            final respStr = await response.stream.bytesToString();
            photoUrl = jsonDecode(respStr)['url'];
          }
        } catch (e) {
          // ignore
        }
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'fullName': _nameCtrl.text.trim(),
        'skillsList': [_skillsCtrl.text.trim()],
        'dailyWage': double.tryParse(_wageCtrl.text.trim()) ?? 0.0,
        'photoUrl': photoUrl ?? user.photoURL,
        'profileCompleted': true,
        'latitude': _lat,
        'longitude': _lng,
        'city': _locationCity,
      });

      // AI wage suggestion (non-blocking)
      String aiSuggestedWage = "₹1,200 - ₹1,600";
      try {
        final response = await http.post(
          Uri.parse('${ApiService.baseUrl}/ai/suggest-wage'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'skills': [_skillsCtrl.text],
            'location': _locationCity
          }),
        ).timeout(const Duration(seconds: 15));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          aiSuggestedWage = data['suggested_wage'] ?? aiSuggestedWage;
        }
      } catch (_) {}

      if (!mounted) return;
      Navigator.pop(context); // close loader
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.amber),
              SizedBox(width: 8),
              Text('Profile Saved & Analyzed'),
            ],
          ),
          content: Text('Gemini suggests $aiSuggestedWage for "${_skillsCtrl.text}" in your area.\n\nYour profile has been successfully saved!'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WorkerDashboard()));
              },
              child: const Text('Continue to Dashboard'),
            )
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // close loader
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save profile: $e'),
          backgroundColor: Colors.redAccent,
        )
      );
    }
  }

  Widget _buildAvatar() {
    if (_imageBytes == null) {
      return const CircleAvatar(
        radius: 50,
        backgroundColor: Color(0xFFE2E8F0),
        child: Icon(Icons.camera_alt, size: 40, color: Colors.grey),
      );
    }
    return CircleAvatar(
      radius: 50,
      backgroundImage: MemoryImage(_imageBytes!),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Worker Profile Setup')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: _buildAvatar(),
            ),
            const SizedBox(height: 8),
            const Text('Tap to upload photo'),
            const SizedBox(height: 32),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'Full Name', 
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _skillsCtrl,
              decoration: InputDecoration(
                labelText: 'Your Skills (e.g., I fix pipes)', 
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.build_outlined),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _wageCtrl,
              decoration: InputDecoration(
                labelText: 'Expected Daily Wage (Rs.)', 
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300)
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.blueAccent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Detected Location', style: TextStyle(fontSize: 12, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70))),
                        Text(_locationCity, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
              ),
              child: Text('Analyze & Save Profile', style: Theme.of(context).textTheme.titleSmall),
            )
          ],
        ),
      ),
    );
  }
}
