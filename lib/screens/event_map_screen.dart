import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/event_state.dart';
import '../state/app_state.dart';

class EventMapScreen extends StatelessWidget {
  const EventMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final city = context.watch<AppState>().cityLabel.split(',').first;
    final events = context.watch<EventState>().eventsForCity(city);

    return Scaffold(
      appBar: AppBar(title: Text('Events Map – $city')),
      body: events.isEmpty
          ? const Center(child: Text('No events to show on map 📍'))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: events.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemBuilder: (_, i) {
                final e = events[i];

                return GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (_) => _EventPreview(event: e),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blueGrey.shade100),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.location_pin,
                          size: 40,
                          color: Colors.redAccent,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          e.location,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          e.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _EventPreview extends StatelessWidget {
  final event;

  const _EventPreview({required this.event});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(event.title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(event.description),
          const SizedBox(height: 8),
          Text('📍 ${event.location}'),
          Text('🕒 ${event.dateTime}'),
        ],
      ),
    );
  }
}
