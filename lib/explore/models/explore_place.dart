import 'package:google_maps_flutter/google_maps_flutter.dart';

enum ExploreStatus { wish, visited, favorite }

class ExplorePlace {
  final String id;
  final LatLng position;
  String name;
  ExploreStatus status;

  ExplorePlace({
    required this.id,
    required this.position,
    required this.name,
    required this.status,
  });
}
