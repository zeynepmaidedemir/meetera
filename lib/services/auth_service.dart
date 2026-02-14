import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class AuthService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadProfilePhoto(File image) async {
    final user = _auth.currentUser!;
    final ref = FirebaseStorage.instance
        .ref()
        .child('profile_photos')
        .child('${user.uid}.jpg');

    await ref.putFile(image);

    final url = await ref.getDownloadURL();

    await _firestore.collection('users').doc(user.uid).update({
      'photoUrl': url,
    });

    return url; // 👈 BUNU EKLE
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // 🔵 Email Register
  Future<UserCredential> registerWithEmail(
    String email,
    String password,
  ) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await _createUserIfNotExists(credential.user!);

    return credential;
  }

  // 🔵 Email Login
  Future<UserCredential> loginWithEmail(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    await _createUserIfNotExists(credential.user!);

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

    await _createUserIfNotExists(userCredential.user!);

    return userCredential;
  }

  // 🔴 Logout
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // 🔥 Firestore user oluşturma
  Future<void> _createUserIfNotExists(User user) async {
    final docRef = _firestore.collection('users').doc(user.uid);
    final snapshot = await docRef.get();

    if (!snapshot.exists) {
      await docRef.set({
        'uid': user.uid,
        'email': user.email ?? '',
        'displayName': user.displayName ?? '',
        'photoUrl': user.photoURL ?? '',
        'bio': '',
        'city': '',
        'country': '',
        'countryCode': '',
        'cityId': '',
        'interests': [],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // 🟣 Profile Update (ileride kullanacağız)
  Future<void> updateProfile({
    required String displayName,
    required String bio,
    required String city,
    required String country,
    required List<String> interests,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).update({
      'displayName': displayName,
      'bio': bio,
      'city': city,
      'country': country,
      'interests': interests,
    });
  }
}
