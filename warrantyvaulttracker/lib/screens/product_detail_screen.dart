import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:warrantyvaulttracker/screens/add_warranty_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class ProductDetailScreen extends StatelessWidget {
  final String warrantyId;

  const ProductDetailScreen({super.key, required this.warrantyId});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text('Warranty Details'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('warranties')
            .doc(warrantyId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.data() == null) {
            return const Center(child: Text('Warranty not found'));
          }

          final data = snapshot.data!.data()! as Map<String, dynamic>;
          final purchaseDate = (data['purchaseDate'] as Timestamp).toDate();
          final expiryDate = (data['expiryDate'] as Timestamp).toDate();
          data['status'] = _calculateStatus(expiryDate);
          final imageUrl = (data['documentUrl'] as String?) ?? '';

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderSection(data, expiryDate),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildModernInfoCard(
                        icon: Icons.info_outline,
                        title: 'Product Information',
                        children: [
                          _buildModernInfoRow(Icons.shopping_bag, 'Brand', data['brand']),
                          _buildModernInfoRow(Icons.category, 'Category', data['category']),
                          _buildModernInfoRow(Icons.store, 'Store', data['storeName']),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildModernInfoCard(
                        icon: Icons.calendar_today,
                        title: 'Warranty Timeline',
                        children: [
                          _buildModernInfoRow(Icons.shopping_cart, 'Purchase Date', DateFormat('dd MMM yyyy').format(purchaseDate)),
                          _buildModernInfoRow(Icons.event_available, 'Expiry Date', DateFormat('dd MMM yyyy').format(expiryDate)),
                          _buildModernInfoRow(Icons.timer, 'Duration', '${data['warrantyDuration']} months'),
                          const SizedBox(height: 12),
                          _buildTimelineBar(expiryDate),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if ((data['notes'] ?? '').toString().isNotEmpty)
                        _buildModernInfoCard(
                          icon: Icons.note,
                          title: 'Notes',
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                              child: Text(data['notes'], style: TextStyle(color: Colors.grey[800], fontSize: 14, height: 1.5)),
                            ),
                          ],
                        ),
                      const SizedBox(height: 16),
                      _buildDocumentsSection(context, imageUrl, data),
                      const SizedBox(height: 24),
                      _buildActionButtons(context, warrantyId, data),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderSection(Map<String, dynamic> data, DateTime expiryDate) {
    final status = data['status'];
    final gradient = _getStatusGradient(status);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25), 
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(75), 
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: Text(
              status.toUpperCase(),
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            data['productName'] ?? '-',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, height: 1.2),
          ),
          const SizedBox(height: 8),
          _buildDaysRemaining(expiryDate),
        ],
      ),
    );
  }

  Widget _buildDaysRemaining(DateTime expiryDate) {
    final now = DateTime.now();
    final daysLeft = expiryDate.difference(now).inDays;
    return Row(
      children: [
        Icon(daysLeft < 0 ? Icons.warning_amber_rounded : Icons.schedule, color: Colors.white, size: 18),
        const SizedBox(width: 6),
        Text(
          daysLeft < 0 ? 'Expired ${daysLeft.abs()} days ago' : '$daysLeft days remaining',
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildModernInfoCard({required IconData icon, required String title, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: Colors.blue[700], size: 20),
              ),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildModernInfoRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14))),
          Expanded(flex: 3, child: Text(value ?? '-', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _buildTimelineBar(DateTime expiryDate) {
    final now = DateTime.now();
    final daysLeft = expiryDate.difference(now).inDays;
    final progress = daysLeft < 0 ? 1.0 : (daysLeft > 365 ? 0.0 : 1 - (daysLeft / 365));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Warranty Progress', style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(daysLeft < 0 ? Colors.red : daysLeft <= 30 ? Colors.orange : Colors.green),
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentsSection(BuildContext context, String? imageUrl, Map<String, dynamic> data) {
    return _buildModernInfoCard(
      icon: Icons.attach_file,
      title: 'Documents',
      children: [
        if (imageUrl == null || imageUrl.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[300]!)),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.folder_open, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text('No documents uploaded', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
          )
        else
          Column(
            children: [
              GestureDetector(
                onTap: () => _openImage(context, imageUrl),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      Image.network(imageUrl, height: 200, width: double.infinity, fit: BoxFit.cover),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.black.withAlpha(125), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.zoom_in, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
             
            ],
          ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, String warrantyId, Map<String, dynamic> data) {
    return Row(
      children: [
      //   Expanded(
      //     child: OutlinedButton.icon(
      //       onPressed: () => _deleteWarranty(context, warrantyId),
      //       icon: const Icon(Icons.delete_outline),
      //       label: const Text('Delete'),
      //       style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
      //     ),
      //   ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            
            onPressed: () => _editWarranty(context, warrantyId, data),
            icon: const Icon(Icons.edit),
            label: const Text('Edit Warranty'),
            style: ElevatedButton.styleFrom(iconColor: Colors.white,padding: const EdgeInsets.symmetric(vertical: 14), backgroundColor: Colors.blue[700], foregroundColor: Colors.white, elevation: 2),
          ),
        ),
      ],
    );
  }

  

  Future<void> _editWarranty(BuildContext context, String warrantyId, Map<String, dynamic> data) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => AddWarrantyScreen(warrantyId: warrantyId, warrantyData: data)));
  }

  // Future<void> _deleteWarranty(BuildContext context, String warrantyId) async {
  //   final confirmed = await showDialog<bool>(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: const Text('Delete Warranty'),
  //       content: const Text('Are you sure you want to delete this warranty?'),
  //       actions: [
  //         TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
  //         TextButton(onPressed: () => Navigator.pop(context, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Delete')),
  //       ],
  //     ),
  //   );

  //   if (confirmed == true) {
  //     try {
  //                             log('Deleting warranty id: ${w['id']}');
  //                             final userId = UserSessionData.uid!;
  //                             await context
  //                                 .read<WarrantyController>()
  //                                 .deleteWarranty(w['id'], userId);

  //                             if (mounted) {
  //                               ScaffoldMessenger.of(context).showSnackBar(
  //                                 SnackBar(
  //                                   content: Text(
  //                                       '${w['productName']} deleted successfully'),
  //                                   backgroundColor: Colors.green[600],
  //                                   duration: const Duration(seconds: 2),
  //                                 ),
  //                               );
  //                             }
  //                           } catch (e) {
  //                             log('Error deleting warranty: $e');
  //                             if (mounted) {
  //                               ScaffoldMessenger.of(context).showSnackBar(
  //                                 SnackBar(
  //                                   content:
  //                                       const Text('Failed to delete warranty'),
  //                                   backgroundColor: Colors.red[600],
  //                                   duration: const Duration(seconds: 2),
  //                                 ),
  //                               );
  //                             }
  //                           }
  //   }
  // }

  void _openImage(BuildContext context, String imageUrl) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(backgroundColor: Colors.black, appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white), body: Center(child: InteractiveViewer(child: Image.network(imageUrl))))));
  }

  LinearGradient _getStatusGradient(String status) {
    if (status == 'Active') return const LinearGradient(colors: [Color(0xFF11998e), Color(0xFF38ef7d)]);
    if (status == 'Expiring Soon') return const LinearGradient(colors: [Color(0xFFf46b45), Color(0xFFeea849)]);
    return const LinearGradient(colors: [Color(0xFFEB3349), Color(0xFFF45C43)]);
  }

  String _calculateStatus(DateTime expiryDate) {
    final now = DateTime.now();
    if (expiryDate.isBefore(now)) return 'Expired';
    final daysLeft = expiryDate.difference(now).inDays;
    return daysLeft <= 30 ? 'Expiring Soon' : 'Active';
  }
}