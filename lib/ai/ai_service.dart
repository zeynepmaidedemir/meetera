import 'dart:convert';
import 'package:http/http.dart' as http;

import 'ai_context.dart';

class AiService {
  static const _baseUrl = 'http://10.0.2.2:3000/chat';

  static Future<Map<String, dynamic>> askAi({
    required String message,
    required AiContext context,
  }) async {
    final body = {
      'message': message,
      'city': context.city, // 🔥 ŞEHİR BURADAN GİDİYOR
    };

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
