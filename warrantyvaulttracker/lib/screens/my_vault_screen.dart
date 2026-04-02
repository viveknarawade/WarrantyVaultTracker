import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:warrantyvaulttracker/controllers/warranty_contoller.dart';
import 'package:warrantyvaulttracker/screens/add_warranty_screen.dart';
import 'package:warrantyvaulttracker/screens/dashboard_screen.dart';
import 'package:warrantyvaulttracker/screens/product_detail_screen.dart';
import 'package:warrantyvaulttracker/screens/profile_screen.dart';
import 'package:warrantyvaulttracker/services/user_session_data.dart';

class MyVaultScreen extends StatefulWidget {
  const MyVaultScreen({super.key});

  @override
  State<MyVaultScreen> createState() => _MyVaultScreenState();
}

class _MyVaultScreenState extends State<MyVaultScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'All Status';
  bool _isFilterOpen = false;
  bool _isMenuOpen = false;

  final List<String> _statusOptions = [
    'All Status',
    'Active',
    'Expiring Soon',
    'Expired',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleFilter() {
    setState(() {
      _isFilterOpen = !_isFilterOpen;
    });
  }

  void _closeFilter() {
    if (_isFilterOpen) {
      setState(() {
        _isFilterOpen = false;
      });
    }
  }

  void _selectStatus(String status) {
    setState(() {
      _selectedStatus = status;
      _isFilterOpen = false;
    });

    context.read<WarrantyController>().setStatus(status);
  }

  void _clearFilters() {
    setState(() {
      _selectedStatus = 'All Status';
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _closeFilter,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
             leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => DashboardScreen()),
            );
          }, // goes back to Dashboard
        ),
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
        body: Stack(
          children: [
            _buildMainContent(context),
            if (_isMenuOpen) _buildMenuOverlay(),
            if (_isFilterOpen) _buildFilterDropdown(),
          ],
        ),
      ),
    );
  }


Widget _buildWarrantyCard(Map<String, dynamic> warranty) {
  final String status = warranty['status'] ?? 'Active';
  Color statusColor = status == 'Active'
      ? Colors.green
      : (status == 'Expiring Soon' ? Colors.orange : Colors.red);

  return Dismissible(
    key: ValueKey(warranty['id']),
    direction: DismissDirection.endToStart,
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
    //       content: const Text('Are you sure you want to delete this item?'),
    //       actions: [
    //         TextButton(
    //           onPressed: () => Navigator.pop(context, false),
    //           child: const Text('Cancel'),
    //         ),
    //         TextButton(
    //           onPressed: () => Navigator.pop(context, true),
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
    final userId = UserSessionData.uid ?? '';
    if (userId.isNotEmpty) {
      await context
          .read<WarrantyController>()
          .deleteWarranty(warranty['id'], userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${warranty['productName']} deleted successfully'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green[600],
          ),
        );
      }
    }
  } catch (e) {
    log('Error deleting warranty: $e');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to delete warranty'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.red[600],
        ),
      );
    }
  }
},

    child: Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.inventory_2_outlined, color: Colors.blue[700]),
        ),
        title: Text(
          warranty['productName'] ?? 'Unknown Product',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
              "${warranty['brand'] ?? 'No Brand'} • Exp: ${warranty['expiryDate'] != null ? (warranty['expiryDate'] as Timestamp).toDate().toString().split(' ')[0] : 'N/A'}"),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: statusColor.withOpacity(0.5)),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: statusColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        onTap: () {
          log("MY VAULT SCREEN : Warranty data: ${warranty.toString()}");
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(warrantyId: warranty['id']),
            ),
          );
        },
      ),
    ),
  );
}

  Widget _buildMainContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Section
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'My Vault',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage all your product warranties.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),

              // Add Product Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to Add Product screen

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddWarrantyScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, size: 20, color: Colors.white),
                  label: const Text(
                    'Add Product',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by name, brand or serial...',
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
              prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.blue, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            onChanged: (value) {
              context.read<WarrantyController>().setSearchQuery(value);
            },
          ),
        ),

        const SizedBox(height: 16),

        // Filter Dropdown
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              GestureDetector(
                onTap: _toggleFilter,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.filter_list,
                        color: Colors.grey[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _selectedStatus,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        Expanded(
          child: Consumer<WarrantyController>(
            builder: (context, controller, _) {
              final warranties = controller.filteredWarranties;

              if (warranties.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      const Text(
                        'No products found',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: warranties.length,
                itemBuilder: (context, index) {
                  return _buildWarrantyCard(warranties[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMenuOverlay() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isMenuOpen = false;
        });
      },
      child: Container(
        color: Colors.black.withOpacity(0.2), // backdrop
        child: Align(
          alignment: Alignment.topLeft,
          child: Container(
            margin: const EdgeInsets.only(top: kToolbarHeight + 8, left: 12),
            width: 220,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _menuItem(Icons.person, 'Profile', () {
                  setState(() => _isMenuOpen = false);
                  // Navigate to Profile
                }),
                _menuItem(Icons.notifications, 'Notifications', () {
                  setState(() => _isMenuOpen = false);
                }),
                _menuItem(Icons.settings, 'Settings', () {
                  setState(() => _isMenuOpen = false);
                }),
                const Divider(height: 1),
                _menuItem(Icons.logout, 'Logout', () {
                  setState(() => _isMenuOpen = false);
                }, isLogout: true),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _menuItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isLogout = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isLogout ? Colors.red : Colors.grey[800],
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isLogout ? Colors.red : Colors.black,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildFilterDropdown() {
    return Positioned(
      top: 270, // adjust based on UI
      right: 16,
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _statusOptions.map((status) {
              final isSelected = status == _selectedStatus;

              return InkWell(
                onTap: () => _selectStatus(status),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.blue.withOpacity(0.05)
                        : Colors.white,
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey[200]!,
                        width: status == _statusOptions.last ? 0 : 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected ? Colors.blue : Colors.grey[800],
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check, color: Colors.blue, size: 18),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
