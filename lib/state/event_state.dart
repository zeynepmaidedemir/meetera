import 'package:flutter/material.dart';
import '../data/event_models.dart';

class EventState extends ChangeNotifier {
  final List<Event> _events = [];

  List<Event> get events => List.unmodifiable(_events);

  // ❗ ŞİMDİLİK FİLTRE YOK → EVENTLER GÖRÜNSÜN
  List<Event> eventsForCity(String city) {
    return _events;
  }

  // ➕ ADD EVENT (STABLE)
  void addEvent({
    required String title,
    required String description,
    required String location,
    required DateTime dateTime,
    required String creatorId,
  }) {
    final newEvent = Event(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      location: location,
      dateTime: dateTime,

      // modelin zorunlu alanları
      city: location,
      creatorId: creatorId,
      creatorName: 'You',
      createdAt: DateTime.now(),

      imageUrl: null,
      interestedUserIds: [],
      goingUserIds: [],
    );

    _events.insert(0, newEvent);
    notifyListeners();
  }

  // ⭐ Interested
  void toggleInterested(String eventId, String userId) {
    final event = _events.firstWhere((e) => e.id == eventId);

    if (event.interestedUserIds.contains(userId)) {
      event.interestedUserIds.remove(userId);
    } else {
      event.interestedUserIds.add(userId);
      event.goingUserIds.remove(userId);
    }
    notifyListeners();
  }

  // ✅ Going
  void toggleGoing(String eventId, String userId) {
    final event = _events.firstWhere((e) => e.id == eventId);

    if (event.goingUserIds.contains(userId)) {
      event.goingUserIds.remove(userId);
    } else {
      event.goingUserIds.add(userId);
      event.interestedUserIds.remove(userId);
    }
    notifyListeners();
  }

  // 🗑️ Delete
  void deleteEvent(String eventId, String userId) {
    _events.removeWhere((e) => e.id == eventId && e.creatorId == userId);
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
