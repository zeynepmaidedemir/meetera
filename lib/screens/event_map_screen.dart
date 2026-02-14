import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/event_state.dart';

class EventMapScreen extends StatelessWidget {
  const EventMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final events = context.watch<EventState>().events;

    return Scaffold(
      appBar: AppBar(title: const Text('Events Map')),
      body: events.isEmpty
          ? const Center(child: Text('No events to show 📍'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: events.length,
              itemBuilder: (_, i) {
                final e = events[i];

                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.location_pin),
                    title: Text(e.title),
                    subtitle: Text(e.location),
                  ),
                );
              },
            ),
    );
  }
}
