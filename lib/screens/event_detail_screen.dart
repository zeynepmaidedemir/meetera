import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../data/event_models.dart';
import '../state/event_state.dart';
import '../services/notification_service.dart';

class EventDetailScreen extends StatelessWidget {
  final Event event;
  final String userId;

  const EventDetailScreen({
    super.key,
    required this.event,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final eventState = context.watch<EventState>();
    final isInterested = eventState.isInterested(event.id, userId);
    final isGoing = eventState.isGoing(event.id, userId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              Share.share(
                '${event.title}\n${event.location}\n${event.dateTime}',
              );
            },
          ),
          if (event.creatorId == userId)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                eventState.deleteEvent(event.id, userId);
                Navigator.pop(context);
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(event.title, style: Theme.of(context).textTheme.headlineSmall),

            const SizedBox(height: 12),

            Text(event.description, style: const TextStyle(fontSize: 16)),

            const SizedBox(height: 20),

            Row(
              children: [
                const Icon(Icons.calendar_today),
                const SizedBox(width: 8),
                Text(
                  '${event.dateTime.day}.${event.dateTime.month}.${event.dateTime.year} – ${event.dateTime.hour}:${event.dateTime.minute.toString().padLeft(2, '0')}',
                ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                const Icon(Icons.location_on),
                const SizedBox(width: 8),
                Text(event.location),
              ],
            ),

            const Spacer(),

            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    icon: Icon(isInterested ? Icons.star : Icons.star_border),
                    label: const Text("Interested"),
                    onPressed: () =>
                        eventState.toggleInterested(event.id, userId),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    icon: Icon(
                      isGoing ? Icons.check_circle : Icons.check_circle_outline,
                    ),
                    label: const Text("Going"),
                    onPressed: () => eventState.toggleGoing(event.id, userId),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.notifications_active),
                label: const Text("Remind me (30 min before)"),
                onPressed: () {
                  final reminderTime = event.dateTime.subtract(
                    const Duration(minutes: 30),
                  );

                  NotificationService.scheduleReminder(
                    id: event.dateTime.millisecondsSinceEpoch,
                    title: 'Upcoming Event',
                    body: event.title,
                    scheduledDate: reminderTime,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
