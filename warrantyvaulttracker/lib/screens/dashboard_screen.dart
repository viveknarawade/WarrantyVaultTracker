import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:warrantyvaulttracker/controllers/warranty_contoller.dart';
import 'package:warrantyvaulttracker/screens/add_warranty_screen.dart';
import 'package:warrantyvaulttracker/screens/product_detail_screen.dart';
import 'package:warrantyvaulttracker/screens/profile_screen.dart';
import 'package:warrantyvaulttracker/screens/my_vault_screen.dart';
import 'package:warrantyvaulttracker/services/user_session_data.dart';
import 'package:warrantyvaulttracker/widget/custom_drawer.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int expiringListCount = 3;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<WarrantyController>();

    final all = controller.filteredWarranties.isNotEmpty
        ? controller.filteredWarranties
        : controller.filteredWarranties;

    final total = controller.filteredWarranties.length;

    final active = controller.filteredWarranties
        .where((w) => w['status'] == 'Active')
        .length;

    final expiringSoon = controller.filteredWarranties
        .where((w) => w['status'] == 'Expiring Soon')
        .length;

    final expired = controller.filteredWarranties
        .where((w) => w['status'] == 'Expired')
        .length;

    final expiringList = controller.filteredWarranties
        .where((w) => w['status'] == 'Expiring Soon')
        .toList();

    int expiringListCount = 3;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        // leading: IconButton(
        //   icon: const Icon(Icons.menu, color: Colors.black),
        //   onPressed: () {},
        // ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 8, bottom: 8),
            child: GestureDetector(
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => ProfileScreen()));
              },
              child: CircleAvatar(
                backgroundColor: Colors.blue,
                child: Text(
                  (UserSessionData.name?.isNotEmpty ?? false)
                      ? UserSessionData.name![0].toUpperCase()
                      : '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      //drawer
      drawer: CustomDrawer(
        onItemSelected: (route) {
          switch (route) {
            case "dashboard":
              break;

            case "vault":
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyVaultScreen()),
              );
              break;

            case "add_warranty":
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddWarrantyScreen()),
              );
              break;

            case "profile":
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
              break;
          }
        },
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dashboard Title
              const Text(
                'Dashboard',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1D1F),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Overview of your warranty vault status.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),

              // Stats Cards
              _buildStatCard(
                title: 'Total Products',
                value: total.toString(),
                icon: Icons.inventory_2_outlined,
                iconColor: Colors.blue,
                iconBgColor: Colors.blue.withOpacity(0.1),
              ),

              const SizedBox(height: 16),

              _buildStatCard(
                title: 'Active Warranties',
                value: active.toString(),
                subtitle: total == 0
                    ? '0% active'
                    : '${((active / total) * 100).toStringAsFixed(0)}% active',
                subtitleColor: Colors.green,
                icon: Icons.verified_outlined,
                iconColor: Colors.green,
                iconBgColor: Colors.green.withOpacity(0.1),
              ),

              const SizedBox(height: 16),
              _buildStatCard(
                title: 'Expiring Soon',
                value: expiringSoon.toString(),
                subtitle: expiringSoon > 0 ? 'Action needed' : 'All good',
                subtitleColor: Colors.orange,
                icon: Icons.access_time,
                iconColor: Colors.orange,
                iconBgColor: Colors.orange.withOpacity(0.1),
              ),

              const SizedBox(height: 16),

              _buildStatCard(
                title: 'Expired',
                value: expired.toString(),
                icon: Icons.warning_amber_outlined,
                iconColor: Colors.red,
                iconBgColor: Colors.red.withOpacity(0.1),
              ),

              const SizedBox(height: 32),

              // Expiring Soon Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Expiring Soon',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1D1F),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        expiringListCount = expiringList.length;
                      });
                    },
                    child: const Text(
                      'View All',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              expiringList.isEmpty
                  ? _emptyExpiringUI()
                  : Column(
                      children: expiringList.take(expiringListCount).map((w) {
                        return Dismissible(
                          key: ValueKey(w['id']),
                          direction:
                              DismissDirection.endToStart, // swipe right → left
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          // confirmDismiss: (direction) async {
                          //   return await showDialog(
                          //     context: context,
                          //     builder: (context) => AlertDialog(
                          //       title: const Text('Delete Warranty'),
                          //       content: const Text(
                          //           'Are you sure you want to delete this item?'),
                          //       actions: [
                          //         TextButton(
                          //           onPressed: () =>
                          //               Navigator.pop(context, false),
                          //           child: const Text('Cancel'),
                          //         ),
                          //         TextButton(
                          //           onPressed: () =>
                          //               Navigator.pop(context, true),
                          //           child: const Text(
                          //             'Delete',
                          //             style: TextStyle(color: Colors.red),
                          //           ),
                          //         ),
                          //       ],
                          //     ),
                          //   );
                          // },
                          onDismissed: (direction) async {
                            try {
                              log('Deleting warranty id: ${w['id']}');
                              final userId = UserSessionData.uid!;
                              await context
                                  .read<WarrantyController>()
                                  .deleteWarranty(w['id'], userId);

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        '${w['productName']} deleted successfully'),
                                    backgroundColor: Colors.green[600],
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            } catch (e) {
                              log('Error deleting warranty: $e');
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content:
                                        const Text('Failed to delete warranty'),
                                    backgroundColor: Colors.red[600],
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            }
                          },

                          child: Card(
                            color: Colors.white,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: const Icon(Icons.access_time,
                                  color: Colors.orange),
                              title: Text(
                                w['productName'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                'Expires on ${DateFormat('dd MMM yyyy').format(
                                  (w['expiryDate'] as Timestamp).toDate(),
                                )}',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProductDetailScreen(
                                        warrantyId: w['id']),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddWarrantyScreen(),
            ),
          );
        },
        backgroundColor: Colors.blue[600],
        child: const Icon(
          Icons.add,
          size: 28,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _emptyExpiringUI() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_outlined,
              size: 40,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No warranties expiring soon',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All your warranties are up to date',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    String? subtitle,
    Color? subtitleColor,
    String? compareText,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1D1F),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: subtitleColor ?? Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (compareText != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          compareText,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}
