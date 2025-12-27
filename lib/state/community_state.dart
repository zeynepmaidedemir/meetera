import 'package:flutter/material.dart';
import '../data/community_models.dart';

class CommunityState extends ChangeNotifier {
  final List<CommunityPost> _posts = [];
  final List<CommunityComment> _comments = [];

  // =====================
  // POSTS
  // =====================
  List<CommunityPost> postsForCity(String city) {
    return _posts.where((p) => p.city == city).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void createPost({
    required String city,
    required String authorId,
    required String authorName,
    required String text,
    String? imageUrl,
  }) {
    _posts.add(
      CommunityPost(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        city: city,
        authorId: authorId,
        authorName: authorName,
        text: text,
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void deletePost(String postId, String userId) {
    _posts.removeWhere((p) => p.id == postId && p.authorId == userId);
    _comments.removeWhere((c) => c.postId == postId);
    notifyListeners();
  }

  void toggleLike(String postId, String userId) {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final post = _posts[index];
    final updatedLikes = Set<String>.from(post.likedBy);

    updatedLikes.contains(userId)
        ? updatedLikes.remove(userId)
        : updatedLikes.add(userId);

    _posts[index] = post.copyWith(likedBy: updatedLikes);
    notifyListeners();
  }

  // =====================
  // COMMENTS
  // =====================
  List<CommunityComment> commentsForPost(String postId) {
    return _comments.where((c) => c.postId == postId).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  void addComment({
    required String postId,
    required String authorId,
    required String authorName,
    required String text,
  }) {
    _comments.add(
      CommunityComment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        postId: postId,
        authorId: authorId,
        authorName: authorName,
        text: text,
        createdAt: DateTime.now(),
      ),
    );

    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final post = _posts[index];
    _posts[index] = post.copyWith(commentCount: post.commentCount + 1);

    notifyListeners();
  }
}
