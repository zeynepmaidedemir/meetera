import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

import 'models/explore_place.dart';

class ExploreWrapScreen extends StatelessWidget {
  final List<ExplorePlace> all;

  ExploreWrapScreen({super.key, required this.all});

  final GlobalKey _key = GlobalKey();

  Future<void> _share() async {
    final boundary =
        _key.currentContext!.findRenderObject() as RenderRepaintBoundary;

    final image = await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = data!.buffer.asUint8List();

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/explore_wrap.png');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles([
      XFile(file.path),
    ], text: 'My MeetEra Explore Wrap ✨');
  }

  @override
  Widget build(BuildContext context) {
    final visited = all
        .where((p) => p.status == ExploreStatus.visited)
        .toList();
    final wish = all.where((p) => p.status == ExploreStatus.wish).toList();
    final fav = all.where((p) => p.status == ExploreStatus.favorite).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore Wrap'),
        actions: [IconButton(icon: const Icon(Icons.share), onPressed: _share)],
      ),
      body: Center(
        child: RepaintBoundary(
          key: _key,
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.deepPurple, Colors.blueAccent],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'My Explore ✨',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _stat('Visited', visited.length),
                    _stat('Wish', wish.length),
                    _stat('Fav', fav.length),
                  ],
                ),
                const SizedBox(height: 16),
                ...visited.map(
                  (p) => Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          p.name,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Created with MeetEra 🌍',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stat(String label, int count) {
    return Column(
      children: [
        Text(
          '$count',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}
