import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'services/version_control_service.dart';

// AI
import 'ai/ai_chat_list_screen.dart';

// Screens
import 'screens/dashboard_screen.dart';
import 'screens/buddy_screen.dart';
import 'screens/community_screen.dart';
import 'screens/events_screen.dart';
import 'explore/explore_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/marketplace_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;
  Offset? aiOffset;
  
  bool _isSoftUpdateAlerted = false;
  VersionControlResult? _hardUpdateResult;

  @override
  void initState() {
    super.initState();
    _checkVersion();
  }

  Future<void> _checkVersion() async {
    final result = await VersionControlService().checkVersion();
    if (!mounted) return;

    if (result.status == VersionStatus.hardUpdate) {
      setState(() {
        _hardUpdateResult = result;
      });
    } else if (result.status == VersionStatus.softUpdate && !_isSoftUpdateAlerted) {
      _isSoftUpdateAlerted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSoftUpdateDialog(result);
      });
    }
  }

  void _showSoftUpdateDialog(VersionControlResult result) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          elevation: 16,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.celebration_rounded,
                    size: 40,
                    color: Color(0xFF6366F1),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "New Version Available! 🎉",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "A new version of the app (v${result.latestVersion}) is available. Update now to get the latest features!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          "Later",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final uri = Uri.parse(result.storeUrl);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          "Update",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigate(int newIndex) {
    setState(() {
      index = newIndex;
    });
  }

  late final List<Widget> screens = [
    DashboardScreen(onNavigate: _navigate),
    const BuddyScreen(),
    const CommunityScreen(),
    const ExploreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    if (_hardUpdateResult != null) {
      return _buildHardUpdateScreen(_hardUpdateResult!);
    }

    final size = MediaQuery.of(context).size;
    aiOffset ??= Offset(16, size.height - 240); // Adjusted for new nav bar

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          screens[index],

          // 🤖 DRAGGABLE AI
          Positioned(
            left: aiOffset!.dx,
            top: aiOffset!.dy,
            child: Draggable(
              feedback: _buildAiFab(),
              childWhenDragging: const SizedBox.shrink(),
              onDragEnd: (details) {
                setState(() {
                  final dx = details.offset.dx.clamp(0.0, size.width - 72);
                  final dy = details.offset.dy.clamp(0.0, size.height - 160);
                  aiOffset = Offset(dx, dy);
                });
              },
              child: _buildAiFab(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(0.15),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(0, Icons.home_rounded, Icons.home_outlined),
              _buildNavItem(1, Icons.people_rounded, Icons.people_outline),
              _buildNavItem(2, Icons.forum_rounded, Icons.forum_outlined),
              _buildNavItem(3, Icons.explore_rounded, Icons.explore_outlined),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int itemIndex, IconData activeIcon, IconData inactiveIcon) {
    final isSelected = index == itemIndex;
    return GestureDetector(
      onTap: () => setState(() => index = itemIndex),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 20 : 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1).withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          isSelected ? activeIcon : inactiveIcon,
          color: isSelected ? const Color(0xFF6366F1) : Colors.grey.shade400,
          size: isSelected ? 28 : 24,
        ),
      ),
    );
  }

  Widget _buildAiFab() {
    return FloatingActionButton(
      heroTag: 'ai_fab',
      child: const Icon(Icons.smart_toy_outlined),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AiChatListScreen()),
        );
      },
    );
  }

  Widget _buildHardUpdateScreen(VersionControlResult result) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1E1B4B), // Very deep indigo
              const Color(0xFF311042), // Deep violet
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF6366F1).withOpacity(0.4),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.2),
                        blurRadius: 40,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.system_update_rounded,
                    size: 78,
                    color: Color(0xFF818CF8),
                  ),
                ),
                const SizedBox(height: 48),
                const Text(
                  "Update Required",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "A critical update is required to continue using the application. Please download the latest version.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withOpacity(0.7),
                    height: 1.5,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: () async {
                      final uri = Uri.parse(result.storeUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1E1B4B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 8,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.download_rounded, size: 22),
                        SizedBox(width: 10),
                        Text(
                          "Update Now",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
