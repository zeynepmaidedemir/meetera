import 'package:flutter/material.dart';
import '../data/event_models.dart';

class EventState extends ChangeNotifier {
  final List<Event> _events = [];

  List<Event> eventsForCity(String city) {
    return _events.where((e) => e.city == city).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  void createEvent({
    required String city,
    required String title,
    required String description,
    required DateTime dateTime,
    required String location,
    required String creatorId,
    required String creatorName,
    String? imageUrl,
  }) {
    _events.add(
      Event(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        city: city,
        title: title,
        description: description,
        dateTime: dateTime,
        location: location,
        creatorId: creatorId,
        creatorName: creatorName,
        interestedUserIds: [],
        goingUserIds: [],
        createdAt: DateTime.now(),
        imageUrl: imageUrl,
      ),
    );
    notifyListeners();
  }

  void deleteEvent(String eventId, String userId) {
    _events.removeWhere((e) => e.id == eventId && e.creatorId == userId);
    notifyListeners();
  }

  void toggleInterested(String eventId, String userId) {
    final e = _events.firstWhere((e) => e.id == eventId);
    if (e.interestedUserIds.contains(userId)) {
      e.interestedUserIds.remove(userId);
    } else {
      e.interestedUserIds.add(userId);
      e.goingUserIds.remove(userId);
    }
    notifyListeners();
  }

  void toggleGoing(String eventId, String userId) {
    final e = _events.firstWhere((e) => e.id == eventId);
    if (e.goingUserIds.contains(userId)) {
      e.goingUserIds.remove(userId);
    } else {
      e.goingUserIds.add(userId);
      e.interestedUserIds.remove(userId);
    }
    notifyListeners();
  }

  bool isInterested(String eventId, String userId) {
    return _events
        .firstWhere((e) => e.id == eventId)
        .interestedUserIds
        .contains(userId);
  }

  bool isGoing(String eventId, String userId) {
    return _events
        .firstWhere((e) => e.id == eventId)
        .goingUserIds
        .contains(userId);
  }
}
