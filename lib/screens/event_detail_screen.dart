import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:add_2_calendar/add_2_calendar.dart' as cal;

import '../data/event_models.dart';
import '../state/event_state.dart';

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
        title: const Text('Event Details'),
        actions: [
          // 📅 ADD TO CALENDAR
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined),
            tooltip: 'Add to calendar',
            onPressed: _addToCalendar,
          ),

          // 🔗 SHARE
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share event',
            onPressed: _shareEvent,
          ),

          // 🗑️ DELETE (CREATOR ONLY)
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 🖼️ IMAGE
          if (event.imageUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                event.imageUrl!,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // TITLE
          Text(event.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),

          // META
          Text(
            '📍 ${event.location}',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            '🕒 ${_formatDateTime(event.dateTime)}',
            style: const TextStyle(color: Colors.grey),
          ),

          const SizedBox(height: 16),

          // DESCRIPTION
          Text(event.description, style: Theme.of(context).textTheme.bodyLarge),

          const SizedBox(height: 24),

          // PARTICIPATION
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  icon: Icon(isInterested ? Icons.star : Icons.star_border),
                  label: Text('Interested (${event.interestedUserIds.length})'),
                  onPressed: () {
                    eventState.toggleInterested(event.id, userId);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  icon: Icon(
                    isGoing ? Icons.check_circle : Icons.check_circle_outline,
                  ),
                  label: Text('Going (${event.goingUserIds.length})'),
                  onPressed: () {
                    eventState.toggleGoing(event.id, userId);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 📅 CALENDAR
  void _addToCalendar() {
    final calendarEvent = cal.Event(
      title: event.title,
      description: event.description,
      location: event.location,
      startDate: event.dateTime,
      endDate: event.dateTime.add(const Duration(hours: 2)),
    );

    cal.Add2Calendar.addEvent2Cal(calendarEvent);
  }

  // 🔗 SHARE
  void _shareEvent() {
    final link = 'https://meetera.app/event/${event.id}';

    final message =
        '''
🎉 ${event.title}

📍 ${event.location}
🕒 ${_formatDateTime(event.dateTime)}

Add to your calendar & join us 👇
$link
''';

    Share.share(message);
  }

  static String _formatDateTime(DateTime dt) {
    final date =
        '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    final time =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$date – $time';
  }
}
