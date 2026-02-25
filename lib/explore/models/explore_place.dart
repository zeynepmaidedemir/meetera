import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'place_status.dart';

class ExplorePlace {
  final String id;
  LatLng position;
  String name;
  ExploreStatus status;

  final DateTime createdAt;
  DateTime? visitedAt;

  ExplorePlace({
    required this.id,
    required this.position,
    required this.name,
    required this.status,
    DateTime? createdAt,
    this.visitedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'lat': position.latitude,
        'lng': position.longitude,
        'name': name,
        'status': status.key,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'visitedAt': visitedAt?.millisecondsSinceEpoch,
      };

  factory ExplorePlace.fromJson(String id, Map<String, dynamic> json) {
    return ExplorePlace(
      id: id,
      position: LatLng(
        (json['lat'] as num).toDouble(),
        (json['lng'] as num).toDouble(),
      ),
      name: (json['name'] as String?) ?? 'Pinned place',
      status: ExploreStatusExt.fromKey((json['status'] as String?) ?? 'wish'),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (json['createdAt'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
      ),
      visitedAt: json['visitedAt'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(json['visitedAt'] as int),
    );
  }
}
