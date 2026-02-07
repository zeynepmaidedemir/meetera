import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'models/explore_place.dart';
import 'models/place_status.dart';

enum WrapThemeStyle { sunset, neon, paper }

class ExploreWrapScreen extends StatefulWidget {
  final List<ExplorePlace> places;

  const ExploreWrapScreen({super.key, required this.places});

  @override
  State<ExploreWrapScreen> createState() => _ExploreWrapScreenState();
}

class _ExploreWrapScreenState extends State<ExploreWrapScreen> {
  final GlobalKey _wrapKey = GlobalKey();
  WrapThemeStyle _theme = WrapThemeStyle.sunset;
  bool _exporting = false;

  List<ExplorePlace> _by(ExploreStatus s) =>
      widget.places.where((p) => p.status == s).toList();

  int get _visitedCount => _by(ExploreStatus.visited).length;
  int get _wishCount => _by(ExploreStatus.wish).length;
  int get _favCount => _by(ExploreStatus.favorite).length;

  // -----------------------
  // 📤 Export + share (story)
  // -----------------------
  Future<void> _addToStory() async {
    if (_exporting) return;

    setState(() => _exporting = true);
    try {
      final boundary =
          _wrapKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/meetera_story_wrap.png');
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Exploring with MeetEra 🌍');
    } catch (e) {
      debugPrint('Export error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not export wrap')));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  // -----------------------
  // 🎨 Theme data
  // -----------------------
  LinearGradient _bg() {
    switch (_theme) {
      case WrapThemeStyle.neon:
        return const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case WrapThemeStyle.paper:
        return const LinearGradient(
          colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case WrapThemeStyle.sunset:
      default:
        return const LinearGradient(
          colors: [Color(0xFFFF6B6B), Color(0xFFFFD93D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  Color _fg() => _theme == WrapThemeStyle.paper ? Colors.black : Colors.white;
  Color _muted() =>
      _theme == WrapThemeStyle.paper ? Colors.black54 : Colors.white70;

  Color _chipBg() =>
      _theme == WrapThemeStyle.paper ? Colors.white : Colors.white24;

  @override
  Widget build(BuildContext context) {
    final visited = _by(ExploreStatus.visited);
    final wish = _by(ExploreStatus.wish);
    final fav = _by(ExploreStatus.favorite);

    return Scaffold(
      appBar: AppBar(title: const Text('Explore Wrap')),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),

            // ✅ Theme selector (labels ALWAYS visible)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _ThemePills(
                value: _theme,
                onChanged: (v) => setState(() => _theme = v),
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 9 / 16,
                  child: RepaintBoundary(
                    key: _wrapKey,
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: _bg(),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 18,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: _WrapCard(
                        fg: _fg(),
                        muted: _muted(),
                        chipBg: _chipBg(),
                        visitedCount: _visitedCount,
                        wishCount: _wishCount,
                        favCount: _favCount,
                        visited: visited,
                        wish: wish,
                        fav: fav,
                        theme: _theme,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ✅ only ONE CTA
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _exporting ? null : _addToStory,
                  icon: _exporting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_to_photos_outlined),
                  label: const Text('Add to story'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemePills extends StatelessWidget {
  final WrapThemeStyle value;
  final ValueChanged<WrapThemeStyle> onChanged;

  const _ThemePills({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget pill(WrapThemeStyle v, String text) {
      final selected = v == value;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(v),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? Colors.black : Colors.black.withOpacity(0.06),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected ? Colors.black : Colors.black.withOpacity(0.08),
              ),
            ),
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        pill(WrapThemeStyle.sunset, 'Sunset'),
        const SizedBox(width: 10),
        pill(WrapThemeStyle.neon, 'Neon'),
        const SizedBox(width: 10),
        pill(WrapThemeStyle.paper, 'Paper'),
      ],
    );
  }
}

class _WrapCard extends StatelessWidget {
  final Color fg;
  final Color muted;
  final Color chipBg;

  final int visitedCount;
  final int wishCount;
  final int favCount;

  final List<ExplorePlace> visited;
  final List<ExplorePlace> wish;
  final List<ExplorePlace> fav;

  final WrapThemeStyle theme;

  const _WrapCard({
    required this.fg,
    required this.muted,
    required this.chipBg,
    required this.visitedCount,
    required this.wishCount,
    required this.favCount,
    required this.visited,
    required this.wish,
    required this.fav,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Text(
          'Exploring with MeetEra 🌍',
          style: TextStyle(
            color: fg,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Your monthly moments — pinned by you.',
          style: TextStyle(color: muted, fontSize: 13),
        ),
        const SizedBox(height: 12),

        // Counters row
        Row(
          children: [
            _miniStat('Visited', visitedCount, Icons.check_circle, fg, chipBg),
            const SizedBox(width: 10),
            _miniStat('Wish', wishCount, Icons.bookmark, fg, chipBg),
            const SizedBox(width: 10),
            _miniStat('Fav', favCount, Icons.favorite, fg, chipBg),
          ],
        ),

        const SizedBox(height: 14),

        // Lists
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: chipBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                _section('✅ Visited', visited, fg, muted),
                const SizedBox(height: 10),
                _section('💗 Favorite', fav, fg, muted),
                const SizedBox(height: 10),
                _section('🧭 Wish', wish, fg, muted),
                const SizedBox(height: 14),
                Center(
                  child: Text(
                    'Created with MeetEra ✨',
                    style: TextStyle(color: muted, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Widget _miniStat(
    String label,
    int value,
    IconData icon,
    Color fg,
    Color bg,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(icon, color: fg, size: 18),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$value',
                  style: TextStyle(
                    color: fg,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(color: fg.withOpacity(0.75), fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _section(
    String title,
    List<ExplorePlace> items,
    Color fg,
    Color muted,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: fg,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Text('—', style: TextStyle(color: muted))
        else
          ...items.take(10).map((p) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                '• ${p.name}',
                style: TextStyle(color: fg, fontSize: 13, height: 1.2),
              ),
            );
          }),
      ],
    );
  }
}
