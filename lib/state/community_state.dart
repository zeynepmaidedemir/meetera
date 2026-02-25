import 'dart:io';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class CommunityState extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _posts = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> get posts => _posts;

  StreamSubscription? _sub;

  void disposeStream() {
    _sub?.cancel();
    _sub = null;
  }

  void listenPosts(String cityId) {
    disposeStream();

    _sub = _firestore
        .collection('posts')
        .doc(cityId)
        .collection('items')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snap) {
      _posts = snap.docs;
      notifyListeners();
    });
  }

  Future<String> _uploadImage(File image, String postId) async {
    final ref = _storage.ref().child("post_images/$postId.jpg");
    await ref.putFile(image);
    return await ref.getDownloadURL();
  }

  Future<void> createPost({
    required String cityId,
    required String text,
    required List<String> hashtags,
    File? imageFile,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final postId = const Uuid().v4();
    String? imageUrl;

    if (imageFile != null) {
      imageUrl = await _uploadImage(imageFile, postId);
    }

    await _firestore
        .collection('posts')
        .doc(cityId)
        .collection('items')
        .doc(postId)
        .set({
      'cityId': cityId,
      'authorId': user.uid,
      'authorName': user.displayName ?? user.email ?? 'User',
      'authorPhotoUrl': user.photoURL ?? '',
      'text': text,
      'hashtags': hashtags,
      'imageUrl': imageUrl ?? '',
      'likedBy': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updatePost({
    required String cityId,
    required String postId,
    required String text,
    required List<String> hashtags,
  }) async {
    await _firestore
        .collection('posts')
        .doc(cityId)
        .collection('items')
        .doc(postId)
        .update({
      'text': text,
      'hashtags': hashtags,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deletePost({
    required String cityId,
    required String postId,
  }) async {
    await _firestore
        .collection('posts')
        .doc(cityId)
        .collection('items')
        .doc(postId)
        .delete();
  }

  Future<void> toggleLike({
    required String cityId,
    required String postId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ref = _firestore
        .collection('posts')
        .doc(cityId)
        .collection('items')
        .doc(postId);

    final snap = await ref.get();
    if (!snap.exists) return;

    final data = snap.data() as Map<String, dynamic>? ?? {};
    final likedBy = List<String>.from(data['likedBy'] ?? []);

    if (likedBy.contains(user.uid)) {
      await ref.update({
        'likedBy': FieldValue.arrayRemove([user.uid]),
      });
    } else {
      await ref.update({
        'likedBy': FieldValue.arrayUnion([user.uid]),
      });
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> commentsStream({
    required String cityId,
    required String postId,
  }) {
    return _firestore
        .collection('posts')
        .doc(cityId)
        .collection('items')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  Future<void> addComment({
    required String cityId,
    required String postId,
    required String text,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _firestore
        .collection('posts')
        .doc(cityId)
        .collection('items')
        .doc(postId)
        .collection('comments')
        .add({
      'authorId': user.uid,
      'authorName': user.displayName ?? user.email ?? 'User',
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
