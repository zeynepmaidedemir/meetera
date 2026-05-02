import 'dart:convert';
import 'package:http/http.dart' as http;

import 'dart:io' show Platform;

class AiService {
  static Future<Map<String, dynamic>> askAi({
    required List<Map<String, String>> messages,
    String? city,
  }) async {
    final String baseUrl = Platform.isAndroid ? 'http://10.0.2.2:3000' : 'http://localhost:3000';
    final res = await http.post(
      Uri.parse('$baseUrl/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'messages': messages, 'city': city}),
    );

    return jsonDecode(res.body);
  }
}
