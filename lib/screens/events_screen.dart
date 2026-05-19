import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../state/event_state.dart';
import '../state/app_state.dart';
import '../data/event_models.dart';
import 'create_event_sheet.dart';
import 'event_detail_screen.dart';
import 'event_map_screen.dart';
import 'event_city_picker_screen.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  String? _currentCityId;
  String? _currentCityName;
  int _selectedFilterIndex = 0; // 0: Upcoming, 1: My Events, 2: Past Events

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_currentCityId == null) {
      final appState = context.read<AppState>();
      final cityId = appState.cityId;
      if (cityId != null) {
        _currentCityId = cityId;
        _currentCityName = appState.city;
        context.read<EventState>().listenToEvents(cityId);
      }
    }
  }

  List<Event> _filterEvents(List<Event> allEvents, String? userId) {
    final now = DateTime.now();
    if (_selectedFilterIndex == 0) {
      // Upcoming
      return allEvents.where((e) => e.dateTime.isAfter(now)).toList();
    } else if (_selectedFilterIndex == 1) {
      // My Events
      if (userId == null) return [];
      return allEvents.where((e) => e.creatorId == userId || e.goingUserIds.contains(userId)).toList();
    } else {
      // Past
      return allEvents.where((e) => e.dateTime.isBefore(now)).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayCityName = _currentCityName ?? 'Loading...';
    final allEvents = _currentCityId == null ? <Event>[] : context.watch<EventState>().eventsForCity(_currentCityId!);
    final userId = FirebaseAuth.instance.currentUser?.uid;
    
    final filteredEvents = _filterEvents(allEvents, userId);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: GestureDetector(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EventCityPickerScreen()),
            );
            if (result != null && result is Map<String, String>) {
              setState(() {
                _currentCityId = result['cityId'];
                _currentCityName = result['cityName'];
              });
              context.read<EventState>().listenToEvents(_currentCityId!);
            }
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Events in $displayCityName",
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black87),
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          if (allEvents.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.map_outlined, color: Colors.black87),
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
      body: Column(
        children: [
          // Filter Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip(0, "Upcoming", Icons.calendar_today_rounded),
                const SizedBox(width: 8),
                _buildFilterChip(1, "My Events", Icons.star_border_rounded),
                const SizedBox(width: 8),
                _buildFilterChip(2, "Past Events", Icons.history_rounded),
              ],
            ),
          ),
          
          Expanded(
            child: filteredEvents.isEmpty
                ? const Center(
                    child: Text(
                      "No events found 🍃\nTry checking another tab or create one!",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredEvents.length,
                    itemBuilder: (_, i) {
                      return _EventCard(
                        event: filteredEvents[i],
                        userId: userId,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(int index, String label, IconData icon) {
    final isSelected = _selectedFilterIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilterIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? const Color(0xFF6366F1) : Colors.grey.shade300,
          ),
          boxShadow: isSelected 
            ? [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] 
            : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final Event event;
  final String? userId;

  const _EventCard({required this.event, required this.userId});

  String _getCategory(String title) {
    final t = title.toLowerCase();
    if (t.contains('party') || t.contains('club') || t.contains('dj')) return 'PARTY';
    if (t.contains('tour') || t.contains('trip') || t.contains('visit')) return 'TOUR';
    if (t.contains('culture') || t.contains('art') || t.contains('museum') || t.contains('night')) return 'CULTURE';
    if (t.contains('workshop') || t.contains('class') || t.contains('learn')) return 'WORKSHOP';
    return 'MEETUP';
  }
  
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'PARTY': return const Color(0xFFE84393); // Pink
      case 'TOUR': return const Color(0xFF00B894);  // Green
      case 'CULTURE': return const Color(0xFFF39C12); // Orange
      case 'WORKSHOP': return const Color(0xFF0984E3); // Blue
      default: return const Color(0xFF6C5CE7); // Purple
    }
  }

  String _getFallbackImage(String category) {
    switch (category) {
      case 'PARTY': return 'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?q=80&w=800&auto=format&fit=crop';
      case 'TOUR': return 'https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?q=80&w=800&auto=format&fit=crop';
      case 'CULTURE': return 'https://images.unsplash.com/photo-1514539079130-25950c84af65?q=80&w=800&auto=format&fit=crop';
      case 'WORKSHOP': return 'https://images.unsplash.com/photo-1524178232363-1fb2b075b655?q=80&w=800&auto=format&fit=crop';
      default: return 'https://images.unsplash.com/photo-1511632765486-a01980e01a18?q=80&w=800&auto=format&fit=crop';
    }
  }

  @override
  Widget build(BuildContext context) {
    final category = _getCategory(event.title);
    final categoryColor = _getCategoryColor(category);
    final imageUrl = event.imageUrl?.isNotEmpty == true ? event.imageUrl! : _getFallbackImage(category);

    final dateFormat = DateFormat('d MMM, yyyy');

    return GestureDetector(
      onTap: () {
        if (userId == null) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EventDetailScreen(event: event, userId: userId!),
          ),
        );
      },
      child: Container(
        height: 220,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
          image: DecorationImage(
            image: CachedNetworkImageProvider(imageUrl),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            // Dark Overlay
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.6),
                    Colors.black.withOpacity(0.9),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: categoryColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      category,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Title & Subtitle
                  Text(
                    event.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    event.description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Bottom Row (Date, Location, Button)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        dateFormat.format(event.dateTime),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          "|",
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ),
                      
                      const Icon(Icons.location_on_rounded, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.location,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      
                      // Go Button
                      Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Color(0xFF6366F1), // Primary color
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
