import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:geocoding/geocoding.dart';

import 'models/explore_place.dart';
import 'models/place_status.dart';
import 'state/explore_state.dart';
import 'explore_wrap_screen.dart';
import 'explore_route_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  static const CameraPosition _initialCamera = CameraPosition(
    target: LatLng(50.0647, 19.9450),
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExploreState>().ensureLoaded();
    });
  }

  // ---------------------
  // 🧠 Human-ish place naming (geocoding limits)
  // ---------------------
  Future<String> _resolvePlaceName(LatLng pos) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );

      if (placemarks.isEmpty) return 'Pinned place';

      final p = placemarks.first;

      // geocoding POI vermez her zaman — insan gibi görünen en iyi alanları seçiyoruz
      final candidates = <String?>[
        p.name,
        p.street,
        p.subLocality,
        p.locality,
        p.administrativeArea,
      ];

      for (final c in candidates) {
        if (_isValidName(c)) return c!.trim();
      }
    } catch (_) {}

    return 'Pinned place';
  }

  bool _isValidName(String? name) {
    if (name == null) return false;
    final t = name.trim();
    if (t.isEmpty) return false;
    if (RegExp(r'^\d+$').hasMatch(t)) return false;
    final low = t.toLowerCase();
    if (low.contains('unnamed') || low.contains('route')) return false;
    if (t.length <= 2) return false;
    return true;
  }

  // ---------------------
  // 📍 Add place
  // ---------------------
  Future<void> _onLongPress(LatLng position) async {
    final explore = context.read<ExploreState>();
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final name = await _resolvePlaceName(position);

    final place = ExplorePlace(
      id: id,
      position: position,
      name: name,
      status: ExploreStatus.wish,
    );

    explore.add(place);
    _openPlaceSheet(place);
  }

  // ---------------------
  // 🧾 Bottom sheet (edit + status)
  // ---------------------
  void _openPlaceSheet(ExplorePlace place) {
    final explore = context.read<ExploreState>();
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
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
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
                onSubmitted: (v) {
                  final name = v.trim();
                  if (name.isEmpty) return;
                  place.name = name;
                  explore.update(place);
                },
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                children: [
                  _chip(
                    place,
                    ExploreStatus.wish,
                    'Wish',
                    Icons.bookmark_border,
                  ),
                  _chip(
                    place,
                    ExploreStatus.favorite,
                    'Favorite',
                    Icons.favorite,
                  ),
                  _chip(
                    place,
                    ExploreStatus.visited,
                    'Visited',
                    Icons.check_circle,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: () {
                  explore.remove(place.id);
                  Navigator.pop(context);
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

  Widget _chip(
    ExplorePlace place,
    ExploreStatus status,
    String label,
    IconData icon,
  ) {
    final explore = context.read<ExploreState>();
    final selected = place.status == status;

    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 16), const SizedBox(width: 6), Text(label)],
      ),
      selected: selected,
      onSelected: (_) {
        place.status = status;
        explore.update(place);
        Navigator.pop(context);
      },
    );
  }

  // ---------------------
  // 🗺️ Markers (mavi / kırmızı / yeşil)
  // ---------------------
  Set<Marker> _markers(List<ExplorePlace> places) {
    return places.map((p) {
      return Marker(
        markerId: MarkerId(p.id),
        position: p.position,
        icon: BitmapDescriptor.defaultMarkerWithHue(_hue(p.status)),
        onTap: () => _openPlaceSheet(p),
      );
    }).toSet();
  }

  double _hue(ExploreStatus status) {
    switch (status) {
      case ExploreStatus.visited:
        return BitmapDescriptor.hueGreen; // ✅ yeşil
      case ExploreStatus.favorite:
        return BitmapDescriptor.hueRose; // ✅ kırmızımsı
      case ExploreStatus.wish:
      default:
        return BitmapDescriptor.hueAzure; // ✅ mavi
    }
  }

  // ---------------------
  // 🎨 Wrap (tek aksiyon)
  // ---------------------
  void _openWrap() {
    final explore = context.read<ExploreState>();
    if (explore.all.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pin at least 1 place first 📍')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ExploreWrapScreen(places: explore.all)),
    );
  }

  // ---------------------
  // 🏆 Badges bottom sheet
  // ---------------------
  void _openBadges() {
    final explore = context.read<ExploreState>();
    final streak = explore.currentStreak;
    final badges = explore.badges;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Explore Streak 🔥  $streak day${streak == 1 ? '' : 's'}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...badges.map((b) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    b.icon,
                    color: b.earned ? Colors.green : Colors.grey,
                  ),
                  title: Text(b.title),
                  subtitle: Text(b.subtitle),
                  trailing: b.earned
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.lock_outline),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _openRoute() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ExploreRouteScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final explore = context.watch<ExploreState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore'),
        actions: [
          IconButton(
            tooltip: 'Wish route',
            icon: const Icon(Icons.route_outlined),
            onPressed: _openRoute,
          ),
          IconButton(
            tooltip: 'Badges',
            icon: const Icon(Icons.emoji_events_outlined),
            onPressed: _openBadges,
          ),
          IconButton(
            tooltip: 'Create wrap',
            icon: const Icon(Icons.auto_awesome),
            onPressed: _openWrap,
          ),
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: _initialCamera,
        markers: _markers(explore.all),
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        onLongPress: _onLongPress,
      ),
    );
  }
}
