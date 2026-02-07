import 'dart:convert';
import 'package:http/http.dart' as http;

class AiService {
  static Future<Map<String, dynamic>> askAi({
    required List<Map<String, String>> messages,
    String? city,
    double? lat,
    double? lng,
  }) async {
    final res = await http.post(
      Uri.parse('http://localhost:3000/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'messages': messages,
        'city': city,
        'lat': lat,
        'lng': lng,
      }),
    );

    return jsonDecode(res.body);
  }
}
