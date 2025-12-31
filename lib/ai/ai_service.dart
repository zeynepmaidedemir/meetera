import 'dart:convert';
import 'package:http/http.dart' as http;

class AiService {
  static const _baseUrl = 'http://10.0.2.2:3000/chat';

  static Future<Map<String, dynamic>> askAi({
    required List<Map<String, String>> messages,
    required String city,
  }) async {
    final body = {'messages': messages, 'city': city};

    print('🟢 AI REQUEST BODY: $body');

    final res = await http.post(
      Uri.parse(_baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (res.statusCode != 200) {
      throw Exception('AI connection failed');
    }

    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}
