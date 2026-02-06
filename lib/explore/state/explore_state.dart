import 'package:flutter/material.dart';
import '../models/explore_place.dart';

class ExploreState extends ChangeNotifier {
  final Map<String, ExplorePlace> _places = {};

  List<ExplorePlace> get all => _places.values.toList();

  List<ExplorePlace> byStatus(ExploreStatus status) =>
      _places.values.where((p) => p.status == status).toList();

  int count(ExploreStatus status) =>
      _places.values.where((p) => p.status == status).length;

  void add(ExplorePlace place) {
    _places[place.id] = place;
    notifyListeners();
  }

  void update(ExplorePlace place) {
    _places[place.id] = place;
    notifyListeners();
  }
}
