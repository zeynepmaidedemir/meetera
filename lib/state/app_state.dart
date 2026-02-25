import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppState extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? city;
  String? country;
  String? countryCode;
  String? cityId;

  Set<String> interests = {};

  bool onboardingCompleted = false;

  // 🔥 Firestore’dan hydrate
  void hydrateFromFirestore(Map<String, dynamic> data) {
    city = data['cityName'];
    country = data['country'];
    countryCode = data['countryCode'];
    cityId = data['cityId'];
    interests = Set<String>.from(data['interests'] ?? []);
    onboardingCompleted = data['onboardingCompleted'] ?? false;

    notifyListeners();
  }

  String get cityLabel =>
      city != null && country != null ? '$city, $country' : '';

  Future<void> setCity({
    required String city,
    required String country,
    required String countryCode,
    required String cityId,
  }) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    await _firestore.collection('users').doc(uid).update({
      'cityName': city,
      'country': country,
      'countryCode': countryCode,
      'cityId': cityId,
    });
  }

  void toggleInterest(String interest) {
    if (interests.contains(interest)) {
      interests.remove(interest);
    } else {
      interests.add(interest);
    }
    notifyListeners();
  }

  Future<void> saveInterests() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    await _firestore.collection('users').doc(uid).update({
      'interests': interests.toList(),
      'onboardingCompleted': true,
    });
  }

  void reset() {
    city = null;
    country = null;
    countryCode = null;
    cityId = null;
    interests.clear();
    onboardingCompleted = false;
    notifyListeners();
  }
}
