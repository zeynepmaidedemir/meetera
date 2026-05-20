import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ConnectionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  /// 🔵 Send friendship / connection request
  Future<void> sendConnectionRequest(String toUserId) async {
    final me = currentUserId;
    if (me == null || me == toUserId) return;

    final requestId = '${me}_$toUserId';
    await _firestore.collection('connectionRequests').doc(requestId).set({
      'fromUserId': me,
      'toUserId': toUserId,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 🔵 Accept connection request
  Future<void> acceptConnectionRequest(String requestId, String fromUserId) async {
    final me = currentUserId;
    if (me == null) return;

    final batch = _firestore.batch();

    // 1. Update request status
    final reqRef = _firestore.collection('connectionRequests').doc(requestId);
    batch.update(reqRef, {
      'status': 'accepted',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 2. Create connections document
    final users = [me, fromUserId]..sort();
    final connectionId = users.join('_');
    final connRef = _firestore.collection('connections').doc(connectionId);
    batch.set(connRef, {
      'users': users,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 3. Create or ensure Chat thread exists between the two
    final chatRef = _firestore.collection('chats').doc(connectionId);
    batch.set(chatRef, {
      'participants': users,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastMessage': '',
      'isActive': true,
    }, SetOptions(merge: true));

    await batch.commit();
  }

  /// 🔵 Reject connection request
  Future<void> rejectConnectionRequest(String requestId) async {
    await _firestore.collection('connectionRequests').doc(requestId).delete();
  }

  /// 🔵 Cancel sent request
  Future<void> cancelConnectionRequest(String toUserId) async {
    final me = currentUserId;
    if (me == null) return;
    final requestId = '${me}_$toUserId';
    await _firestore.collection('connectionRequests').doc(requestId).delete();
  }

  /// 🔵 Remove connection / Unfriend
  Future<void> removeConnection(String otherUserId) async {
    final me = currentUserId;
    if (me == null) return;

    final users = [me, otherUserId]..sort();
    final connectionId = users.join('_');

    final batch = _firestore.batch();

    // Remove connections document
    final connRef = _firestore.collection('connections').doc(connectionId);
    batch.delete(connRef);

    // Delete corresponding connectionRequests
    final reqId1 = '${me}_$otherUserId';
    final reqId2 = '${otherUserId}_$me';
    batch.delete(_firestore.collection('connectionRequests').doc(reqId1));
    batch.delete(_firestore.collection('connectionRequests').doc(reqId2));

    // Archive or deactivate chat
    final chatRef = _firestore.collection('chats').doc(connectionId);
    batch.update(chatRef, {
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// 🔵 Engelle (Block User)
  Future<void> blockUser(String toBlockUserId) async {
    final me = currentUserId;
    if (me == null || me == toBlockUserId) return;

    final blockId = '${me}_$toBlockUserId';
    final batch = _firestore.batch();

    // 1. Write block record
    final blockRef = _firestore.collection('blockedUsers').doc(blockId);
    batch.set(blockRef, {
      'blockerId': me,
      'blockedId': toBlockUserId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2. Remove connection (if any)
    final users = [me, toBlockUserId]..sort();
    final connectionId = users.join('_');
    batch.delete(_firestore.collection('connections').doc(connectionId));

    // 3. Remove connection requests
    batch.delete(_firestore.collection('connectionRequests').doc('${me}_$toBlockUserId'));
    batch.delete(_firestore.collection('connectionRequests').doc('${toBlockUserId}_$me'));

    // 4. Update chat thread to set blockedBy
    final chatRef = _firestore.collection('chats').doc(connectionId);
    batch.update(chatRef, {
      'blockedBy': me,
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// 🔵 Engeli Kaldır (Unblock User)
  Future<void> unblockUser(String blockedUserId) async {
    final me = currentUserId;
    if (me == null) return;

    final blockId = '${me}_$blockedUserId';
    final batch = _firestore.batch();

    batch.delete(_firestore.collection('blockedUsers').doc(blockId));

    final users = [me, blockedUserId]..sort();
    final connectionId = users.join('_');
    final chatRef = _firestore.collection('chats').doc(connectionId);
    batch.update(chatRef, {
      'blockedBy': FieldValue.delete(),
      'isActive': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// 🔵 Rapor Et (Report User)
  Future<void> reportUser({
    required String reportedUserId,
    required String reason,
    required String description,
    required String sourceType,
    String? sourceId,
  }) async {
    final me = currentUserId;
    if (me == null) return;

    final reportId = _firestore.collection('reports').doc().id;
    await _firestore.collection('reports').doc(reportId).set({
      'reporterId': me,
      'reportedUserId': reportedUserId,
      'reason': reason,
      'description': description,
      'sourceType': sourceType,
      'sourceId': sourceId,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'pending',
    });
  }
}
