import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/buddy_user.dart';

class BuddyState extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<BuddyUser> _users = [];
  List<BuddyUser> get users => _users;

  String? get _me => FirebaseAuth.instance.currentUser?.uid;

  Future<void> loadUsersByCity(String cityId) async {
    final me = _me;
    if (me == null) return;

    final snapshot = await _firestore
        .collection('users')
        .where('cityId', isEqualTo: cityId)
        .get();

    _users = snapshot.docs
        .where((doc) => doc.id != me)
        .map((doc) => BuddyUser.fromFirestore(doc.id, doc.data()))
        .toList();

    notifyListeners();
  }

  int matchPercent({
    required List<String> myInterests,
    required List<String> otherInterests,
  }) {
    if (myInterests.isEmpty || otherInterests.isEmpty) return 0;

    final my = myInterests.toSet();
    final other = otherInterests.toSet();

    final common = my.intersection(other).length;
    final union = my.union(other).length;

    if (union == 0) return 0;

    return ((common / union) * 100).round();
  }

  Future<void> connect(String otherUserId) async {
    final me = _me;
    if (me == null) return;

    final users = [me, otherUserId]..sort();
    final convoId = users.join('_');

    final ref = _firestore.collection('chats').doc(convoId);
    final snap = await ref.get();

    if (!snap.exists) {
      await ref.set({
        'participants': users,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
      });
    } else {
      await ref.update({'updatedAt': FieldValue.serverTimestamp()});
    }
  }

  Future<List<String>> getMyConnectedIds() async {
    final me = _me;
    if (me == null) return [];

    final snap = await _firestore
        .collection('chats')
        .where('participants', arrayContains: me)
        .get();

    final ids = <String>[];

    for (var doc in snap.docs) {
      final participants = List<String>.from(doc['participants'] ?? []);
      for (var p in participants) {
        if (p != me) ids.add(p);
      }
    }

    return ids;
  }
}
