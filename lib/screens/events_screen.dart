  import 'package:flutter/material.dart';
  import 'package:provider/provider.dart';

  import '../state/event_state.dart';
  import '../state/app_state.dart';
  import 'create_event_sheet.dart';
  import 'event_map_screen.dart';
  import 'event_detail_screen.dart';

  class EventsScreen extends StatelessWidget {
    const EventsScreen({super.key});

    @override
    Widget build(BuildContext context) {
      final city = context.watch<AppState>().cityLabel.split(',').first;
      final events = context.watch<EventState>().eventsForCity(city);
      final userId = 'me';

      return Scaffold(
        appBar: AppBar(
          title: Text('Events in $city'),
          actions: [
            // 🗺️ MAP VIEW
            IconButton(
              icon: const Icon(Icons.map_outlined),
              tooltip: 'View events on map',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EventMapScreen()),
                );
              },
            ),
          ],
        ),

        // ➕ CREATE EVENT
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => const CreateEventSheet(),
            );
          },
          child: const Icon(Icons.add),
        ),

        // 📋 EVENT LIST
        body: events.isEmpty
            ? const Center(child: Text('No events yet 🎉'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: events.length,
                itemBuilder: (_, i) {
                  final e = events[i];
                  final eventState = context.read<EventState>();

                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              EventDetailScreen(event: e, userId: userId),
                        ),
                      );
                    },
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // HEADER
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    e.title,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                ),
                                if (e.creatorId == userId)
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    tooltip: 'Delete event',
                                    onPressed: () {
                                      eventState.deleteEvent(e.id, userId);
                                    },
                                  ),
                              ],
                            ),

                            // 🖼️ IMAGE (OPTIONAL)
                            if (e.imageUrl != null) ...[
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  e.imageUrl!,
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ],

                            const SizedBox(height: 8),

                            // DESCRIPTION
                            Text(e.description),

                            const SizedBox(height: 8),

                            // META
                            Text(
                              '📍 ${e.location}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                            Text(
                              '🕒 ${_formatDateTime(e.dateTime)}',
                              style: const TextStyle(color: Colors.grey),
                            ),

                            const SizedBox(height: 12),

                            // ACTIONS
                            Row(
                              children: [
                                TextButton.icon(
                                  icon: Icon(
                                    eventState.isInterested(e.id, userId)
                                        ? Icons.star
                                        : Icons.star_border,
                                  ),
                                  label: Text(
                                    'Interested (${e.interestedUserIds.length})',
                                  ),
                                  onPressed: () {
                                    eventState.toggleInterested(e.id, userId);
                                  },
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  icon: Icon(
                                    eventState.isGoing(e.id, userId)
                                        ? Icons.check_circle
                                        : Icons.check_circle_outline,
                                  ),
                                  label: Text('Going (${e.goingUserIds.length})'),
                                  onPressed: () {
                                    eventState.toggleGoing(e.id, userId);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      );
    }

    // 🕒 DATE FORMATTER
    static String _formatDateTime(DateTime dt) {
      final date =
          '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
      final time =
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      return '$date – $time';
    }
  }
