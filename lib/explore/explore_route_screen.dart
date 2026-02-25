import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'state/explore_state.dart';
import 'models/explore_place.dart';
import 'models/place_status.dart';
import 'utils/route_utils.dart';

class ExploreRouteScreen extends StatelessWidget {
  const ExploreRouteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final explore = context.watch<ExploreState>();
    final wish = explore.byStatus(ExploreStatus.wish);

    if (wish.length < 2) {
      return Scaffold(
        appBar: AppBar(title: const Text('Wish Route')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Route için en az 2 adet WISH pin lazım 🧭\n\nMap’te long press → WISH seç.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final List<ExplorePlace> route = explore.buildWishRoute();
    final preview = RouteUtils.buildWalkingRoute(route);

    return Scaffold(
      appBar: AppBar(title: const Text('Wish Route')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _header(route.length, preview),
          const SizedBox(height: 14),
          ..._routeCards(preview),
          const SizedBox(height: 18),
          _note(),
        ],
      ),
    );
  }

  Widget _header(int stops, RoutePreview preview) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.black.withOpacity(0.04),
      ),
      child: Row(
        children: [
          const Icon(Icons.route_outlined),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Stops: $stops\n'
              'Distance: ${preview.totalDistanceKm.toStringAsFixed(2)} km\n'
              'Walking: ${preview.estimatedMinutes} min',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _routeCards(RoutePreview preview) {
    final cards = <Widget>[];
    final steps = preview.steps;

    for (int i = 0; i < steps.length; i++) {
      final p = steps[i].place;
      final seg = steps[i].distanceKm;
      final isLast = i == steps.length - 1;

      cards.add(
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black.withOpacity(0.08)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(radius: 14, child: Text('${i + 1}')),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                      i == 0 ? "Start" : "+ ${seg.toStringAsFixed(2)} km",
                      style: TextStyle(
                          color: Colors.black.withOpacity(0.6), fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (!isLast) const Icon(Icons.arrow_downward_rounded),
            ],
          ),
        ),
      );
    }

    return cards;
  }

  Widget _note() {
    return Text(
      'Bu “story planı” — navigasyon değil.\nSadece pin’lerin birbirine yakınlığına göre sıralanır.',
      style: TextStyle(color: Colors.black.withOpacity(0.6)),
      textAlign: TextAlign.center,
    );
  }
}
