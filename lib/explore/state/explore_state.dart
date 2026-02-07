import 'dart:convert';
import 'dart:math' as _m;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/explore_place.dart';
import '../models/place_status.dart';

class ExploreBadge {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool earned;

  ExploreBadge({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.earned,
  });
}

class ExploreState extends ChangeNotifier {
  static const _kKey = 'explore_places_v2';

  final List<ExplorePlace> _places = [];
  bool _loaded = false;

  List<ExplorePlace> get all => List.unmodifiable(_places);

  List<ExplorePlace> byStatus(ExploreStatus status) =>
      _places.where((p) => p.status == status).toList();

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kKey);
      if (raw == null || raw.trim().isEmpty) {
        notifyListeners();
        return;
      }

      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      _places
        ..clear()
        ..addAll(list.map(ExplorePlace.fromJson));

      notifyListeners();
    } catch (_) {
      // sessiz geç
      notifyListeners();
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(_places.map((e) => e.toJson()).toList());
      await prefs.setString(_kKey, raw);
    } catch (_) {}
  }

  void add(ExplorePlace place) {
    _places.add(place);
    _persist();
    notifyListeners();
  }

  void update(ExplorePlace place) {
    final idx = _places.indexWhere((p) => p.id == place.id);
    if (idx == -1) return;

    // visitedAt set kuralı
    final prev = _places[idx];
    if (prev.status != ExploreStatus.visited &&
        place.status == ExploreStatus.visited) {
      place.visitedAt ??= DateTime.now();
    }

    _places[idx] = place;
    _persist();
    notifyListeners();
  }

  void remove(String id) {
    _places.removeWhere((p) => p.id == id);
    _persist();
    notifyListeners();
  }

  // -----------------------
  // 🔥 Streak (visited days)
  // -----------------------
  int get currentStreak {
    final visited =
        byStatus(ExploreStatus.visited)
            .map((p) => p.visitedAt)
            .whereType<DateTime>()
            .map((d) => DateTime(d.year, d.month, d.day))
            .toSet()
            .toList()
          ..sort();

    if (visited.isEmpty) return 0;

    final today = DateTime.now();
    var day = DateTime(today.year, today.month, today.day);

    // streak today veya en son gün üzerinden
    final set = visited.toSet();
    int streak = 0;

    // eğer bugün yoksa ama dün varsa streak yine yürüsün (soft)
    if (!set.contains(day)) {
      final yesterday = day.subtract(const Duration(days: 1));
      if (set.contains(yesterday)) {
        day = yesterday;
      } else {
        return 0;
      }
    }

    while (set.contains(day)) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  List<ExploreBadge> get badges {
    final visited = byStatus(ExploreStatus.visited).length;
    final fav = byStatus(ExploreStatus.favorite).length;
    final wish = byStatus(ExploreStatus.wish).length;
    final streak = currentStreak;

    return [
      ExploreBadge(
        title: 'First Pin',
        subtitle: 'Pinned your first place 📍',
        icon: Icons.push_pin_outlined,
        earned: _places.isNotEmpty,
      ),
      ExploreBadge(
        title: 'Explorer',
        subtitle: 'Visited 3 places ✅',
        icon: Icons.explore_outlined,
        earned: visited >= 3,
      ),
      ExploreBadge(
        title: 'Collector',
        subtitle: 'Saved 5 wishes 🧭',
        icon: Icons.bookmark_border,
        earned: wish >= 5,
      ),
      ExploreBadge(
        title: 'Taste',
        subtitle: 'Marked 3 favorites 💗',
        icon: Icons.favorite_border,
        earned: fav >= 3,
      ),
      ExploreBadge(
        title: 'Streak',
        subtitle: '2-day explore streak 🔥',
        icon: Icons.local_fire_department_outlined,
        earned: streak >= 2,
      ),
    ];
  }

  // -----------------------
  // 🧭 Route suggestion (no GPS)
  // nearest-neighbor starting from "medoid"
  // -----------------------
  List<ExplorePlace> buildWishRoute() {
    final wish = byStatus(ExploreStatus.wish);
    if (wish.length <= 2) return wish;

    // start = point with smallest total distance (medoid-ish)
    ExplorePlace start = wish.first;
    double best = double.infinity;

    for (final a in wish) {
      double sum = 0;
      for (final b in wish) {
        if (a.id == b.id) continue;
        sum += _haversineMeters(
          a.position.latitude,
          a.position.longitude,
          b.position.latitude,
          b.position.longitude,
        );
      }
      if (sum < best) {
        best = sum;
        start = a;
      }
    }

    final remaining = [...wish];
    remaining.removeWhere((p) => p.id == start.id);

    final route = <ExplorePlace>[start];
    var current = start;

    while (remaining.isNotEmpty) {
      ExplorePlace nearest = remaining.first;
      double nearestD = double.infinity;

      for (final p in remaining) {
        final d = _haversineMeters(
          current.position.latitude,
          current.position.longitude,
          p.position.latitude,
          p.position.longitude,
        );
        if (d < nearestD) {
          nearestD = d;
          nearest = p;
        }
      }

      route.add(nearest);
      remaining.removeWhere((p) => p.id == nearest.id);
      current = nearest;
    }

    return route;
  }

  static double _haversineMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const R = 6371000.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);

    final a =
        (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            (sin(dLon / 2) * sin(dLon / 2));
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }
}

// dart:math inline (tek dosyada tutmak için)
double sin(double x) => Math._sin(x);
double cos(double x) => Math._cos(x);
double sqrt(double x) => Math._sqrt(x);
double atan2(double y, double x) => Math._atan2(y, x);
double _deg2rad(double d) => d * 0.017453292519943295;

class Math {
  static double _sin(double x) => _m.sin(x);
  static double _cos(double x) => _m.cos(x);
  static double _sqrt(double x) => _m.sqrt(x);
  static double _atan2(double y, double x) => _m.atan2(y, x);
}
