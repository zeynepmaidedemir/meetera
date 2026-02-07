import 'dart:math';
import '../models/explore_place.dart';

class RouteStep {
  final ExplorePlace place;
  final double distanceKm;

  RouteStep({required this.place, required this.distanceKm});
}

class RoutePreview {
  final List<RouteStep> steps;
  final double totalDistanceKm;
  final int estimatedMinutes;

  RoutePreview({
    required this.steps,
    required this.totalDistanceKm,
    required this.estimatedMinutes,
  });
}

class RouteUtils {
  /// Walking default: ~5 km/h
  static const double walkingSpeedKmPerHour = 5;

  static RoutePreview buildWalkingRoute(List<ExplorePlace> places) {
    if (places.length < 2) {
      return RoutePreview(steps: [], totalDistanceKm: 0, estimatedMinutes: 0);
    }

    final remaining = [...places];
    final ordered = <ExplorePlace>[];

    // start from first
    ordered.add(remaining.removeAt(0));

    while (remaining.isNotEmpty) {
      final last = ordered.last;

      remaining.sort((a, b) {
        final da = _distanceKm(last, a);
        final db = _distanceKm(last, b);
        return da.compareTo(db);
      });

      ordered.add(remaining.removeAt(0));
    }

    double total = 0;
    final steps = <RouteStep>[];

    for (var i = 0; i < ordered.length; i++) {
      double d = 0;
      if (i > 0) {
        d = _distanceKm(ordered[i - 1], ordered[i]);
        total += d;
      }
      steps.add(RouteStep(place: ordered[i], distanceKm: d));
    }

    final hours = total / walkingSpeedKmPerHour;
    final minutes = (hours * 60).round();

    return RoutePreview(
      steps: steps,
      totalDistanceKm: total,
      estimatedMinutes: minutes,
    );
  }

  static double _distanceKm(ExplorePlace a, ExplorePlace b) {
    const r = 6371;
    final dLat = _deg2rad(b.position.latitude - a.position.latitude);
    final dLon = _deg2rad(b.position.longitude - a.position.longitude);

    final lat1 = _deg2rad(a.position.latitude);
    final lat2 = _deg2rad(b.position.latitude);

    final h =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);

    return 2 * r * atan2(sqrt(h), sqrt(1 - h));
  }

  static double _deg2rad(double d) => d * pi / 180;
}
