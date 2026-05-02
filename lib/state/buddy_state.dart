import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';

import 'dart:async';

class BuddyState extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<UserModel> _users = [];
  List<UserModel> get users => _users;

  String? get _me => FirebaseAuth.instance.currentUser?.uid;
  StreamSubscription? _usersSub;

  void loadUsersByCity(String cityId) {
    final me = _me;
    if (me == null) return;

    _usersSub?.cancel();
    _usersSub = _firestore
        .collection('users')
        .where('cityId', isEqualTo: cityId)
        .snapshots()
        .listen((snapshot) {
      _users = snapshot.docs
          .where((doc) => doc.id != me)
          .map((doc) => UserModel.fromFirestore(doc.id, doc.data()))
          .toList();
      notifyListeners();
    });
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

  Future<void> disconnect(String otherUserId) async {
    final me = _me;
    if (me == null) return;

    final users = [me, otherUserId]..sort();
    final convoId = users.join('_');

    await _firestore.collection('chats').doc(convoId).delete();
  }

  Stream<List<String>> myConnectedIdsStream() {
    final me = _me;
    if (me == null) return const Stream.empty();

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: me)
        .snapshots()
        .map((snap) {
      final ids = <String>[];
      for (var doc in snap.docs) {
        final participants = List<String>.from(doc['participants'] ?? []);
        for (var p in participants) {
          if (p != me) ids.add(p);
        }
      }
      return ids;
    });
  }

  @override
  void dispose() {
    _usersSub?.cancel();
    super.dispose();
  }
}
