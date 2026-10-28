import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/api_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';

class PostJobScreen extends StatefulWidget {
  final String? jobId;
  final Map<String, dynamic>? initialData;
  
  const PostJobScreen({super.key, this.jobId, this.initialData});

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  
  String _selectedCategory = "General Labor";
  final List<String> _categories = ["Plumbing", "Electrical", "Carpentry", "Painting", "General Labor", "Masonry"];
  
  bool _isLoading = false;
  LatLng _selectedLocation = const LatLng(31.5204, 74.3587); // Default Lahore
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _determinePosition();
    if (widget.initialData != null) {
      _titleCtrl.text = widget.initialData!['title'] ?? '';
      _descCtrl.text = widget.initialData!['description'] ?? '';
      _budgetCtrl.text = (widget.initialData!['budget'] ?? '').toString();
      if (widget.initialData!['category'] != null) {
        String cat = widget.initialData!['category'];
        // Remove markdown bolding if AI mistakenly included it
        cat = cat.replaceAll('**', '').trim();
        if (!_categories.contains(cat)) {
           _categories.add(cat);
        }
        _selectedCategory = cat;
      }
      if (widget.initialData!['location'] != null) {
        // assuming location is a GeoPoint or Map
      }
    }
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _selectedLocation = LatLng(position.latitude, position.longitude);
      _mapController.move(_selectedLocation, 14.0);
    });
  }

  void _submitJob() async {
    if (_titleCtrl.text.isEmpty || _descCtrl.text.isEmpty || _budgetCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Please login first.");

      String locationName = "Location Set";
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(_selectedLocation.latitude, _selectedLocation.longitude);
        if (placemarks.isNotEmpty) {
          locationName = "${placemarks.first.locality ?? ''}, ${placemarks.first.administrativeArea ?? ''}".trim();
          if (locationName == ",") locationName = "Location Set";
        }
      } catch (_) {}

      if (widget.jobId != null) {
         // Update existing job
         await FirebaseFirestore.instance.collection('jobs').doc(widget.jobId).update({
            "title": _titleCtrl.text,
            "description": _descCtrl.text,
            "budget": double.parse(_budgetCtrl.text),
            "category": _selectedCategory,
            "location": locationName,
            "latitude": _selectedLocation.latitude,
            "longitude": _selectedLocation.longitude,
         });
         if (!mounted) return;
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Job Updated Successfully!'), backgroundColor: Colors.green));
      } else {
         // Post new job
         await ApiService.postJob({
           "employerId": user.uid,
           "title": _titleCtrl.text,
           "description": _descCtrl.text,
           "budget": double.parse(_budgetCtrl.text),
           "category": _selectedCategory,
           "location": locationName,
           "latitude": _selectedLocation.latitude,
           "longitude": _selectedLocation.longitude,
         });
         if (!mounted) return;
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Job Sent! AI is categorizing and pinging nearby workers.'), backgroundColor: Colors.green));
      }

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PRO-LINK', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: const [
          Icon(Icons.swap_horiz, color: Color(0xFF112A46)),
          SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('NEW LISTING', style: TextStyle(color: Color(0xFFB85C19), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  const Text('Post a Job', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF112A46))),
                  const SizedBox(height: 8),
                  Text('Describe what you need. Our AI will automatically categorize it for the right tradespeople.', style: TextStyle(color: (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white), fontSize: 15)),
                  
                  const SizedBox(height: 24),
                  const Text('Job Title', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF112A46))),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleCtrl,
                    decoration: InputDecoration(
                      hintText: "e.g. Fix Leaking Bathroom Pipe",
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF112A46))),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "Provide details about the issue...",
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Text('Trade Category', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF112A46))),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(fillColor: Colors.white, filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                    items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategory = val);
                    },
                  ),

                  const SizedBox(height: 16),
                  const Text('Budget', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF112A46))),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _budgetCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.money, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70)),
                      suffixIcon: const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Text('PKR', style: TextStyle(color: Color(0xFFB85C19), fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
            
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text('Job Location (Drag map to set exact pin)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF112A46))),
            ),
            const SizedBox(height: 8),

            // Live Interactive OpenStreetMap
            Container(
              height: 250,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.12), width: 2),
                boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.12), blurRadius: 10)],
              ),
              clipBehavior: Clip.hardEdge,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _selectedLocation,
                      initialZoom: 14.0,
                      onPositionChanged: (position, hasGesture) {
                        if (hasGesture && position.center != null) {
                          _selectedLocation = position.center!;
                        }
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.app',
                      ),
                    ],
                  ),
                  // Center Marker Pin overlay
                  const Padding(
                    padding: EdgeInsets.only(bottom: 40.0), // Offset slightly up to point at center
                    child: Icon(Icons.location_on, size: 50, color: Color(0xFFB85C19)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitJob,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB85C19),
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Post Job Securely', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        SizedBox(width: 8),
                        Icon(Icons.send, size: 20, color: Colors.white),
                      ],
                    ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
