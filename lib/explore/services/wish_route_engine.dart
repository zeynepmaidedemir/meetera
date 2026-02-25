import '../models/explore_place.dart';
import 'geo.dart';

class WishRouteEngine {
  static List<ExplorePlace> buildSmartRoute(List<ExplorePlace> wishes) {
    if (wishes.length <= 2) return List<ExplorePlace>.from(wishes);

    final remaining = List<ExplorePlace>.from(wishes);
    final route = <ExplorePlace>[];

    ExplorePlace current = remaining.removeAt(0);
    route.add(current);

    while (remaining.isNotEmpty) {
      remaining.sort((a, b) {
        final da = Geo.distanceMeters(
          lat1: current.position.latitude,
          lng1: current.position.longitude,
          lat2: a.position.latitude,
          lng2: a.position.longitude,
        );
        final db = Geo.distanceMeters(
          lat1: current.position.latitude,
          lng1: current.position.longitude,
          lat2: b.position.latitude,
          lng2: b.position.longitude,
        );
        return da.compareTo(db);
      });

      current = remaining.removeAt(0);
      route.add(current);
    }

    return route;
  }
}
