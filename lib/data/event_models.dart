import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String cityId;
  final String title;
  final String description;
  final DateTime dateTime;
  final String location;
  final String creatorId;
  final String creatorName;
  final List<String> interestedUserIds;
  final List<String> goingUserIds;
  final DateTime createdAt;

  final double? lat;
  final double? lng;
  final String? imageUrl;

  Event({
    required this.id,
    required this.cityId,
    required this.title,
    required this.description,
    required this.dateTime,
    required this.location,
    required this.creatorId,
    required this.creatorName,
    required this.interestedUserIds,
    required this.goingUserIds,
    required this.createdAt,
    this.lat,
    this.lng,
    this.imageUrl,
  });

  // 🔥 Firestore → Model
  factory Event.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Event(
      id: doc.id,
      cityId: data['cityId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      dateTime: (data['dateTime'] as Timestamp).toDate(),
      location: data['location'] ?? '',
      creatorId: data['creatorId'] ?? '',
      creatorName: data['creatorName'] ?? '',
      interestedUserIds: List<String>.from(data['interestedUserIds'] ?? []),
      goingUserIds: List<String>.from(data['goingUserIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lat: data['lat'],
      lng: data['lng'],
      imageUrl: data['imageUrl'],
    );
  }

  // 🔥 Model → Firestore
  Map<String, dynamic> toMap() {
    return {
      'cityId': cityId,
      'title': title,
      'description': description,
      'dateTime': Timestamp.fromDate(dateTime),
      'location': location,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'interestedUserIds': interestedUserIds,
      'goingUserIds': goingUserIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'lat': lat,
      'lng': lng,
      'imageUrl': imageUrl,
    };
  }
}
