import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = "http://127.0.0.1:8000";

  Future<String?> sendPredictionRequest(List<double> features) async {
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
        return data["prediction"];
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
