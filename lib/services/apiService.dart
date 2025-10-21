import 'dart:convert';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;

final flutterTts = FlutterTts();

Future<void> speakText(String text) async {
  await flutterTts.setLanguage("ur-PK");
  await flutterTts.setPitch(1.0);
  await flutterTts.speak(text);
}
class ApiService {
  final String baseUrl = "https://gesturetospeechappbackend.onrender.com";

  Future<String?> sendPredictionRequest( features) async {
    try {
      final url = Uri.parse("$baseUrl/predict");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"features": features}),
      );

      if (response.statusCode == 200) {
        print("Response: ${response.body}");
        final data = jsonDecode(response.body);
        print("Gesture: ${data["gesture"]}");
        await speakText(data["gesture"]);
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