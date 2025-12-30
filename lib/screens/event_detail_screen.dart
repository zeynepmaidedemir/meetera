import '../services/notification_service.dart';
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
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined),
            onPressed: _addToCalendar,
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: _shareEvent,
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(event.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),

          Text(
            '📍 ${event.location}',
            style: const TextStyle(color: Colors.grey),
          ),
          Text(
            '🕒 ${event.dateTime}',
            style: const TextStyle(color: Colors.grey),
          ),

          IconButton(
            icon: const Icon(Icons.notifications_active_outlined),
            tooltip: 'Remind me',
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

          const SizedBox(height: 16),
          Text(event.description),

          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  icon: Icon(isInterested ? Icons.star : Icons.star_border),
                  label: Text('Interested (${event.interestedUserIds.length})'),
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
                  label: Text('Going (${event.goingUserIds.length})'),
                  onPressed: () => eventState.toggleGoing(event.id, userId),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

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

  void _shareEvent() {
    Share.share('${event.title}\n${event.location}\n${event.dateTime}');
  }
}
