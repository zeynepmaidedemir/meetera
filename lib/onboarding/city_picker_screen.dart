import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class CityPickerScreen extends StatelessWidget {
  const CityPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();

    final cities = const [
      {'city': 'Warsaw', 'country': 'Poland'},
      {'city': 'Krakow', 'country': 'Poland'},
      {'city': 'Lublin', 'country': 'Poland'},
      {'city': 'Wroclaw', 'country': 'Poland'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Select your city')),
      body: ListView.builder(
        itemCount: cities.length,
        itemBuilder: (_, i) {
          final c = cities[i];

          return ListTile(
            title: Text(c['city']!),
            subtitle: Text(c['country']!),
            onTap: () {
              appState.setCity(city: c['city']!, country: c['country']!);
              // ❗ Navigator YOK
              // OnboardingGate otomatik geçirecek
            },
          );
        },
      ),
    );
  }
}
