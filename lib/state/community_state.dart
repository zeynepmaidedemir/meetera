import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class CommunityState extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  List<QueryDocumentSnapshot> _posts = [];
  List<QueryDocumentSnapshot> get posts => _posts;

  // 📡 Realtime Feed
  void loadPosts(String cityId) {
    _firestore
        .collection('posts')
        .where('cityId', isEqualTo: cityId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
          _posts = snapshot.docs;
          notifyListeners();
        });
  }

  // 🖼 Upload Image
  Future<String> _uploadImage(File image, String postId) async {
    final ref = _storage.ref().child("post_images/$postId.jpg");
    await ref.putFile(image);
    return await ref.getDownloadURL();
  }

  // ✍️ Create Post (image optional)
  Future<void> createPost({
    required String cityId,
    required String text,
    File? imageFile,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final postId = const Uuid().v4();

    String? imageUrl;

    if (imageFile != null) {
      imageUrl = await _uploadImage(imageFile, postId);
    }

    await _firestore.collection('posts').doc(postId).set({
      'cityId': cityId,
      'authorId': user.uid,
      'authorName': user.displayName ?? 'User',
      'text': text,
      'imageUrl': imageUrl,
      'likedBy': [],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ❤️ Toggle Like
  Future<void> toggleLike(String postId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ref = _firestore.collection('posts').doc(postId);
    final doc = await ref.get();
    final likedBy = List<String>.from(doc['likedBy'] ?? []);

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
}
