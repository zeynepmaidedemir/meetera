import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/buddy_state.dart';
import '../state/app_state.dart';
import '../models/user_model.dart';
import 'buddy_card.dart';

class BuddyScreen extends StatefulWidget {
  const BuddyScreen({super.key});

  @override
  State<BuddyScreen> createState() => _BuddyScreenState();
}

class _BuddyScreenState extends State<BuddyScreen> {
  String? _currentCityId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appState = Provider.of<AppState>(context, listen: true);
    final cityId = appState.cityId;
    if (cityId != null && cityId.isNotEmpty && cityId != _currentCityId) {
      _currentCityId = cityId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<BuddyState>().loadUsersByCity(cityId);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "Buddies in ${appState.city ?? ''}",
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
          ),
          centerTitle: true,
          bottom: const TabBar(
            labelColor: Color(0xFF6366F1),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF6366F1),
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            tabs: [
              Tab(text: "Discover"),
              Tab(text: "Connections"),
              Tab(text: "Requests"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            DiscoverTab(),
            ConnectionsTab(),
            RequestsTab(),
          ],
        ),
      ),
    );
  }
}

/// 🌟 DISCOVER TAB: Users in the city that have NO active requests/connections
class DiscoverTab extends StatelessWidget {
  const DiscoverTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<BuddyState>();
    final appState = context.watch<AppState>();

    if (state.isLoadingUsers) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF6366F1),
        ),
      );
    }

    if (state.users.isEmpty) {
      return _buildEmptyState(
        context,
        icon: Icons.explore_outlined,
        title: "No buddies around",
        subtitle: "No buddies found in this city yet. Try changing your search or check back later!",
      );
    }

    final connectedIds = state.connectedIds;
    final incomingIds = state.incomingRequestIds;
    final sentIds = state.sentRequestIds;
    final blockedIds = state.blockedIds;

    // Filter out connected, incoming, sent, blocked users
    final filteredUsers = state.users.where((u) {
      return !connectedIds.contains(u.uid) &&
          !incomingIds.contains(u.uid) &&
          !sentIds.contains(u.uid) &&
          !blockedIds.contains(u.uid);
    }).toList();

    if (filteredUsers.isEmpty) {
      return _buildEmptyState(
        context,
        icon: Icons.check_circle_outline_rounded,
        title: "You are all caught up!",
        subtitle: "You have connected or sent requests to all buddies in this city. Great job!",
      );
    }

    // Sort by Match %
    filteredUsers.sort((a, b) {
      final pA = state.matchPercent(
        myInterests: appState.interests.toList(),
        otherInterests: a.interests,
      );
      final pB = state.matchPercent(
        myInterests: appState.interests.toList(),
        otherInterests: b.interests,
      );
      return pB.compareTo(pA);
    });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredUsers.length,
      itemBuilder: (_, i) {
        return BuddyCard(buddy: filteredUsers[i], isConnected: false);
      },
    );
  }
}

/// 🌟 CONNECTIONS TAB: Active friends
class ConnectionsTab extends StatelessWidget {
  const ConnectionsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<BuddyState>();
    final appState = context.watch<AppState>();

    if (state.isLoadingUsers) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF6366F1),
        ),
      );
    }

    final connectedIds = state.connectedIds;
    final connectedUsers = state.users.where((u) => connectedIds.contains(u.uid)).toList();

    if (connectedUsers.isEmpty) {
      return _buildEmptyState(
        context,
        icon: Icons.people_outline_rounded,
        title: "No connections yet",
        subtitle: "Go to the Discover tab to meet like-minded travelers and send them a connection request!",
      );
    }

    // Sort by match %
    connectedUsers.sort((a, b) {
      final pA = state.matchPercent(
        myInterests: appState.interests.toList(),
        otherInterests: a.interests,
      );
      final pB = state.matchPercent(
        myInterests: appState.interests.toList(),
        otherInterests: b.interests,
      );
      return pB.compareTo(pA);
    });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: connectedUsers.length,
      itemBuilder: (_, i) {
        return BuddyCard(buddy: connectedUsers[i], isConnected: true);
      },
    );
  }
}

/// 🌟 REQUESTS TAB: Incoming, Sent Requests, and Blocked Users
class RequestsTab extends StatelessWidget {
  const RequestsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<BuddyState>();

    if (state.isLoadingUsers) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF6366F1),
        ),
      );
    }

    final incomingIds = state.incomingRequestIds;
    final sentIds = state.sentRequestIds;

    final incomingUsers = state.users.where((u) => incomingIds.contains(u.uid)).toList();
    final sentUsers = state.users.where((u) => sentIds.contains(u.uid)).toList();

    return StreamBuilder<List<UserModel>>(
      stream: state.blockedUsersStream,
      builder: (context, snapshot) {
        final blockedUsers = snapshot.data ?? [];

        if (incomingUsers.isEmpty && sentUsers.isEmpty && blockedUsers.isEmpty) {
          return _buildEmptyState(
            context,
            icon: Icons.mail_outline_rounded,
            title: "Inbox clean",
            subtitle: "You have no incoming, outgoing pending requests, or blocked users.",
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (incomingUsers.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.only(left: 8, bottom: 12),
                child: Text(
                  "Incoming Requests",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.2),
                ),
              ),
              ...incomingUsers.map((u) => BuddyCard(buddy: u, isConnected: false)),
              const SizedBox(height: 24),
            ],
            if (sentUsers.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.only(left: 8, bottom: 12),
                child: Text(
                  "Sent Requests",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.2),
                ),
              ),
              ...sentUsers.map((u) => BuddyCard(buddy: u, isConnected: false)),
              const SizedBox(height: 24),
            ],
            if (blockedUsers.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.only(left: 8, bottom: 12),
                child: Text(
                  "Blocked Users",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.2, color: Colors.redAccent),
                ),
              ),
              ...blockedUsers.map((u) => BuddyCard(buddy: u, isConnected: false)),
            ],
          ],
        );
      },
    );
  }
}

Widget _buildEmptyState(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String subtitle,
}) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 54,
              color: const Color(0xFF6366F1),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
