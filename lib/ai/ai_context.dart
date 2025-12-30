import '../data/event_models.dart';

class AiContext {
  final String city;
  final List<Event> events;

  AiContext({required this.city, required this.events});

  String toPrompt() {
    final buffer = StringBuffer();

    buffer.writeln('User city: $city');

    if (events.isNotEmpty) {
      buffer.writeln('\nUpcoming events:');
      for (final e in events.take(5)) {
        buffer.writeln('- ${e.title} at ${e.location} on ${e.dateTime}');
      }
    }

    return buffer.toString();
  }
}
