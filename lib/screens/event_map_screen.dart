import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../data/event_models.dart';

class EventMapScreen extends StatelessWidget {
  const EventMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final cityId = appState.cityId;

    if (cityId == null) {
      return const Scaffold(body: Center(child: Text("City not selected")));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Events Map")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('events')
            .where('cityId', isEqualTo: cityId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          final events = docs
              .map((d) => Event.fromFirestore(d))
              .where((e) => e.lat != null && e.lng != null)
              .toList();

          if (events.isEmpty) {
            return const Center(child: Text("No events with location yet 🗺️"));
          }

          final markers = events.map((event) {
            return Marker(
              markerId: MarkerId(event.id),
              position: LatLng(event.lat!, event.lng!),
              infoWindow: InfoWindow(
                title: event.title,
                snippet: event.location,
              ),
            );
          }).toSet();

          return GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(events.first.lat!, events.first.lng!),
              zoom: 12,
            ),
            markers: markers,
          );
        },
      ),
    );
  }
}
