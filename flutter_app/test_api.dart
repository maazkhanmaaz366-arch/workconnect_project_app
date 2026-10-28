import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print("Starting API Test (Simulating Flutter Request)...");
  
  final url = Uri.parse('http://127.0.0.1:8000/ai/match');
  
  final payload = {
    "job_description": "Looking for an expert carpenter to build custom walnut cabinets.",
    "workers": [
      {
        "uid": "worker123",
        "skillsList": ["Carpentry", "Cabinetry", "Woodworking"],
        "averageRating": 4.8
      },
      {
        "uid": "worker456",
        "skillsList": ["Plumbing", "Pipe Fitting"],
        "averageRating": 4.5
      }
    ]
  };
  
  print("Payload Prepared:");
  print(jsonEncode(payload));
  print("\nSending POST request to \$url...");
  
  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    ).timeout(const Duration(seconds: 45));
    
    print("\n--- Response Received ---");
    print("Status Code: \${response.statusCode}");
    print("Body: \${response.body}");
    
    if (response.statusCode == 200) {
       print("\nSUCCESS! The backend processed the Flutter request correctly.");
    } else {
       print("\nFAILED! The backend returned an error.");
    }
  } catch (e) {
    print("\nEXCEPTION CAUGHT!");
    print(e.toString());
  }
}
