import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:geocoding/geocoding.dart';

import 'models/explore_place.dart';
import 'state/explore_state.dart';
import 'explore_wrap_screen.dart';

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

  // ---------------------
  // 🧠 Human place naming
  // ---------------------
  Future<String> _resolvePlaceName(LatLng pos) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );

      if (placemarks.isEmpty) return 'Pinned place';

      final p = placemarks.first;
      final candidates = [p.name, p.street, p.subLocality, p.locality];

      for (final c in candidates) {
        if (_isValidName(c)) return c!;
      }
    } catch (_) {}

    return 'Pinned place';
  }

  bool _isValidName(String? name) {
    if (name == null) return false;
    final t = name.trim().toLowerCase();
    if (t.isEmpty) return false;
    if (RegExp(r'^\d+$').hasMatch(t)) return false;
    if (t.contains('unnamed') || t.contains('route')) return false;
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
  // 🧾 Bottom sheet
  // ---------------------
  void _openPlaceSheet(ExplorePlace place) {
    final explore = context.read<ExploreState>();
    final controller = TextEditingController(text: place.name);

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
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Place name',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (v) {
                  if (v.trim().isEmpty) return;
                  place.name = v.trim();
                  explore.update(place);
                },
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                children: ExploreStatus.values.map((s) {
                  return ChoiceChip(
                    label: Text(s.name),
                    selected: place.status == s,
                    onSelected: (_) {
                      place.status = s;
                      explore.update(place);
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------
  // 🗺️ Markers
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
        return BitmapDescriptor.hueGreen;
      case ExploreStatus.favorite:
        return BitmapDescriptor.hueRose;
      case ExploreStatus.wish:
      default:
        return BitmapDescriptor.hueAzure;
    }
  }

  // ---------------------
  // 🎨 Wrap
  // ---------------------
  void _createWrap() {
    final explore = context.read<ExploreState>();
    final visited = explore.byStatus(ExploreStatus.visited);

    if (visited.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No visited places yet')));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ExploreWrapScreen(all: explore.all)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final explore = context.watch<ExploreState>();

    return Scaffold(
      body: GoogleMap(
        initialCameraPosition: _initialCamera,
        markers: _markers(explore.all),
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        onLongPress: _onLongPress,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: FloatingActionButton.extended(
          icon: const Icon(Icons.auto_awesome),
          label: const Text('Create wrap'),
          onPressed: _createWrap,
        ),
      ),
    );
  }
}
