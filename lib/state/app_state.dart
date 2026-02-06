import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  // 🌍 CITY
  String? _city;
  String? _country;

  // 📍 LOCATION (MAP FEATURE İÇİN EKLENDİ)
  double? _lat;
  double? _lng;

  // 🎯 INTERESTS
  final Set<String> _interests = {};
  bool _interestsCompleted = false;

  // 🤝 CONNECTED BUDDIES
  final Set<String> _connectedBuddyIds = {};

  // =====================
  // GETTERS
  // =====================
  bool get hasCity => _city != null && _country != null;
  bool get hasLocation => _lat != null && _lng != null;

  String get cityLabel => hasCity ? '$_city, $_country' : 'City not selected';

  double? get lat => _lat;
  double? get lng => _lng;

  Set<String> get interests => _interests;
  bool get interestsCompleted => _interestsCompleted;

  bool isConnected(String buddyId) {
    return _connectedBuddyIds.contains(buddyId);
  }

  // =====================
  // ACTIONS
  // =====================
  void setCity({required String city, required String country}) {
    _city = city;
    _country = country;
    notifyListeners();
  }

  // 📍 LOCATION
  void setLocation({required double lat, required double lng}) {
    _lat = lat;
    _lng = lng;
    notifyListeners();
  }

  // 🎯 INTERESTS
  void toggleInterest(String interest) {
    _interests.contains(interest)
        ? _interests.remove(interest)
        : _interests.add(interest);
    notifyListeners();
  }

  void completeInterests() {
    _interestsCompleted = true;
    notifyListeners();
  }

  // 🤝 BUDDY
  void connectBuddy(String buddyId) {
    if (_connectedBuddyIds.contains(buddyId)) return;
    _connectedBuddyIds.add(buddyId);
    notifyListeners();
  }
}
