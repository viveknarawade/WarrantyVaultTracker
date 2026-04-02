import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:warrantyvaulttracker/services/user_session_data.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> registerUser(String name, String email, String password) async {
    try {
      // 1. Create Firebase Auth user
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        // 2. Update display name
        await user.updateDisplayName(name);

        // 3. Save user profile in Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'name': name,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
          'totalProducts': 0,
          'notificationEnabled': true,
        });
      }

      return user;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> loginUser(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) return null;

      // Fetch Firestore user data
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();

      String name = userDoc['name'];
      String firestoreEmail = userDoc['email'];
      int totalProducts = userDoc['totalProducts'] ?? 0;
      bool notificationEnabled = userDoc['notificationEnabled'] ?? true;

      // Save session data
      await UserSessionData.setUserSessionData(
        loginData: true,
        id: user.uid,
        name: name,
        email: firestoreEmail,
        totalProducts: totalProducts,
        notificationEnabled: notificationEnabled,
      );

      return user;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await UserSessionData.clearSessionData();
  }

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;

    final uid = UserSessionData.uid;
    if (user == null) return;
    log(uid.toString());

    // 1️⃣ Delete Firestore user document
    await _firestore.collection('users').doc(uid).delete();

    // 2️⃣ Delete Firebase Auth user
    await user.delete();

    // 3️⃣ Clear local session
    await UserSessionData.clearSessionData();
  }

//update user name and email
//change pass
}
