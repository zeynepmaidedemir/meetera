import 'package:flutter/material.dart';
import 'package:meetera/explore/models/place_status.dart';
import 'package:provider/provider.dart';
import 'state/explore_state.dart';
import 'models/explore_place.dart';

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
              'Add at least 2 Wish places to build a route 🧭\n\nTip: Long press on map → Wish',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final route = explore.buildWishRoute();

   return Scaffold(
      appBar: AppBar(
-        title: const Text('Wish Route'),
-        title: const Text('Walking (default)'),
+        title: Column(
+          crossAxisAlignment: CrossAxisAlignment.start,
+          children: const [
+            Text('Wish Route'),
+            Text(
+              'Walking (default)',
+              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
+            ),
+          ],
+        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _header(route),
          const SizedBox(height: 14),
          ..._routeCards(route),
          const SizedBox(height: 18),
          _note(),
        ],
      ),
    );
  }

  Widget _header(List<ExplorePlace> route) {
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
              'Suggested explore order (${route.length} stops)',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _routeCards(List<ExplorePlace> route) {
    final cards = <Widget>[];

    for (int i = 0; i < route.length; i++) {
      final p = route[i];
      final isLast = i == route.length - 1;

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
                child: Text(p.name, style: const TextStyle(fontSize: 15)),
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
      'A discovery path, not navigation.\nWe don’t use your live location yet — this order is based on pins proximity.',
      style: TextStyle(color: Colors.black.withOpacity(0.6)),
      textAlign: TextAlign.center,
    );
  }
}
