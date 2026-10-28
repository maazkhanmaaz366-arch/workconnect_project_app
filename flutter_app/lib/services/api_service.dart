import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiService {
  // Use 10.0.2.2 for Android emulator, 127.0.0.1 for Web/iOS emulator
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    } else {
      return 'http://127.0.0.1:8000';
    }
  }

  static Future<Map<String, dynamic>> registerUser(String idToken, String role) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id_token': idToken,
        'role': role,
      }),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to register on Backend: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> postJob(Map<String, dynamic> jobData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/jobs/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(jobData),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to post job: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> overrideGoogleLogin(String idToken) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/google-override'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id_token': idToken}),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to link Google account: ${response.body}');
    }
  }
}
