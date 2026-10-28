import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/api_service.dart';


class EmployerProfileScreen extends StatefulWidget {
  const EmployerProfileScreen({super.key});

  @override
  State<EmployerProfileScreen> createState() => _EmployerProfileScreenState();
}

class _EmployerProfileScreenState extends State<EmployerProfileScreen> {
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  
  String _selectedIndustry = 'Construction & Real Estate';
  String _selectedSize = '1-10 Employees';
  bool _isLoading = true;
  bool _isSaving = false;
  String? _photoUrl;
  bool? _isVerified;

  final List<String> _industries = ['Construction & Real Estate', 'IT & Tech', 'Facility Maintenance', 'Logistics', 'Healthcare', 'Other'];
  final List<String> _sizes = ['1-10 Employees', '11-50 Employees', '51-200 Employees', '200+ Employees'];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        _companyNameController.text = data['companyName'] ?? '';
        _phoneController.text = data['phoneNumber'] ?? '';
        _websiteController.text = data['website'] ?? '';
        _locationController.text = data['location'] ?? '';
        _bioController.text = data['bio'] ?? '';
        _photoUrl = data['photoUrl'];
        _isVerified = data['isVerified'];
        if (data['industry'] != null && _industries.contains(data['industry'])) _selectedIndustry = data['industry'];
        if (data['companySize'] != null && _sizes.contains(data['companySize'])) _selectedSize = data['companySize'];
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'companyName': _companyNameController.text,
        'phoneNumber': _phoneController.text,
        'website': _websiteController.text,
        'location': _locationController.text,
        'bio': _bioController.text,
        'industry': _selectedIndustry,
        'companySize': _selectedSize,
        if (_photoUrl != null) 'photoUrl': _photoUrl,
      }, SetOptions(merge: true));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Company Profile Saved!'), backgroundColor: Colors.green));
      }
    }
    setState(() => _isSaving = false);
  }

  Future<void> _pickAndUploadProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
       setState(() => _isSaving = true);
       try {
         final bytes = await pickedFile.readAsBytes();
         final url = await _uploadToLocalBackend(bytes, 'profile_${FirebaseAuth.instance.currentUser!.uid}.jpg');
         
         if (url == null) throw Exception("Backend upload failed");
         
         setState(() {
            _photoUrl = url;
         });
         await _saveProfile();
       } catch (e) {
         if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile Upload failed: $e')));
         setState(() => _isSaving = false);
       }
    }
  }

  Future<String?> _uploadToLocalBackend(List<int> bytes, String filename) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('${ApiService.baseUrl}/upload'));
      request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
      var response = await request.send();
      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final json = jsonDecode(respStr);
        return json['url'];
      }
    } catch (e) {
      print("Upload error: $e");
    }
    return null;
  }

  Future<void> _uploadKycDocument() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
       setState(() => _isSaving = true);
       try {
         final bytes = await pickedFile.readAsBytes();
         final url = await _uploadToLocalBackend(bytes, 'kyc_${FirebaseAuth.instance.currentUser!.uid}.jpg');
         
         if (url == null) throw Exception("Backend upload failed");
         
         // Update Firestore with the doc and set isVerified to false (pending)
         await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).set({
           'verificationDocUrl': url,
           'isVerified': false,
         }, SetOptions(merge: true));
         
         setState(() {
            _isVerified = false;
         });
         
         if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tax/Business ID submitted! Pending Admin approval.'), backgroundColor: Colors.orange));
       } catch (e) {
         if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
       } finally {
         setState(() => _isSaving = false);
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return Scaffold( body: Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)));

    return Scaffold(
      
      appBar: AppBar(
        
        elevation: 0,
        title: Text('Company Profile', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
        actions: [
          _isSaving 
            ? Padding(padding: EdgeInsets.all(16.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.primary)))
            : IconButton(icon: const Icon(Icons.check_circle, color: Colors.green, size: 28), onPressed: _saveProfile)
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: GestureDetector(
              onTap: _pickAndUploadProfileImage,
              child: Stack(
                children: [
                  Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Theme.of(context).colorScheme.surfaceContainerHighest, width: 2),
                      image: _photoUrl != null ? DecorationImage(image: NetworkImage(_photoUrl!), fit: BoxFit.cover) : null,
                    ),
                    child: _photoUrl == null ? Icon(Icons.business, size: 50, color: Theme.of(context).colorScheme.primary) : null,
                  ),
                  Positioned(
                    bottom: -4, right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondary, shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                    ),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          
          _buildTextField('Company Name', _companyNameController, Icons.business_center),
          _buildTextField('Phone Number', _phoneController, Icons.phone, keyboardType: TextInputType.phone),
          _buildTextField('Website URL', _websiteController, Icons.language, keyboardType: TextInputType.url),
          _buildTextField('Office Location', _locationController, Icons.location_on),
          
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedIndustry,
            decoration: _inputDecoration('Industry', Icons.category),
            items: _industries.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
            onChanged: (val) => setState(() => _selectedIndustry = val!),
            icon: Icon(Icons.keyboard_arrow_down, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: 24),
          
          DropdownButtonFormField<String>(
            value: _selectedSize,
            decoration: _inputDecoration('Company Size', Icons.groups),
            items: _sizes.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
            onChanged: (val) => setState(() => _selectedSize = val!),
            icon: Icon(Icons.keyboard_arrow_down, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: 24),

          _buildTextField('About Company', _bioController, Icons.description, maxLines: 5),

          const SizedBox(height: 24),
          Text('Identity Verification (KYC)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.primary)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isVerified == true ? Colors.green.withOpacity(0.1) : (_isVerified == false ? Colors.orange.withOpacity(0.1) : Colors.white),
              border: Border.all(color: _isVerified == true ? Colors.green : (_isVerified == false ? Colors.orange : Theme.of(context).colorScheme.surfaceContainerHighest)),
              borderRadius: BorderRadius.circular(12)
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _isVerified == true ? Icons.verified : (_isVerified == false ? Icons.access_time_filled : Icons.warning_amber_rounded),
                      color: _isVerified == true ? Colors.green : (_isVerified == false ? Colors.orange : Colors.grey),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isVerified == true ? 'Verified Business' : (_isVerified == false ? 'Verification Pending' : 'Action Required'),
                      style: TextStyle(fontWeight: FontWeight.bold, color: _isVerified == true ? Colors.green : (_isVerified == false ? Colors.orange : (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white))),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _isVerified == true 
                    ? 'Your business has been verified by an administrator.' 
                    : (_isVerified == false ? 'Your Business Tax ID is under review by our Trust & Safety team.' : 'Please upload your Business Tax ID to receive the Verified Badge and build trust with workers.'),
                  style: TextStyle(fontSize: 14, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70)),
                ),
                if (_isVerified != true && _isVerified != false) ...[
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _uploadKycDocument,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Upload Tax ID'),
                    style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
                  )
                ]
              ],
            ),
          ),
          
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: _isSaving ? null : _saveProfile,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 20),
              backgroundColor: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
            ),
            child: const Text('Save Profile Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          )
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.surfaceContainerHighest)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.surfaceContainerHighest)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {int maxLines = 1, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: maxLines == 1 ? Icon(icon, color: Theme.of(context).colorScheme.primary) : null,
          alignLabelWithHint: true,
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.surfaceContainerHighest)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.surfaceContainerHighest)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)),
        ),
      ),
    );
  }
}
