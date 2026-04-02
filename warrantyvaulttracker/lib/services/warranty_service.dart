import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WarrantyService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

//add warranty
Future<DocumentReference> addWarranty(
    Map<String, dynamic> warrantyData) async {

  final uid = _auth.currentUser!.uid;

  if (uid == null) throw Exception('User not logged in');

  final userRef = _firestore.collection('users').doc(uid);

  //  Transaction = safe increment
  return await _firestore.runTransaction((transaction) async {
    transaction.update(userRef, {
      'totalProducts': FieldValue.increment(1),
    });

    final warrantyRef = userRef.collection('warranties').doc();
    transaction.set(warrantyRef, warrantyData);

    return warrantyRef;
  });
}


// get Warranties
  Stream<QuerySnapshot> getWarranties() {
    final uid = _auth.currentUser!.uid;
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('warranties')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> updateWarranty(String id, Map<String, dynamic> data) async {
    final uid = _auth.currentUser!.uid;
    final docRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('warranties')
        .doc(id);
    final docSnapshot = await docRef.get();

    if (!docSnapshot.exists) {
      throw Exception('Warranty document not found!');
    }

    await docRef.update(data);
  }

  
}
