import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import '../models/map_place.dart';

class MapLauncherUtil {
  static Future<void> openPlaces(List<MapPlace> places) async {
    if (places.isEmpty) return;

    final first = places.first;

    final waypoints = places.map((p) => '${p.lat},${p.lng}').join('|');

    final googleUrl =
        'https://www.google.com/maps/dir/?api=1'
        '&destination=${first.lat},${first.lng}'
        '&waypoints=$waypoints';

    final appleUrl = 'http://maps.apple.com/?q=${first.lat},${first.lng}';

    final uri = Uri.parse(Platform.isIOS ? appleUrl : googleUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
