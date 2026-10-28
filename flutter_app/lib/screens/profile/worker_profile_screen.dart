import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/api_service.dart';

class WorkerProfileScreen extends StatefulWidget {
  const WorkerProfileScreen({super.key});

  @override
  State<WorkerProfileScreen> createState() => _WorkerProfileScreenState();
}

class _WorkerProfileScreenState extends State<WorkerProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _skillController = TextEditingController();
  
  List<String> _skills = [];
  List<String> _portfolioUrls = [];
  String? _photoUrl;
  bool? _isVerified; // null = unsubmitted, false = pending, true = verified
  bool _isLoading = true;
  bool _isSaving = false;

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
        _nameController.text = data['fullName'] ?? '';
        _titleController.text = data['professionalTitle'] ?? '';
        _phoneController.text = data['phoneNumber'] ?? '';
        _rateController.text = (data['hourlyRate'] ?? '').toString();
        _bioController.text = data['bio'] ?? '';
        _photoUrl = data['photoUrl'];
        _isVerified = data['isVerified'];
        if (data['skillsList'] != null) {
          _skills = List<String>.from(data['skillsList']);
        }
        if (data['portfolioUrls'] != null) {
          _portfolioUrls = List<String>.from(data['portfolioUrls']);
        }
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'fullName': _nameController.text,
        'professionalTitle': _titleController.text,
        'phoneNumber': _phoneController.text,
        'hourlyRate': double.tryParse(_rateController.text) ?? 0.0,
        'bio': _bioController.text,
        'skillsList': _skills,
        'portfolioUrls': _portfolioUrls,
        if (_photoUrl != null) 'photoUrl': _photoUrl,
      }, SetOptions(merge: true));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile Saved!'), backgroundColor: Colors.green));
      }
    }
    setState(() => _isSaving = false);
  }

  void _addSkill() {
    if (_skillController.text.trim().isNotEmpty) {
      setState(() {
        _skills.add(_skillController.text.trim());
        _skillController.clear();
      });
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

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
       setState(() => _isSaving = true);
       try {
         final bytes = await pickedFile.readAsBytes();
         final url = await _uploadToLocalBackend(bytes, 'portfolio_${DateTime.now().millisecondsSinceEpoch}.jpg');
         
         if (url != null) {
           setState(() {
              _portfolioUrls.add(url);
           });
           await _saveProfile();
         } else {
           throw Exception("Backend upload failed");
         }
       } catch (e) {
         if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
         setState(() => _isSaving = false);
       }
    }
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
         
         if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verification document submitted! Pending Admin approval.'), backgroundColor: Colors.orange));
       } catch (e) {
         if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
       } finally {
         setState(() => _isSaving = false);
       }
    }
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Professional Profile'),
        actions: [
          _isSaving 
            ? const Padding(padding: EdgeInsets.all(16.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
            : IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: _saveProfile)
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Image Upload
          Center(
            child: GestureDetector(
              onTap: _pickAndUploadProfileImage,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: _photoUrl != null ? NetworkImage(_photoUrl!) : null,
                    child: _photoUrl == null ? const Icon(Icons.person, size: 50, color: Colors.grey) : null,
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: Color(0xFF112A46), shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                    ),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          _buildTextField('Full Name', _nameController, Icons.person),
          _buildTextField('Professional Title (e.g. Master Electrician)', _titleController, Icons.work),
          _buildTextField('Phone Number', _phoneController, Icons.phone, keyboardType: TextInputType.phone),
          _buildTextField('Hourly Rate (₹)', _rateController, Icons.attach_money, keyboardType: TextInputType.number),
          _buildTextField('Bio / Professional Summary', _bioController, Icons.description, maxLines: 4),
          
          const SizedBox(height: 16),
          const Text('Skills', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _skillController,
                  decoration: InputDecoration(
                    hintText: 'Add a skill (e.g. Plumbing)',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onSubmitted: (_) => _addSkill(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _addSkill,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB85C19), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: const Text('Add'),
              )
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _skills.map((s) => Chip(
              label: Text(s, style: const TextStyle(color: Colors.white, fontSize: 12)),
              backgroundColor: const Color(0xFF112A46),
              deleteIcon: const Icon(Icons.close, color: Colors.white, size: 16),
              onDeleted: () => setState(() => _skills.remove(s)),
            )).toList(),
          ),

          const SizedBox(height: 24),
          const Text('Portfolio & Certifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ..._portfolioUrls.map((url) => Container(
                   margin: const EdgeInsets.only(right: 12),
                   width: 100, height: 100,
                   decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
                   ),
                )),
                GestureDetector(
                  onTap: _pickAndUploadImage,
                  child: _buildPortfolioUploadBox(),
                )
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          const Text('Identity Verification (KYC)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isVerified == true ? Colors.green.withOpacity(0.1) : (_isVerified == false ? Colors.orange.withOpacity(0.1) : Colors.grey[50]),
              border: Border.all(color: _isVerified == true ? Colors.green : (_isVerified == false ? Colors.orange : Colors.black12)),
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
                      _isVerified == true ? 'Verified Account' : (_isVerified == false ? 'Verification Pending' : 'Action Required'),
                      style: TextStyle(fontWeight: FontWeight.bold, color: _isVerified == true ? Colors.green : (_isVerified == false ? Colors.orange : (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white))),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _isVerified == true 
                    ? 'Your identity has been verified by an administrator.' 
                    : (_isVerified == false ? 'Your documents are currently under review by our Trust & Safety team.' : 'Please upload your ID or Trade License to receive the Verified Badge and build trust with Employers.'),
                  style: TextStyle(fontSize: 14, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70)),
                ),
                if (_isVerified != true && _isVerified != false) ...[
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _uploadKycDocument,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Upload Document'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF112A46)),
                  )
                ]
              ],
            ),
          ),

          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _isSaving ? null : _saveProfile,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: const Color(0xFF112A46),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
            ),
            child: Text('Save Profile', style: Theme.of(context).textTheme.titleSmall),
          )
        ],
      ),
    );
  }

  Widget _buildPortfolioUploadBox() {
    return Container(
      width: 100, height: 100,
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.12), style: BorderStyle.solid)),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate, color: Colors.grey, size: 32),
          SizedBox(height: 4),
          Text('Upload', style: TextStyle(color: Colors.grey, fontSize: 12))
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {int maxLines = 1, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: maxLines == 1 ? Icon(icon, color: Colors.grey) : null,
          alignLabelWithHint: true,
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.12))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.12))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF112A46), width: 2)),
        ),
      ),
    );
  }
}
