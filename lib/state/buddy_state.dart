import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/buddy_user.dart';

class BuddyState extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<BuddyUser> _users = [];
  List<BuddyUser> get users => _users;

  Set<String> _connectedUserIds = {};

  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  Future<void> loadUsersByCity(String cityId) async {
    final snapshot = await _firestore
        .collection('users')
        .where('cityId', isEqualTo: cityId)
        .get();

    _users = snapshot.docs
        .where((doc) => doc.id != _currentUserId)
        .map((doc) => BuddyUser.fromFirestore(doc.id, doc.data()))
        .toList();

    notifyListeners();
  }

  double matchPercent({
    required List<String> myInterests,
    required List<String> otherInterests,
  }) {
    if (myInterests.isEmpty || otherInterests.isEmpty) return 0;

    final common = otherInterests.where((i) => myInterests.contains(i)).length;

    return common / otherInterests.length;
  }

  bool isConnected(String uid) {
    return _connectedUserIds.contains(uid);
  }

  void connect(String uid) {
    _connectedUserIds.add(uid);
    notifyListeners();
  }
}
