import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/rendering.dart';

import 'models/explore_place.dart';
import 'models/place_status.dart';

class ExploreStoryScreen extends StatefulWidget {
  final List<ExplorePlace> places;

  const ExploreStoryScreen({super.key, required this.places});

  @override
  State<ExploreStoryScreen> createState() => _ExploreStoryScreenState();
}

class _ExploreStoryScreenState extends State<ExploreStoryScreen> {
  final GlobalKey _boundaryKey = GlobalKey();

  int _count(ExploreStatus s) =>
      widget.places.where((p) => p.status == s).length;

  Future<void> _share() async {
    try {
      RenderRepaintBoundary boundary =
          _boundaryKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/story.png');
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles([XFile(file.path)]);
    } catch (e) {
      debugPrint("Share error: $e");
    }
  }

  Widget _stat(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        "$value $label",
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Story"),
        actions: [IconButton(icon: const Icon(Icons.share), onPressed: _share)],
      ),
      body: Center(
        child: RepaintBoundary(
          key: _boundaryKey,
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xff6a11cb), Color(0xff2575fc)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "My Explore Story",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                _stat("Visited", _count(ExploreStatus.visited)),
                _stat("Wish", _count(ExploreStatus.wish)),
                _stat("Favorite", _count(ExploreStatus.favorite)),

                const Divider(color: Colors.white),

                ...widget.places.map(
                  (p) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      "${p.name} (${p.status.name})",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
