import 'package:flutter/material.dart';
import 'dashboard_screen.dart';

/// DEPRECATED: AppShell kullanıyoruz.
/// HomeScreen artık bottom nav içermez.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DashboardScreen();
  }
}
