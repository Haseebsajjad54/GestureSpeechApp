import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = "http://10.0.2.2:8000"; // Use 10.0.2.2 for Android emulator

  Future<String?> sendPredictionRequest( features) async {
    try {
      final url = Uri.parse("$baseUrl/predict");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"features": features}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // assuming your backend response = {"prediction": "gesture_name"}
        return data["gesture"];
      } else {
        print("Error: ${response.statusCode}, ${response.body}");
        return null;
      }
    } catch (e) {
      print("Exception: $e");
      return null;
    }
  }
}