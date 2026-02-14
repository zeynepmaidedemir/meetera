import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../state/event_state.dart';
import '../state/app_state.dart';
import 'create_event_sheet.dart';
import 'event_detail_screen.dart';
import 'event_map_screen.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final cityId = context.read<AppState>().cityId;
    if (cityId != null) {
      context.read<EventState>().listenToEvents(cityId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final city = context.watch<AppState>().city ?? '';
    final cityId = context.watch<AppState>().cityId;
    final events = cityId == null
        ? []
        : context.watch<EventState>().eventsForCity(cityId);

    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text("Events in $city"),
        centerTitle: true,
        actions: [
          if (events.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.map_outlined),
              tooltip: "View on map",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EventMapScreen()),
                );
              },
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text("Create"),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => const CreateEventSheet(),
          );
        },
      ),
      body: events.isEmpty
          ? const Center(
              child: Text(
                "No events yet 🎉\nBe the first to create one!",
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: events.length,
              itemBuilder: (_, i) {
                final e = events[i];

                return GestureDetector(
                  onTap: () {
                    if (userId == null) return;

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            EventDetailScreen(event: e, userId: userId),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade400, Colors.blue.shade700],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            e.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "${e.dateTime.day}.${e.dateTime.month}.${e.dateTime.year}",
                                style: const TextStyle(color: Colors.white),
                              ),
                              const SizedBox(width: 16),
                              const Icon(
                                Icons.location_on,
                                size: 16,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  e.location,
                                  style: const TextStyle(color: Colors.white),
                                  overflow: TextOverflow.ellipsis,
                                ),
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
}
