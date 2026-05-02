class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String bio;
  final String photoUrl;
  final String currentCity;
  final String homeCountry;
  final List<String> interests;
  final List<String> blockedUsers;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.bio,
    required this.photoUrl,
    required this.currentCity,
    required this.homeCountry,
    required this.interests,
    required this.blockedUsers,
  });

  factory UserModel.fromFirestore(String id, Map<String, dynamic> data) {
    return UserModel(
      uid: id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? 'User',
      bio: data['bio'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      currentCity: data['cityId'] ?? data['currentCity'] ?? '', // Fallback for old data
      homeCountry: data['homeCountry'] ?? '',
      interests: List<String>.from(data['interests'] ?? []),
      blockedUsers: List<String>.from(data['blockedUsers'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'bio': bio,
      'photoUrl': photoUrl,
      'currentCity': currentCity,
      'homeCountry': homeCountry,
      'interests': interests,
      'blockedUsers': blockedUsers,
    };
  }
}
