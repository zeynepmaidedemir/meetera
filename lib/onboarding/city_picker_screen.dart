import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../state/app_state.dart';
import '../services/city_service.dart';

class CityPickerScreen extends StatefulWidget {
  const CityPickerScreen({super.key});

  @override
  State<CityPickerScreen> createState() => _CityPickerScreenState();
}

class _CityPickerScreenState extends State<CityPickerScreen> {
  final CityService _cityService = CityService();

  List<dynamic> countries = [];
  List<dynamic> filteredCountries = [];
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    loadCountries();
  }

  Future<void> loadCountries() async {
    final data = await _cityService.fetchCountries();
    setState(() {
      countries = data;
      filteredCountries = data;
    });
  }

  void filter(String query) {
    final lowerQuery = query.toLowerCase();

    setState(() {
      searchQuery = query;

      if (query.isEmpty) {
        filteredCountries = countries;
      } else {
        filteredCountries = countries
            .map((country) {
              final countryName = country['country'];
              final cities = List<String>.from(country['cities']);

              final matchedCities = cities
                  .where((city) => city.toLowerCase().contains(lowerQuery))
                  .toList();

              if (countryName.toLowerCase().contains(lowerQuery)) {
                // Ülke eşleşti → tüm şehirleri göster
                return country;
              }

              if (matchedCities.isNotEmpty) {
                // Sadece eşleşen şehirleri göster
                return {'country': countryName, 'cities': matchedCities};
              }

              return null;
            })
            .where((e) => e != null)
            .toList();
      }
    });
  }

  Future<void> selectCity({
    required String city,
    required String country,
  }) async {
    final countryCode = country.substring(0, 2).toUpperCase();
    final cityId =
        "${city.toLowerCase().replaceAll(' ', '_')}_${countryCode.toLowerCase()}";

    final appState = context.read<AppState>();

    appState.setCity(
      city: city,
      country: country,
      countryCode: countryCode,
      cityId: cityId,
    );

    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'city': city,
        'country': country,
        'countryCode': countryCode,
        'cityId': cityId,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (countries.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Select your city")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: "Search country or city...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: filter,
            ),
          ),
          Expanded(
            child: ListView(
              children: filteredCountries.map((country) {
                final countryName = country['country'];
                final cities = country['cities'];

                return ExpansionTile(
                  title: Text(countryName),
                  children: cities.map<Widget>((city) {
                    return ListTile(
                      title: Text(city),
                      onTap: () => selectCity(city: city, country: countryName),
                    );
                  }).toList(),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
