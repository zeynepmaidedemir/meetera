import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/explore_place.dart';
import '../models/place_status.dart';
import '../services/badge_engine.dart';
import '../services/wish_route_engine.dart';

class ExploreState extends ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  StreamSubscription? _sub;

  final List<ExplorePlace> _places = [];
  List<ExplorePlace> get all => List.unmodifiable(_places);

  List<ExplorePlace> byStatus(ExploreStatus s) =>
      _places.where((p) => p.status == s).toList();

  String? get _uid => _auth.currentUser?.uid;

  // badges
  List<String> _badges = [];
  List<String> get badges => List.unmodifiable(_badges);

  String? _lastEarned;
  String? consumeNewBadge() {
    final b = _lastEarned;
    _lastEarned = null;
    return b;
  }

  void _refreshBadges() {
    final updated = BadgeEngine.calculate(
      visited: byStatus(ExploreStatus.visited).length,
      favorites: byStatus(ExploreStatus.favorite).length,
      wishes: byStatus(ExploreStatus.wish).length,
      streak: currentStreak,
      current: _badges,
    );

    final gained = updated.where((e) => !_badges.contains(e)).toList();
    _badges = updated;
    if (gained.isNotEmpty) _lastEarned = gained.first;
  }

  void startListening() {
    final uid = _uid;
    if (uid == null) return;

    _sub?.cancel();
    _sub = _firestore
        .collection('explore')
        .doc(uid)
        .collection('pins')
        .orderBy('createdAt')
        .snapshots()
        .listen((snap) {
      _places
        ..clear()
        ..addAll(snap.docs.map((d) => ExplorePlace.fromJson(d.id, d.data())));
      _refreshBadges();
      notifyListeners();
    });
  }

  Future<void> add(ExplorePlace place) async {
    final uid = _uid;
    if (uid == null) return;

    // visited kuralı
    if (place.status == ExploreStatus.visited && place.visitedAt == null) {
      place.visitedAt = DateTime.now();
    }

    await _firestore
        .collection('explore')
        .doc(uid)
        .collection('pins')
        .doc(place.id)
        .set(place.toJson());
  }

  Future<void> update(ExplorePlace place) async {
    final uid = _uid;
    if (uid == null) return;

    if (place.status == ExploreStatus.visited && place.visitedAt == null) {
      place.visitedAt = DateTime.now();
    }

    await _firestore
        .collection('explore')
        .doc(uid)
        .collection('pins')
        .doc(place.id)
        .update(place.toJson());
  }

  Future<void> remove(String id) async {
    final uid = _uid;
    if (uid == null) return;

    await _firestore
        .collection('explore')
        .doc(uid)
        .collection('pins')
        .doc(id)
        .delete();
  }

  // streak
  int get currentStreak {
    final days = byStatus(ExploreStatus.visited)
        .map((e) => e.visitedAt)
        .whereType<DateTime>()
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet()
        .toList()
      ..sort();

    if (days.isEmpty) return 0;

    final today = DateTime.now();
    var check = DateTime(today.year, today.month, today.day);

    final set = days.toSet();
    if (!set.contains(check)) {
      check = check.subtract(const Duration(days: 1));
      if (!set.contains(check)) return 0;
    }

    int streak = 0;
    while (set.contains(check)) {
      streak++;
      check = check.subtract(const Duration(days: 1));
    }
    return streak;
  }

  // route
  List<ExplorePlace> buildWishRoute() {
    final wishes = byStatus(ExploreStatus.wish);
    return WishRouteEngine.buildSmartRoute(wishes);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
