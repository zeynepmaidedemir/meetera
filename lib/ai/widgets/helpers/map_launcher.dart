import 'package:url_launcher/url_launcher.dart';

class MapLauncher {
  static Future<void> openPlaces(List places) async {
    if (places.isEmpty) return;

    // Google Maps query string
    final query = places
        .map(
          (p) => '${p['lat']},${p['lng']}(${Uri.encodeComponent(p['name'])})',
        )
        .join('|');

    final url =
        'https://www.google.com/maps/dir/?api=1&destination=${places[0]['lat']},${places[0]['lng']}&waypoints=$query';

    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
