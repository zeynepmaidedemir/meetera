import 'dart:convert';
import 'package:http/http.dart' as http;

class AiService {
  static Future<Map<String, dynamic>> askAi({
    required List<Map<String, String>> messages,
    String? city,
  }) async {
    final res = await http.post(
      Uri.parse('http://10.0.2.2:3000/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'messages': messages, 'city': city}),
    );

    return jsonDecode(res.body);
  }
}
