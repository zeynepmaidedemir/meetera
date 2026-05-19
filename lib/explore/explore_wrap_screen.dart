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
    final streak = state.currentStreak;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Your MeetEra Wrap", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: _exporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.ios_share, color: Colors.white),
            onPressed: _exporting ? null : _shareWrap,
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            _themeSelector(),
            const SizedBox(height: 20),
            Expanded(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: RepaintBoundary(
                    key: _wrapKey,
                    child: _wrapCard(
                      visited: visited.length,
                      wish: wish.length,
                      favorite: favorite.length,
                      streak: streak,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Share your journey to your story!",
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
            ),
            const SizedBox(height: 20),
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
      // High pixel ratio for crystal clear image export
      final image = await boundary.toImage(pixelRatio: 4);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/meetera_wrap.png');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles([XFile(file.path)],
          text: "My 2026 Exploring Journey with MeetEra 🌍");
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
    final themes = ["Neon", "Sunset", "Paper"];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: themes.map((t) {
            final selected = theme.toLowerCase() == t.toLowerCase();
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => theme = t.toLowerCase()),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: selected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Center(
                    child: Text(
                      t,
                      style: TextStyle(
                        color: selected ? Colors.black : Colors.white70,
                        fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _wrapCard({
    required int visited,
    required int wish,
    required int favorite,
    required int streak,
  }) {
    // Determine colors
    List<Color> gradientColors;
    Color fg;
    Color fgMuted;
    Color pillBg;

    if (theme == "sunset") {
      gradientColors = [const Color(0xFFFF512F), const Color(0xFFDD2476)];
      fg = Colors.white;
      fgMuted = Colors.white.withOpacity(0.8);
      pillBg = Colors.black.withOpacity(0.2);
    } else if (theme == "paper") {
      gradientColors = [const Color(0xFFFDFBFB), const Color(0xFFEBEDEE)];
      fg = const Color(0xFF111111);
      fgMuted = const Color(0xFF666666);
      pillBg = Colors.black.withOpacity(0.05);
    } else {
      // Neon
      gradientColors = [const Color(0xFF0F2027), const Color(0xFF203A43), const Color(0xFF2C5364)];
      fg = Colors.white;
      fgMuted = Colors.white.withOpacity(0.7);
      pillBg = Colors.white.withOpacity(0.1);
    }

    return Container(
      width: 320,
      height: 568, // 9:16 aspect ratio base (e.g., iPhone size ratio)
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Background abstract element for neon/sunset
          if (theme == "neon" || theme == "sunset")
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Row(
                children: [
                  Icon(Icons.auto_awesome, color: theme == 'neon' ? Colors.cyanAccent : fg, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    "MY JOURNEY",
                    style: TextStyle(
                      color: fg,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              const Spacer(flex: 2),
              
              // MAIN STAT
              Text(
                "You explored",
                style: TextStyle(
                  color: fgMuted,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                "$visited",
                style: TextStyle(
                  color: fg,
                  fontSize: 86,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                  letterSpacing: -2,
                ),
              ),
              Text(
                "new places.",
                style: TextStyle(
                  color: fg,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
              ),
              
              const Spacer(flex: 2),

              // STREAK
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: pillBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: fg.withOpacity(0.1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("🔥", style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "$streak Day Streak",
                          style: TextStyle(color: fg, fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                        Text(
                          "Unstoppable explorer!",
                          style: TextStyle(color: fgMuted, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // SUB STATS
              Row(
                children: [
                  Expanded(
                    child: _miniStatPill("❤️ Loved", "$favorite", fg, fgMuted, pillBg),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _miniStatPill("🧭 Wishlist", "$wish", fg, fgMuted, pillBg),
                  ),
                ],
              ),
              
              const Spacer(flex: 3),
              
              // FOOTER
              Center(
                child: Column(
                  children: [
                    Text(
                      "MeetEra 2026",
                      style: TextStyle(
                        color: fg,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "@meetera.app",
                      style: TextStyle(
                        color: fgMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStatPill(String label, String value, Color fg, Color fgMuted, Color pillBg) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: pillBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: fg.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: fgMuted, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(color: fg, fontSize: 22, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
