import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/event_models.dart';

class EventState extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Event> _events = [];
  StreamSubscription? _subscription;

  List<Event> get events => _events;

  List<Event> eventsForCity(String cityId) {
    return _events.where((e) => e.cityId == cityId).toList();
  }

  void listenToEvents(String cityId) {
    _subscription?.cancel();

    _subscription = _firestore
        .collection('events')
        .where('cityId', isEqualTo: cityId)
        .orderBy('dateTime')
        .snapshots()
        .listen((snapshot) {
          _events = snapshot.docs
              .map<Event>((doc) => Event.fromFirestore(doc))
              .toList();

          notifyListeners();
        });
  }

  Future<void> addEvent({
    required String cityId,
    required String title,
    required String description,
    required String location,
    required DateTime dateTime,
    required String creatorId,
    required String creatorName,
  }) async {
    final newEvent = Event(
      id: '',
      cityId: cityId,
      title: title,
      description: description,
      dateTime: dateTime,
      location: location,
      creatorId: creatorId,
      creatorName: creatorName,
      interestedUserIds: [],
      goingUserIds: [],
      createdAt: DateTime.now(),
    );

    await _firestore.collection('events').add(newEvent.toMap());
  }

  Future<void> toggleInterested(String eventId, String userId) async {
    final ref = _firestore.collection('events').doc(eventId);

    await ref.update({
      'interestedUserIds': FieldValue.arrayUnion([userId]),
    });
  }

  Future<void> toggleGoing(String eventId, String userId) async {
    final ref = _firestore.collection('events').doc(eventId);

    await ref.update({
      'goingUserIds': FieldValue.arrayUnion([userId]),
    });
  }

  bool isInterested(String eventId, String userId) {
    final event = _events.firstWhere((e) => e.id == eventId);
    return event.interestedUserIds.contains(userId);
  }

  bool isGoing(String eventId, String userId) {
    final event = _events.firstWhere((e) => e.id == eventId);
    return event.goingUserIds.contains(userId);
  }

  Future<void> deleteEvent(String eventId, String userId) async {
    await _firestore.collection('events').doc(eventId).delete();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
