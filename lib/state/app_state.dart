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

  // =========================
  // GETTERS
  // =========================

  String? get city => _city;
  String? get country => _country;
  String? get countryCode => _countryCode;
  String? get cityId => _cityId;

  bool get profileLoaded => _profileLoaded;

  Set<String> get interests => _interests;

  bool get hasCity => _cityId != null && _cityId!.isNotEmpty;
  bool get hasInterests => _interests.isNotEmpty;

  String get cityLabel =>
      _city != null && _country != null ? '$_city, $_country' : '';

  // 🔥 Buddy compatibility
  bool isConnected(String buddyId) {
    return _connectedBuddyIds.contains(buddyId);
  }

  // =========================
  // LOAD PROFILE
  // =========================

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

    final dbInterests = List<String>.from(data['interests'] ?? []);

    _interests
      ..clear()
      ..addAll(dbInterests);

    _profileLoaded = true;
    notifyListeners();
  }

  // =========================
  // SAVE CITY
  // =========================

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
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    notifyListeners();
  }

  // =========================
  // INTERESTS
  // =========================

  void toggleInterest(String interest) {
    if (_interests.contains(interest)) {
      _interests.remove(interest);
    } else {
      _interests.add(interest);
    }
    notifyListeners();
  }

  Future<void> saveInterests() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).set({
      'interests': _interests.toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    notifyListeners();
  }

  // =========================
  // BUDDY CONNECT
  // =========================

  void connectBuddy(String buddyId) {
    _connectedBuddyIds.add(buddyId);
    notifyListeners();
  }

  // =========================
  // RESET
  // =========================

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
