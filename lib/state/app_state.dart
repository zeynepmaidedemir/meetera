import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppState extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _city;
  String? _country;
  String? _countryCode;
  String? _cityId;

  final Set<String> _interests = {};
  final Set<String> _connectedBuddyIds = {};

  bool _profileLoaded = false;

  // ==============================
  // GETTERS
  // ==============================

  bool get profileLoaded => _profileLoaded;

  String? get city => _city;
  String? get country => _country;
  String? get countryCode => _countryCode;
  String? get cityId => _cityId;

  bool get hasCity => _cityId != null;
  bool get hasInterests => _interests.isNotEmpty;

  // 🔥 Eski UI uyumluluğu
  bool get interestsCompleted => _interests.isNotEmpty;

  Set<String> get interests => _interests;

  String get cityLabel {
    if (_city == null || _country == null) {
      return "City not selected";
    }
    return "$_city, $_country";
  }

  bool isConnected(String buddyId) {
    return _connectedBuddyIds.contains(buddyId);
  }

  // ==============================
  // PROFILE LOAD
  // ==============================

  Future<void> loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await _firestore.collection('users').doc(user.uid).get();

    if (!doc.exists) {
      _profileLoaded = true;
      notifyListeners();
      return;
    }

    final data = doc.data()!;

    _city = data['city'];
    _country = data['country'];
    _countryCode = data['countryCode'];
    _cityId = data['cityId'];

    final interestsFromDb = List<String>.from(data['interests'] ?? []);

    _interests
      ..clear()
      ..addAll(interestsFromDb);

    _profileLoaded = true;
    notifyListeners();
  }

  // ==============================
  // CITY SAVE
  // ==============================

  Future<void> setCity({
    required String city,
    required String country,
    required String countryCode,
    required String cityId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _city = city;
    _country = country;
    _countryCode = countryCode;
    _cityId = cityId;

    await _firestore.collection('users').doc(user.uid).set({
      'city': city,
      'country': country,
      'countryCode': countryCode,
      'cityId': cityId,
    }, SetOptions(merge: true));

    notifyListeners();
  }

  // ==============================
  // INTERESTS
  // ==============================

  void toggleInterest(String interest) {
    if (_interests.contains(interest)) {
      _interests.remove(interest);
    } else {
      _interests.add(interest);
    }
    notifyListeners();
  }

  Future<void> completeInterests() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).set({
      'interests': _interests.toList(),
    }, SetOptions(merge: true));

    notifyListeners();
  }

  // ==============================
  // BUDDY
  // ==============================

  void connectBuddy(String buddyId) {
    if (_connectedBuddyIds.contains(buddyId)) return;

    _connectedBuddyIds.add(buddyId);
    notifyListeners();
  }

  // ==============================
  // RESET (LOGOUT İÇİN)
  // ==============================

  void reset() {
    _city = null;
    _country = null;
    _countryCode = null;
    _cityId = null;

    _interests.clear();
    _connectedBuddyIds.clear();

    _profileLoaded = false;

    notifyListeners();
  }
}
