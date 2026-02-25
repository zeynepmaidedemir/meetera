import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'state/explore_state.dart';
import 'models/place_status.dart';

class ExploreStoryScreen extends StatefulWidget {
  const ExploreStoryScreen({super.key});

  @override
  State<ExploreStoryScreen> createState() => _ExploreStoryScreenState();
}

class _ExploreStoryScreenState extends State<ExploreStoryScreen> {
  final _page = PageController();

  @override
  Widget build(BuildContext context) {
    final explore = context.watch<ExploreState>();
    final visited = explore.byStatus(ExploreStatus.visited);

    return Scaffold(
      appBar: AppBar(title: const Text("Discover Story")),
      body: visited.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  "Henüz VISITED yok.\nMap’te long press → pin\nSonra pini aç → Visited ✅",
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : PageView.builder(
              controller: _page,
              itemCount: visited.length,
              itemBuilder: (_, i) {
                final p = visited[i];
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.black.withOpacity(0.06),
                          Colors.black.withOpacity(0.02),
                        ],
                      ),
                      border: Border.all(color: Colors.black.withOpacity(0.08)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Story ${i + 1}/${visited.length}",
                            style: TextStyle(
                              color: Colors.black.withOpacity(0.6),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            p.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "VISITED ✅\n\nLat: ${p.position.latitude.toStringAsFixed(5)}\nLng: ${p.position.longitude.toStringAsFixed(5)}",
                            style: TextStyle(
                              color: Colors.black.withOpacity(0.75),
                            ),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton(
                                  onPressed: () {
                                    if (i < visited.length - 1) {
                                      _page.nextPage(
                                        duration:
                                            const Duration(milliseconds: 250),
                                        curve: Curves.easeOut,
                                      );
                                    }
                                  },
                                  child: const Text("Next"),
                                ),
                              ),
                            ],
                          )
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
