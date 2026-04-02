import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/user_session_data.dart';
import '../services/warranty_service.dart';

class WarrantyController extends ChangeNotifier {
  final WarrantyService _service = WarrantyService();

  List<Map<String, dynamic>> _allWarranties = [];
  List<Map<String, dynamic>> filteredWarranties = [];

  String selectedStatus = 'All Status';
  String searchQuery = ''; 

  WarrantyController() {
    _listenToWarranties();
  }
 Future<void> deleteWarranty(String id, String userId) async {
    try {
      final warrantyRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('warranties')
          .doc(id);

   

      await warrantyRef.delete(); 

      final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
      await userRef.update({
        'totalProducts': FieldValue.increment(-1),
      });

      _allWarranties.removeWhere((w) => w['id'] == id);
      filteredWarranties.removeWhere((w) => w['id'] == id);
      
      await UserSessionData.decrementTotalProducts();
      notifyListeners();
      
      log('Successfully deleted warranty from Firebase subcollection');
    } catch (e) {
      log('Error deleting warranty: $e');
      rethrow;
    }
  }

  void _listenToWarranties() {
    _service.getWarranties().listen((snapshot) {
      _allWarranties = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final status = calculateStatus(data['expiryDate']);
        return {
          'id': doc.id,
          ...data,
          'status': status,
        };
      }).toList();

      applyFilter();
    });
  }

  void setStatus(String status) {
    selectedStatus = status;
    applyFilter();
  }

  void setSearchQuery(String query) {
    searchQuery = query.toLowerCase();
    applyFilter();
  }

  void applyFilter() {
    filteredWarranties = _allWarranties.where((w) {
      final matchesStatus =
          selectedStatus == 'All Status' || w['status'] == selectedStatus;

      final name = (w['productName'] ?? '').toString().toLowerCase();
      final brand = (w['brand'] ?? '').toString().toLowerCase();
      final serial = (w['serialNumber'] ?? '').toString().toLowerCase();

      final matchesSearch = name.contains(searchQuery) ||
          brand.contains(searchQuery) ||
          serial.contains(searchQuery);

      return matchesStatus && matchesSearch;
    }).toList();

    notifyListeners();
  }

  String calculateStatus(Timestamp expiryDate) {
    final now = DateTime.now();
    final expiry = expiryDate.toDate();
    if (expiry.isBefore(now)) return 'Expired';
    final daysLeft = expiry.difference(now).inDays;
    if (daysLeft <= 30) return 'Expiring Soon';
    return 'Active';
  }
}
