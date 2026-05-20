import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:rxdart/rxdart.dart';

import '../models/user_model.dart';
import '../services/connection_service.dart';

enum ConnectionStatus { none, sent, received, connected, blocked }

class BuddyState extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConnectionService _connectionService = ConnectionService();

  List<UserModel> _users = [];
  List<UserModel> get users => _users;

  // Cache lists to prevent multiple heavy Firestore stream builders
  List<String> _connectedIds = [];
  List<String> _incomingRequestIds = [];
  List<String> _sentRequestIds = [];
  List<String> _blockedIds = [];
  bool _isLoadingUsers = false;

  List<String> get connectedIds => _connectedIds;
  List<String> get incomingRequestIds => _incomingRequestIds;
  List<String> get sentRequestIds => _sentRequestIds;
  List<String> get blockedIds => _blockedIds;
  bool get isLoadingUsers => _isLoadingUsers;

  String? get _me => FirebaseAuth.instance.currentUser?.uid;
  StreamSubscription? _usersSub;
  StreamSubscription? _connectionsSub;
  StreamSubscription? _incomingSub;
  StreamSubscription? _sentSub;
  StreamSubscription? _blockedSub;

  BuddyState() {
    String? lastUid;
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null) {
        lastUid = null;
        cancelSocialSubs();
      } else if (user.uid != lastUid) {
        lastUid = user.uid;
        cancelSocialSubs();
        _initSocialSubs(user.uid);
      }
    });
  }

  void loadUsersByCity(String cityId) {
    final me = _me;
    if (me == null) return;

    _isLoadingUsers = true;
    notifyListeners();

    _usersSub?.cancel();
    _usersSub = _firestore
        .collection('users')
        .where('cityId', isEqualTo: cityId)
        .snapshots()
        .listen((snapshot) {
      _users = snapshot.docs
          .where((doc) => doc.id != me)
          .map((doc) => UserModel.fromFirestore(doc.id, doc.data()))
          .toList();
      _isLoadingUsers = false;
      notifyListeners();
    }, onError: (e) {
      _isLoadingUsers = false;
      notifyListeners();
    });

    _initSocialSubs(me);
  }

  void _initSocialSubs([String? uid]) {
    final me = uid ?? _me;
    if (me == null) return;

    if (_connectionsSub != null) return; // Already listening

    _connectionsSub = _firestore
        .collection('connections')
        .where('users', arrayContains: me)
        .snapshots()
        .listen((snap) {
      final ids = <String>[];
      for (var doc in snap.docs) {
        final usersList = List<String>.from(doc['users'] ?? []);
        for (var u in usersList) {
          if (u != me) ids.add(u);
        }
      }
      _connectedIds = ids;
      notifyListeners();
    });

    _incomingSub = _firestore
        .collection('connectionRequests')
        .where('toUserId', isEqualTo: me)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snap) {
      _incomingRequestIds = snap.docs.map((doc) => doc['fromUserId'].toString()).toList();
      notifyListeners();
    });

    _sentSub = _firestore
        .collection('connectionRequests')
        .where('fromUserId', isEqualTo: me)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snap) {
      _sentRequestIds = snap.docs.map((doc) => doc['toUserId'].toString()).toList();
      notifyListeners();
    });

    _blockedSub = _firestore
        .collection('blockedUsers')
        .where('blockerId', isEqualTo: me)
        .snapshots()
        .listen((snap) {
      _blockedIds = snap.docs.map((doc) => doc['blockedId'].toString()).toList();
      notifyListeners();
    });
  }

  /// 🔵 Stream of blocked user profiles
  Stream<List<UserModel>> get blockedUsersStream {
    final me = _me;
    if (me == null) return Stream.value([]);
    return _firestore
        .collection('blockedUsers')
        .where('blockerId', isEqualTo: me)
        .snapshots()
        .asyncMap((snap) async {
      final ids = snap.docs.map((doc) => doc['blockedId'].toString()).toList();
      if (ids.isEmpty) return [];
      final users = <UserModel>[];
      for (final id in ids) {
        try {
          final doc = await _firestore.collection('users').doc(id).get();
          if (doc.exists && doc.data() != null) {
            users.add(UserModel.fromFirestore(doc.id, doc.data()!));
          }
        } catch (e) {
          debugPrint('Error fetching blocked user $id: $e');
        }
      }
      return users;
    });
  }

  void cancelSocialSubs() {
    _usersSub?.cancel();
    _connectionsSub?.cancel();
    _incomingSub?.cancel();
    _sentSub?.cancel();
    _blockedSub?.cancel();

    _usersSub = null;
    _connectionsSub = null;
    _incomingSub = null;
    _sentSub = null;
    _blockedSub = null;

    _connectedIds = [];
    _incomingRequestIds = [];
    _sentRequestIds = [];
    _blockedIds = [];
    _users = [];
    _isLoadingUsers = false;
  }

  ConnectionStatus getConnectionStatus(String otherUserId) {
    final me = _me;
    if (me == null) return ConnectionStatus.none;

    if (_blockedIds.contains(otherUserId)) return ConnectionStatus.blocked;
    if (_connectedIds.contains(otherUserId)) return ConnectionStatus.connected;
    if (_sentRequestIds.contains(otherUserId)) return ConnectionStatus.sent;
    if (_incomingRequestIds.contains(otherUserId)) return ConnectionStatus.received;

    return ConnectionStatus.none;
  }

  /// 📊 Matching % calculation
  int matchPercent({
    required List<String> myInterests,
    required List<String> otherInterests,
  }) {
    if (myInterests.isEmpty || otherInterests.isEmpty) return 0;

    final my = myInterests.toSet();
    final other = otherInterests.toSet();

    final common = my.intersection(other).length;
    final union = my.union(other).length;

    if (union == 0) return 0;

    return ((common / union) * 100).round();
  }

  /// 🔵 Stream of connected User IDs
  Stream<List<String>> myConnectedIdsStream() {
    final me = _me;
    if (me == null) return const Stream.empty();

    return _firestore
        .collection('connections')
        .where('users', arrayContains: me)
        .snapshots()
        .map((snap) {
      final ids = <String>[];
      for (var doc in snap.docs) {
        final users = List<String>.from(doc['users'] ?? []);
        for (var u in users) {
          if (u != me) ids.add(u);
        }
      }
      return ids;
    });
  }

  /// 🔵 Stream of incoming connection request User IDs
  Stream<List<String>> incomingRequestIdsStream() {
    final me = _me;
    if (me == null) return const Stream.empty();

    return _firestore
        .collection('connectionRequests')
        .where('toUserId', isEqualTo: me)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) => snap.docs.map((doc) => doc['fromUserId'].toString()).toList());
  }

  /// 🔵 Stream of sent connection request User IDs
  Stream<List<String>> sentRequestIdsStream() {
    final me = _me;
    if (me == null) return const Stream.empty();

    return _firestore
        .collection('connectionRequests')
        .where('fromUserId', isEqualTo: me)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) => snap.docs.map((doc) => doc['toUserId'].toString()).toList());
  }

  /// 🔵 Stream of blocked User IDs
  Stream<List<String>> blockedIdsStream() {
    final me = _me;
    if (me == null) return const Stream.empty();

    return _firestore
        .collection('blockedUsers')
        .where('blockerId', isEqualTo: me)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => doc['blockedId'].toString()).toList());
  }

  /// 🔵 Stream of block status checking between me and another user (Either blocker or blocked)
  Stream<bool> isBlockedStream(String otherUserId) {
    final me = _me;
    if (me == null) return Stream.value(false);

    // Sorted key used for Chat Block status
    final users = [me, otherUserId]..sort();
    final convoId = users.join('_');

    return _firestore
        .collection('chats')
        .doc(convoId)
        .snapshots()
        .map((snap) {
      if (!snap.exists) return false;
      final data = snap.data() ?? {};
      return data.containsKey('blockedBy') && data['blockedBy'] != null;
    });
  }

  /// 🔵 Reactive status checker
  Stream<ConnectionStatus> statusStream(String otherUserId) {
    final me = _me;
    if (me == null) return Stream.value(ConnectionStatus.none);

    final users = [me, otherUserId]..sort();
    final connId = users.join('_');
    final reqId1 = '${me}_$otherUserId';
    final reqId2 = '${otherUserId}_$me';

    final blockedStream = _firestore.collection('blockedUsers').doc('${me}_$otherUserId').snapshots();
    final connStream = _firestore.collection('connections').doc(connId).snapshots();
    final req1Stream = _firestore.collection('connectionRequests').doc(reqId1).snapshots();
    final req2Stream = _firestore.collection('connectionRequests').doc(reqId2).snapshots();

    return Rx.combineLatest4<
        DocumentSnapshot<Map<String, dynamic>>,
        DocumentSnapshot<Map<String, dynamic>>,
        DocumentSnapshot<Map<String, dynamic>>,
        DocumentSnapshot<Map<String, dynamic>>,
        ConnectionStatus>(
      blockedStream,
      connStream,
      req1Stream,
      req2Stream,
      (blockSnap, connSnap, req1Snap, req2Snap) {
        if (blockSnap.exists) return ConnectionStatus.blocked;
        if (connSnap.exists) return ConnectionStatus.connected;
        if (req1Snap.exists && req1Snap.data()?['status'] == 'pending') return ConnectionStatus.sent;
        if (req2Snap.exists && req2Snap.data()?['status'] == 'pending') return ConnectionStatus.received;
        return ConnectionStatus.none;
      },
    ).asBroadcastStream();
  }

  // 🔵 Connection request delegation to ConnectionService
  Future<void> sendRequest(String toUserId) async {
    await _connectionService.sendConnectionRequest(toUserId);
  }

  Future<void> acceptRequest(String fromUserId) async {
    final requestId = '${fromUserId}_$_me';
    await _connectionService.acceptConnectionRequest(requestId, fromUserId);
  }

  Future<void> declineRequest(String fromUserId) async {
    final requestId = '${fromUserId}_$_me';
    await _connectionService.rejectConnectionRequest(requestId);
  }

  Future<void> cancelRequest(String toUserId) async {
    await _connectionService.cancelConnectionRequest(toUserId);
  }

  Future<void> removeFriend(String otherUserId) async {
    await _connectionService.removeConnection(otherUserId);
  }

  Future<void> block(String otherUserId) async {
    await _connectionService.blockUser(otherUserId);
  }

  Future<void> unblock(String otherUserId) async {
    await _connectionService.unblockUser(otherUserId);
  }

  Future<void> report({
    required String reportedUserId,
    required String reason,
    required String description,
    required String sourceType,
    String? sourceId,
  }) async {
    await _connectionService.reportUser(
      reportedUserId: reportedUserId,
      reason: reason,
      description: description,
      sourceType: sourceType,
      sourceId: sourceId,
    );
  }

  @override
  void dispose() {
    _usersSub?.cancel();
    super.dispose();
  }
}
