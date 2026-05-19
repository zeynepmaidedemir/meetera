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
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: const Text('Wish Route', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.grey.shade50,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.map_outlined, size: 80, color: Colors.blue.shade600),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Start Building Your Route',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Add at least 2 "Wish" pins on the map to automatically generate an optimized walking route.',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600, height: 1.5),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final List<ExplorePlace> route = explore.buildWishRoute();
    final preview = RouteUtils.buildWalkingRoute(route);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Wish Route', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.grey.shade50,
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(route.length, preview),
                  const SizedBox(height: 32),
                  const Text(
                    "Your Journey",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 20),
                  ..._routeTimeline(preview),
                  const SizedBox(height: 32),
                  _note(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(int stops, RoutePreview preview) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF5E35B1), Color(0xFF3949AB)], // Deep Purple to Indigo
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5E35B1).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.directions_walk_rounded, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Route',
                  style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  '${preview.totalDistanceKm.toStringAsFixed(1)} km',
                  style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.schedule, color: Colors.white70, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '~${preview.estimatedMinutes} min',
                      style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.location_on, color: Colors.white70, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '$stops stops',
                      style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _routeTimeline(RoutePreview preview) {
    final cards = <Widget>[];
    final steps = preview.steps;

    for (int i = 0; i < steps.length; i++) {
      final p = steps[i].place;
      final seg = steps[i].distanceKm;
      final isLast = i == steps.length - 1;
      final isFirst = i == 0;

      cards.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Timeline Column
              SizedBox(
                width: 40,
                child: Column(
                  children: [
                    // Top line (empty for first)
                    Expanded(
                      flex: 1,
                      child: Container(
                        width: 3,
                        color: isFirst ? Colors.transparent : Colors.deepPurple.shade200,
                      ),
                    ),
                    // Node
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: isFirst ? Colors.green : (isLast ? Colors.red : Colors.deepPurple),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: (isFirst ? Colors.green : (isLast ? Colors.red : Colors.deepPurple)).withOpacity(0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    // Bottom line (empty for last)
                    Expanded(
                      flex: 5,
                      child: Container(
                        width: 3,
                        color: isLast ? Colors.transparent : Colors.deepPurple.shade200,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              
              // Content Card
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isFirst ? Colors.green.withOpacity(0.1) : (isLast ? Colors.red.withOpacity(0.1) : Colors.deepPurple.withOpacity(0.1)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isFirst ? 'START' : (isLast ? 'DESTINATION' : 'STOP ${i + 1}'),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: isFirst ? Colors.green.shade700 : (isLast ? Colors.red.shade700 : Colors.deepPurple.shade700),
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (!isFirst)
                              Row(
                                children: [
                                  Icon(Icons.directions_walk, size: 14, color: Colors.grey.shade500),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${seg.toStringAsFixed(1)} km',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          p.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return cards;
  }

  Widget _note() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, color: Colors.orange.shade800),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Note: This is an optimized sequence based on proximity, not a turn-by-turn navigation guide.',
              style: TextStyle(color: Colors.orange.shade900, height: 1.4, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
