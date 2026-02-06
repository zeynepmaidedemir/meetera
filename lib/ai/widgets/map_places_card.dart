import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/map_place.dart';

class MapPlacesCard extends StatelessWidget {
  final List<MapPlace> places;

  const MapPlacesCard({super.key, required this.places});

  @override
  Widget build(BuildContext context) {
    final p = places.first;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "📍 Location",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.map),
              label: const Text("Open in Maps"),
              onPressed: () => _openMaps(p.lat, p.lng),
            ),
          ],
        ),
      ),
    );
  }

  void _openMaps(double lat, double lng) {
    final uri = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=$lat,$lng",
    );
    launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
