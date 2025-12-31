import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MapButton extends StatelessWidget {
  const MapButton({super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      icon: const Icon(Icons.map),
      label: const Text('Open in Maps'),
      onPressed: () async {
        final uri = Uri.parse('https://www.google.com/maps/search/?api=1');
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      },
    );
  }
}
