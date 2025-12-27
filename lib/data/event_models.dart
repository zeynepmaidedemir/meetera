class Event {
  final String id;
  final String city;
  final String title;
  final String description;
  final DateTime dateTime;
  final String location;
  final String creatorId;
  final String creatorName;
  final List<String> interestedUserIds;
  final List<String> goingUserIds;
  final DateTime createdAt;

  // 🖼️ IMAGE (MOCK / FUTURE UPLOAD)
  final String? imageUrl;

  Event({
    required this.id,
    required this.city,
    required this.title,
    required this.description,
    required this.dateTime,
    required this.location,
    required this.creatorId,
    required this.creatorName,
    required this.interestedUserIds,
    required this.goingUserIds,
    required this.createdAt,
    this.imageUrl,
  });
}
