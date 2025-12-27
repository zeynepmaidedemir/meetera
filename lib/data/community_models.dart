class CommunityPost {
  final String id;
  final String city;
  final String authorId;
  final String authorName;
  final String text;
  final String? imageUrl;
  final DateTime createdAt;

  final Set<String> likedBy;
  final int commentCount;

  CommunityPost({
    required this.id,
    required this.city,
    required this.authorId,
    required this.authorName,
    required this.text,
    this.imageUrl,
    required this.createdAt,
    Set<String>? likedBy,
    this.commentCount = 0,
  }) : likedBy = likedBy ?? {};

  CommunityPost copyWith({Set<String>? likedBy, int? commentCount}) {
    return CommunityPost(
      id: id,
      city: city,
      authorId: authorId,
      authorName: authorName,
      text: text,
      imageUrl: imageUrl,
      createdAt: createdAt,
      likedBy: likedBy ?? this.likedBy,
      commentCount: commentCount ?? this.commentCount,
    );
  }
}

class CommunityComment {
  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String text;
  final DateTime createdAt;

  CommunityComment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    required this.text,
    required this.createdAt,
  });
}
