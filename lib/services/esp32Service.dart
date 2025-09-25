import 'package:http/http.dart' as http;

class ESP32Service {
  final String baseUrl = "http://192.168.1.45"; // ESP32 ka IP

  Future<void> turnLedOn() async {
    final response = await http.get(Uri.parse("$baseUrl/led_on"));
    print("Response: ${response.body}");
  }

  Future<void> turnLedOff() async {
    final response = await http.get(Uri.parse("$baseUrl/led_off"));
    print("Response: ${response.body}");
  }
}
