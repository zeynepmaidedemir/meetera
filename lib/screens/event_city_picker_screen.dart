import 'package:flutter/material.dart';
import '../services/city_service.dart';

class EventCityPickerScreen extends StatefulWidget {
  const EventCityPickerScreen({super.key});

  @override
  State<EventCityPickerScreen> createState() => _EventCityPickerScreenState();
}

class _EventCityPickerScreenState extends State<EventCityPickerScreen> {
  final CityService _cityService = CityService();
  List<dynamic> countries = [];
  List<dynamic> filteredCountries = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  Future<void> _loadCountries() async {
    try {
      final data = await _cityService.fetchCountries();
      setState(() {
        countries = data;
        filteredCountries = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _filter(String query) {
    final lowerQuery = query.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredCountries = countries;
      } else {
        filteredCountries = countries.map((country) {
          final countryName = country['country'];
          final cities = List<String>.from(country['cities']);
          final matchedCities = cities.where((c) => c.toLowerCase().contains(lowerQuery)).toList();
          
          if (countryName.toLowerCase().contains(lowerQuery)) return country;
          if (matchedCities.isNotEmpty) return {'country': countryName, 'cities': matchedCities};
          return null;
        }).where((e) => e != null).toList();
      }
    });
  }

  void _selectCity(String city, String country) {
    final countryCode = country.substring(0, 2).toUpperCase();
    final cityId = "${city.toLowerCase().replaceAll(' ', '_')}_${countryCode.toLowerCase()}";
    
    Navigator.pop(context, {
      'cityId': cityId,
      'cityName': city,
      'countryName': country,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Select City"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: isLoading 
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Search country or city...",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                    onChanged: _filter,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredCountries.length,
                    itemBuilder: (context, index) {
                      final country = filteredCountries[index];
                      final countryName = country['country'];
                      final cities = country['cities'] as List;

                      return ExpansionTile(
                        title: Text(countryName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        children: cities.map<Widget>((city) {
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 32),
                            title: Text(city),
                            onTap: () => _selectCity(city, countryName),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
