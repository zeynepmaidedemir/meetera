class MapPlace {
  final String name;
  final double lat;
  final double lng;
  final int distance;

  MapPlace({
    required this.name,
    required this.lat,
    required this.lng,
    required this.distance,
  });

  factory MapPlace.fromJson(Map<String, dynamic> json) {
    return MapPlace(
      name: json['name'],
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      distance: json['distance'],
    );
  }
}
