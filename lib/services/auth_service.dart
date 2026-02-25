import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ✅ Ensure user doc exists (idempotent)
  Future<void> ensureUserDoc({User? user}) async {
    final u = user ?? _auth.currentUser;
    if (u == null) return;

    final ref = _firestore.collection('users').doc(u.uid);
    final snap = await ref.get();

    if (snap.exists) return;

    await ref.set({
      'displayName': u.displayName ?? '',
      'email': u.email ?? '',
      'photoUrl': u.photoURL ?? '',
      'cityId': '',
      'cityName': '',
      'country': '',
      'countryCode': '',
      'interests': <String>[],
      'onboardingCompleted': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // 🔵 Email Register
  Future<UserCredential> registerWithEmail(
      String email, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // user doc'u garantiye al
    await ensureUserDoc(user: credential.user);

    return credential;
  }

  // 🔵 Email Login
  Future<UserCredential> loginWithEmail(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // user doc'u garantiye al
    await ensureUserDoc(user: credential.user);

    return credential;
  }

  // 🔵 Google Login
  Future<UserCredential> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception("Google sign in cancelled");
    }

    final googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);

    // user doc'u garantiye al
    await ensureUserDoc(user: userCredential.user);

    return userCredential;
  }

  // 🔴 Logout
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // 🟣 Profile Update (core alanlar)
  Future<void> updateProfile({
    required String displayName,
    required String bio, // eğer tutmak istiyorsan user doc'a da ekleyebilirsin
    required String cityName,
    required String country,
    required String countryCode,
    required String cityId,
    required List<String> interests,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).set({
      'displayName': displayName,
      'country': country,
      'countryCode': countryCode,
      'cityId': cityId,
      'cityName': cityName,
      'interests': interests,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // 🖼 Upload profile photo
  Future<String> uploadProfilePhoto(File image) async {
    final user = _auth.currentUser!;
    final ref = _storage.ref().child('profile_photos/${user.uid}.jpg');

    await ref.putFile(image);

    final url = await ref.getDownloadURL();

    await _firestore.collection('users').doc(user.uid).set({
      'photoUrl': url,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return url;
  }
}
