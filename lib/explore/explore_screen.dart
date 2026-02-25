import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:geocoding/geocoding.dart';

import 'state/explore_state.dart';
import 'models/place_status.dart';
import 'models/explore_place.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExploreState>().startListening();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ExploreState>();

    final earned = state.consumeNewBadge();
    if (earned != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("🎉 Badge: $earned"),
            backgroundColor: Colors.deepPurple,
          ),
        );
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Explore"),
        actions: [
          IconButton(
            tooltip: "Badges",
            icon: const Icon(Icons.emoji_events_outlined),
            onPressed: _openBadges,
          ),
          IconButton(
            tooltip: "Wish Route",
            icon: const Icon(Icons.route_outlined),
            onPressed: () => Navigator.pushNamed(context, "/exploreRoute"),
          ),
          IconButton(
            tooltip: "Wrap",
            icon: const Icon(Icons.auto_awesome),
            onPressed: () => Navigator.pushNamed(context, "/exploreWrap"),
          ),
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: LatLng(50.0647, 19.9450),
          zoom: 12,
        ),
        markers: _markers(state),
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        onLongPress: (pos) => _openStatusSelector(pos),
      ),
    );
  }

  void _openBadges() {
    final state = context.read<ExploreState>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Badges • Streak ${state.currentStreak} 🔥",
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              if (state.badges.isEmpty)
                const Text("Henüz rozet yok 😅")
              else
                ...state.badges.map((b) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.workspace_premium),
                      title: Text(b),
                    )),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openStatusSelector(LatLng latLng) async {
    final name = await _resolvePlaceName(latLng);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 6),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 14),
              const Text("Select status",
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 14),

              // ✅ 3 dikdörtgen
              Row(
                children: [
                  _statusBox("Visited", Colors.green, ExploreStatus.visited,
                      latLng, name),
                  const SizedBox(width: 12),
                  _statusBox(
                      "Wish", Colors.blue, ExploreStatus.wish, latLng, name),
                  const SizedBox(width: 12),
                  _statusBox("Favorite", Colors.pink, ExploreStatus.favorite,
                      latLng, name),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _statusBox(
    String label,
    Color color,
    ExploreStatus status,
    LatLng latLng,
    String resolvedName,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () async {
          Navigator.pop(context);

          final place = ExplorePlace(
            id: const Uuid().v4(),
            position: latLng,
            name: resolvedName,
            status: status,
          );

          await context.read<ExploreState>().add(place);

          if (!mounted) return;
          _openEditSheet(place);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ),
    );
  }

  Set<Marker> _markers(ExploreState state) {
    return state.all.map((p) {
      return Marker(
        markerId: MarkerId(p.id),
        position: p.position,
        icon: BitmapDescriptor.defaultMarkerWithHue(_hue(p.status)),
        onTap: () => _openEditSheet(p),
      );
    }).toSet();
  }

  double _hue(ExploreStatus status) {
    switch (status) {
      case ExploreStatus.visited:
        return BitmapDescriptor.hueGreen;
      case ExploreStatus.favorite:
        return BitmapDescriptor.hueRose;
      case ExploreStatus.wish:
      default:
        return BitmapDescriptor.hueAzure;
    }
  }

  Future<String> _resolvePlaceName(LatLng pos) async {
    try {
      final placemarks =
          await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isEmpty) return "Pinned place";

      final p = placemarks.first;
      final candidates = [p.name, p.street, p.subLocality, p.locality];
      for (final c in candidates) {
        if (c != null && c.trim().isNotEmpty) return c.trim();
      }
    } catch (_) {}
    return "Pinned place";
  }

  void _openEditSheet(ExplorePlace place) {
    final controller = TextEditingController(text: place.name);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 18,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Place name',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (v) async {
                  place.name = v.trim().isEmpty ? place.name : v.trim();
                  await context.read<ExploreState>().update(place);
                },
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                children: ExploreStatus.values.map((s) {
                  return ChoiceChip(
                    label: Text(s.name),
                    selected: place.status == s,
                    onSelected: (_) async {
                      place.status = s;
                      await context.read<ExploreState>().update(place);
                      if (mounted) Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: () async {
                  await context.read<ExploreState>().remove(place.id);
                  if (mounted) Navigator.pop(context);
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text('Remove pin'),
              ),
            ],
          ),
        );
      },
    );
  }
}
