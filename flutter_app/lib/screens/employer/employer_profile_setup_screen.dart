import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/api_service.dart';
import 'dart:typed_data';
import 'employer_dashboard.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';


class EmployerProfileSetupScreen extends StatefulWidget {
  const EmployerProfileSetupScreen({super.key});

  @override
  State<EmployerProfileSetupScreen> createState() => _EmployerProfileSetupScreenState();
}

class _EmployerProfileSetupScreenState extends State<EmployerProfileSetupScreen> {
  final _nameCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  Uint8List? _imageBytes;
  bool _isSaving = false;
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
    if (_nameCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter your name'),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }
    
    setState(() => _isSaving = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
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
           // Ignore errors if offline
         }
       }

       await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'fullName': _nameCtrl.text,
          'companyName': _companyCtrl.text,
          'role': 'employer',
          'profileCompleted': true,
          'latitude': _lat,
          'longitude': _lng,
          'city': _locationCity,
          if (photoUrl != null) 'photoUrl': photoUrl,
       }, SetOptions(merge: true));
    }
    setState(() => _isSaving = false);
    
    if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const EmployerDashboard()));
  }

  Widget _buildAvatar() {
    return Stack(
      children: [
        Container(
          width: 120, height: 120,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Theme.of(context).colorScheme.surfaceContainerHighest, width: 2),
            image: _imageBytes != null ? DecorationImage(image: MemoryImage(_imageBytes!), fit: BoxFit.cover) : null,
          ),
          child: _imageBytes == null ? Icon(Icons.business, size: 60, color: Theme.of(context).colorScheme.primary) : null,
        ),
        Positioned(
          bottom: -4, right: -4,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondaryContainer, shape: BoxShape.circle),
            child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        title: Text('Employer Setup', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
        
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.primary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: _buildAvatar(),
            ),
            const SizedBox(height: 16),
            Text('Upload Company Logo', style: TextStyle(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70), fontWeight: FontWeight.bold)),
            const SizedBox(height: 48),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'Your Full Name', 
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.surfaceContainerHighest)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.surfaceContainerHighest)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)),
                prefixIcon: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _companyCtrl,
              decoration: InputDecoration(
                labelText: 'Company Name', 
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.surfaceContainerHighest)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.surfaceContainerHighest)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)),
                prefixIcon: Icon(Icons.business, color: Theme.of(context).colorScheme.primary),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.surfaceContainerHighest)
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: Theme.of(context).colorScheme.secondaryContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Detected Location', style: TextStyle(fontSize: 12, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70))),
                        Text(_locationCity, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 60),
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
              ),
              child: _isSaving 
                 ? const CircularProgressIndicator(color: Colors.white)
                 : const Text('Save & Enter Dashboard', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }
}
