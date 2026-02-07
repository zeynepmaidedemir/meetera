import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'place_status.dart';

class ExplorePlace {
  final String id;
  LatLng position;
  String name;
  ExploreStatus status;

  /// persist + streak için
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
    'id': id,
    'lat': position.latitude,
    'lng': position.longitude,
    'name': name,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'visitedAt': visitedAt?.toIso8601String(),
  };

  static ExplorePlace fromJson(Map<String, dynamic> json) {
    return ExplorePlace(
      id: json['id'] as String,
      position: LatLng(
        (json['lat'] as num).toDouble(),
        (json['lng'] as num).toDouble(),
      ),
      name: (json['name'] as String?) ?? 'Pinned place',
      status: ExploreStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String?),
        orElse: () => ExploreStatus.wish,
      ),
      createdAt: _dt(json['createdAt']) ?? DateTime.now(),
      visitedAt: _dt(json['visitedAt']),
    );
  }

  static DateTime? _dt(dynamic v) {
    if (v == null) return null;
    try {
      return DateTime.parse(v.toString());
    } catch (_) {
      return null;
    }
  }
}
