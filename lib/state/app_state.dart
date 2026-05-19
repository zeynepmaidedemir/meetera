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
  Set<String> blockedUsers = {};

  bool onboardingCompleted = false;

  // 🔥 Firestore’dan hydrate
  void hydrateFromFirestore(Map<String, dynamic> data) {
    city = data['cityName'];
    country = data['country'];
    countryCode = data['countryCode'];
    cityId = data['cityId'];
    interests = Set<String>.from(data['interests'] ?? []);
    blockedUsers = Set<String>.from(data['blockedUsers'] ?? []);
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
  
  Future<void> blockUser(String blockUid) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    blockedUsers.add(blockUid);
    notifyListeners();
    
    await _firestore.collection('users').doc(user.uid).update({
      'blockedUsers': FieldValue.arrayUnion([blockUid])
    });
  }
  
  Future<void> reportContent({
    required String contentType, // 'post', 'user', 'comment'
    required String contentId,
    required String reportedUid,
    required String reason,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    await _firestore.collection('reports').add({
      'reporterId': user.uid,
      'reportedUid': reportedUid,
      'contentId': contentId,
      'contentType': contentType,
      'reason': reason,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'pending',
    });
  }

  void reset() {
    city = null;
    country = null;
    countryCode = null;
    cityId = null;
    interests.clear();
    blockedUsers.clear();
    onboardingCompleted = false;
    notifyListeners();
  }
}
