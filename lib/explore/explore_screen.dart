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
                const Text("No badges earned yet 😅")
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

    final controller = TextEditingController(text: name);

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
              const SizedBox(height: 6),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 20),
              
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'Location Name (Editable)',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text("Select a status to save",
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  _statusBox("Visited", Colors.green, ExploreStatus.visited,
                      latLng, controller),
                  const SizedBox(width: 12),
                  _statusBox(
                      "Wish", Colors.blue, ExploreStatus.wish, latLng, controller),
                  const SizedBox(width: 12),
                  _statusBox("Favorite", Colors.pink, ExploreStatus.favorite,
                      latLng, controller),
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
    TextEditingController controller,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () async {
          Navigator.pop(context);

          final finalName = controller.text.trim().isNotEmpty ? controller.text.trim() : "Pinned place";

          final place = ExplorePlace(
            id: const Uuid().v4(),
            position: latLng,
            name: finalName,
            status: status,
          );

          await context.read<ExploreState>().add(place);

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Pin added successfully!"),
              backgroundColor: color,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 2),
            ),
          );
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
      final parts = <String>[];

      if (p.street != null && p.street!.trim().isNotEmpty) {
        parts.add(p.street!.trim());
      } else if (p.name != null && p.name!.trim().isNotEmpty) {
        parts.add(p.name!.trim());
      }

      if (p.subLocality != null && p.subLocality!.trim().isNotEmpty) {
        parts.add(p.subLocality!.trim());
      } else if (p.locality != null && p.locality!.trim().isNotEmpty) {
        parts.add(p.locality!.trim());
      }

      if (parts.isNotEmpty) {
        return parts.join(', ');
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
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'Place name',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.deepPurple),
                    onPressed: () async {
                      final newName = controller.text.trim();
                      if (newName.isNotEmpty) {
                        place.name = newName;
                        await context.read<ExploreState>().update(place);
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Name updated!"),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
                onSubmitted: (v) async {
                  place.name = v.trim().isEmpty ? place.name : v.trim();
                  await context.read<ExploreState>().update(place);
                  if (mounted) {
                    Navigator.pop(context);
                  }
                },
              ),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Change Status",
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _editStatusBox("Visited", Colors.green, ExploreStatus.visited, place, controller),
                  const SizedBox(width: 12),
                  _editStatusBox("Wish", Colors.blue, ExploreStatus.wish, place, controller),
                  const SizedBox(width: 12),
                  _editStatusBox("Favorite", Colors.pink, ExploreStatus.favorite, place, controller),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await context.read<ExploreState>().remove(place.id);
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Pin removed."),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  label: const Text(
                    'Remove Pin',
                    style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _editStatusBox(
    String label,
    Color color,
    ExploreStatus status,
    ExplorePlace place,
    TextEditingController controller,
  ) {
    final isSelected = place.status == status;
    return Expanded(
      child: GestureDetector(
        onTap: () async {
          if (isSelected) return;
          
          // Also save any typed name
          final newName = controller.text.trim();
          if (newName.isNotEmpty && newName != place.name) {
            place.name = newName;
          }
          
          place.status = status;
          await context.read<ExploreState>().update(place);
          if (mounted) Navigator.pop(context);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.grey.shade500,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
