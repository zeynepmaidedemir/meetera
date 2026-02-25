import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'state/explore_state.dart';
import 'models/place_status.dart';

class ExploreWrapScreen extends StatefulWidget {
  const ExploreWrapScreen({super.key});

  @override
  State<ExploreWrapScreen> createState() => _ExploreWrapScreenState();
}

class _ExploreWrapScreenState extends State<ExploreWrapScreen> {
  String theme = "neon";
  final GlobalKey _wrapKey = GlobalKey();
  bool _exporting = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ExploreState>();

    final visited = state.byStatus(ExploreStatus.visited);
    final wish = state.byStatus(ExploreStatus.wish);
    final favorite = state.byStatus(ExploreStatus.favorite);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Explore Wrap"),
        actions: [
          IconButton(
            icon: _exporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.share),
            onPressed: _exporting ? null : _shareWrap,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _themeSelector(),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: RepaintBoundary(
                  key: _wrapKey,
                  child: _wrapCard(
                    visited: visited.length,
                    wish: wish.length,
                    favorite: favorite.length,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareWrap() async {
    setState(() => _exporting = true);
    try {
      final boundary =
          _wrapKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/meetera_wrap.png');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles([XFile(file.path)],
          text: "Exploring with MeetEra 🌍");
    } catch (e) {
      debugPrint("Share error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Wrap export failed")),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Widget _themeSelector() {
    final themes = ["Sunset", "Neon", "Paper"];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: themes.map((t) {
        final selected = theme.toLowerCase() == t.toLowerCase();
        return ChoiceChip(
          label: Text(t),
          selected: selected,
          onSelected: (_) => setState(() => theme = t.toLowerCase()),
        );
      }).toList(),
    );
  }

  Widget _wrapCard({
    required int visited,
    required int wish,
    required int favorite,
  }) {
    final colors = theme == "sunset"
        ? [Colors.orange, Colors.pink]
        : theme == "paper"
            ? [Colors.grey.shade200, Colors.white]
            : [
                const Color(0xff1f005c),
                const Color(0xff5b0060),
                const Color(0xff870160),
              ];

    final isPaper = theme == "paper";

    final fg = isPaper ? Colors.black : Colors.white;
    final muted = isPaper ? Colors.black54 : Colors.white70;

    return Container(
      width: 320,
      height: 480, // 🔥 daha kısa, story vibe
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "MeetEra 2026 🌍",
            style: TextStyle(
              color: muted,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "$visited",
            style: TextStyle(
              color: fg,
              fontSize: 60,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            "Places Visited",
            style: TextStyle(
              color: muted,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: isPaper
                  ? Colors.black.withOpacity(0.05)
                  : Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                _miniStat("❤️ Favorites", favorite, muted),
                const SizedBox(height: 6),
                _miniStat("🧭 Wish", wish, muted),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Text(
            "Created with MeetEra ✨",
            style: TextStyle(
              color: muted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, int value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: color)),
        Text(
          "$value",
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
