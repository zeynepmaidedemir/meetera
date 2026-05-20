import 'dart:convert';
import 'package:http/http.dart' as http;

class CityService {
  static const bool enableTestExceptions = false;

  Future<List<dynamic>> fetchCountries() async {
    if (enableTestExceptions) {
      throw Exception("Test: fetchCountries failed!");
    }

    final response = await http.get(
      Uri.parse('https://countriesnow.space/api/v0.1/countries'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data'];
    } else {
      throw Exception('Failed to load countries');
    }
  }
}
