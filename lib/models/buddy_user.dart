class BuddyUser {
  final String uid;
  final String displayName;
  final String bio;
  final String photoUrl;
  final String cityId;
  final List<String> interests;

  BuddyUser({
    required this.uid,
    required this.displayName,
    required this.bio,
    required this.photoUrl,
    required this.cityId,
    required this.interests,
  });

  factory BuddyUser.fromFirestore(String id, Map<String, dynamic> data) {
    return BuddyUser(
      uid: id,
      displayName: data['displayName'] ?? 'User',
      bio: data['bio'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      cityId: data['cityId'] ?? '',
      interests: List<String>.from(data['interests'] ?? []),
    );
  }
}
