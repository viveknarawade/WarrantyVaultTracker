import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:warrantyvaulttracker/screens/dashboard_screen.dart';
import 'package:warrantyvaulttracker/screens/profile_screen.dart';
import 'package:warrantyvaulttracker/services/notifi_service.dart';
import 'package:warrantyvaulttracker/services/user_session_data.dart';
import 'package:warrantyvaulttracker/services/warranty_service.dart';
import 'package:warrantyvaulttracker/services/cloudinary_service.dart';

class AddWarrantyScreen extends StatefulWidget {
  final String? warrantyId;
  final Map<String, dynamic>? warrantyData;

  const AddWarrantyScreen({
    super.key,
    this.warrantyId,
    this.warrantyData,
  });

  @override
  State<AddWarrantyScreen> createState() => _AddWarrantyScreenState();
}

class _AddWarrantyScreenState extends State<AddWarrantyScreen> {
  final WarrantyService _warrantyService = WarrantyService();
  final _formKey = GlobalKey<FormState>();
  final _productNameController = TextEditingController();
  final _brandController = TextEditingController();
  final _storeNameController = TextEditingController();
  final _warrantyDurationController = TextEditingController(text: '12');
  final _serialNumberController = TextEditingController();
  final _notesController = TextEditingController();
  String? _existingImageUrl; // 👈 for edit mode
  bool get isEditMode => widget.warrantyId != null;

  String _selectedCategory = 'Other';
  DateTime? _purchaseDate;
  DateTime? _expiryDate;
  File? _invoiceImage;

  bool _isLoading = false;

  final List<String> _categories = [
    'Electronics',
    'Appliances',
    'Vehicle',
    'Furniture',
    'Health',
    'Sports',
    'Other',
  ];
  @override
  void initState() {
    super.initState();

    if (isEditMode && widget.warrantyData != null) {
      final data = widget.warrantyData!;

      _productNameController.text = data['productName'] ?? '';
      _brandController.text = data['brand'] ?? '';
      _storeNameController.text = data['storeName'] ?? '';
      _warrantyDurationController.text =
          data['warrantyDuration']?.toString() ?? '12';
      _notesController.text = data['notes'] ?? '';
      _selectedCategory = data['category'] ?? 'Other';

      _purchaseDate = (data['purchaseDate'] as Timestamp?)?.toDate();
      _expiryDate = (data['expiryDate'] as Timestamp?)?.toDate();

      // ✅ Correctly handle documentUrl (string, not list)
      if (data['documentUrl'] != null &&
          (data['documentUrl'] as String).isNotEmpty) {
        _existingImageUrl = data['documentUrl'] as String;
      }
    }
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _brandController.dispose();
    _storeNameController.dispose();
    _warrantyDurationController.dispose();
    _serialNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await picker.pickImage(
                  source: ImageSource.camera,
                );
                if (image != null) {
                  setState(() {
                    _invoiceImage = File(image.path);
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await picker.pickImage(
                  source: ImageSource.gallery,
                );
                if (image != null) {
                  setState(() {
                    _invoiceImage = File(image.path);
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _calculateExpiryDate() {
    if (_purchaseDate != null && _warrantyDurationController.text.isNotEmpty) {
      final months = int.tryParse(_warrantyDurationController.text) ?? 0;
      setState(() {
        _expiryDate = DateTime(
          _purchaseDate!.year,
          _purchaseDate!.month + months,
          _purchaseDate!.day,
        );
      });
    }
  }

  Future<void> _selectPurchaseDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _purchaseDate = picked;
      });
      _calculateExpiryDate();
    }
  }

  Future<void> _saveWarranty() async {
    if (!_formKey.currentState!.validate()) return;
    if (_purchaseDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select purchase date')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? documentUrl;
      String? documentPublicId;
      if (_invoiceImage != null) {
        // If editing and old image exists, get its public_id
        String? oldPublicId;
        if (_existingImageUrl != null &&
            isEditMode &&
            widget.warrantyData != null) {
          oldPublicId = widget.warrantyData!['documentPublicId'];
        }

        // Upload to Cloudinary, overwriting if public_id exists
        final uploadedUrl =
            await uploadToCloudinary(_invoiceImage!, publicId: oldPublicId);

        documentUrl = uploadedUrl;
        documentPublicId =
            uploadedUrl!.split('/').last.split('.').first; // extract public_id
      } else if (_existingImageUrl != null) {
        // Keep old image if no new image picked
        documentUrl = _existingImageUrl;
        documentPublicId = widget.warrantyData?['documentPublicId'];
      }

      final warrantyData = {
        'productName': _productNameController.text.trim(),
        'brand': _brandController.text.trim(),
        'category': _selectedCategory,
        'storeName': _storeNameController.text.trim(),
        'purchaseDate': Timestamp.fromDate(_purchaseDate!),
        'warrantyDuration': int.parse(_warrantyDurationController.text),
        'expiryDate': Timestamp.fromDate(_expiryDate!),
        'notes': _notesController.text.trim(),
        'documentUrl': documentUrl,
        'documentPublicId': documentPublicId,
      };
      String warrantyId;
      if (widget.warrantyId == null) {
        //  ADD MODE
        warrantyData['createdAt'] = FieldValue.serverTimestamp();
        final docRef = await _warrantyService.addWarranty(warrantyData);
        warrantyId = docRef.id;
        await UserSessionData.incrementTotalProducts();
      } else {
        //  EDIT MODE
        warrantyId = widget.warrantyId!;

        await NotificationService().cancelWarrantyNotifications(warrantyId);

        await _warrantyService.updateWarranty(warrantyId, warrantyData);
      }

      try {
        await NotificationService().scheduleWarrantyNotifications(
          warrantyId: warrantyId,
          productName: _productNameController.text.trim(),
          expiryDate: _expiryDate!,
        );
        log("Warranty notifications scheduled for ID: $warrantyId");
      } catch (e) {

        if (e.toString().contains('exact_alarms_not_permitted')) {

          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Enable Notifications'),
                content: const Text(
                  'To receive warranty expiry reminders, please enable exact alarm permission in settings.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Skip'),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(context);

                      await NotificationService().requestExactAlarmPermission();
                    },
                    child: const Text('Enable'),
                  ),
                ],
              ),
            );
          }
        }
      }

      if (mounted) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.warrantyId == null
                  ? 'Warranty added successfully!'
                  : 'Warranty updated successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildInvoicePreview() {
    if (_invoiceImage != null) {
      return _imagePreview(
        Image.file(_invoiceImage!, fit: BoxFit.cover),
        onRemove: () {
          setState(() {
            _invoiceImage = null;
            _existingImageUrl = null;
          });
        },
      );
    }

    if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
      return _imagePreview(
        Image.network(_existingImageUrl!, fit: BoxFit.cover),
        onRemove: () {
          setState(() {
            _existingImageUrl = null;
          });
        },
      );
    }

    return OutlinedButton.icon(
      onPressed: _pickImage,
      icon: const Icon(Icons.upload_file),
      label: const Text('Browse Files'),
    );
  }

  Widget _imagePreview(Widget image, {required VoidCallback onRemove}) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 120,
            width: 120,
            child: image,
          ),
        ),
        Positioned(
          top: -8,
          right: -8,
          child: IconButton(
            icon: const Icon(Icons.cancel, color: Colors.red),
            onPressed: onRemove,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          }, 
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Page Title
                Text(
                  isEditMode ? 'Edit Product' : 'Add New Product',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Enter product details manually or scan your bill.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),

                // Scan Bill & Auto-Fill Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.document_scanner_outlined,
                          color: Colors.blue[700],
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Scan Bill & Auto-Fill',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Select your invoice image here, or click to browse',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInvoicePreview(),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Product Name
                const Text(
                  'Product Name',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _productNameController,
                  decoration: InputDecoration(
                    hintText: 'e.g. iPhone 15 Pro',
                    hintStyle: TextStyle(color: Colors.grey[400]),
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
                      borderSide:
                          const BorderSide(color: Colors.blue, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter product name';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Brand
                const Text(
                  'Brand',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _brandController,
                  decoration: InputDecoration(
                    hintText: 'e.g. Apple',
                    hintStyle: TextStyle(color: Colors.grey[400]),
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
                      borderSide:
                          const BorderSide(color: Colors.blue, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter brand name';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Category
                const Text(
                  'Category',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
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
                      borderSide:
                          const BorderSide(color: Colors.blue, width: 2),
                    ),
                  ),
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value!;
                    });
                  },
                ),

                const SizedBox(height: 16),

                // Store Name
                const Text(
                  'Store Name',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _storeNameController,
                  decoration: InputDecoration(
                    hintText: 'e.g. Amazon',
                    hintStyle: TextStyle(color: Colors.grey[400]),
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
                      borderSide:
                          const BorderSide(color: Colors.blue, width: 2),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Purchase Date
                const Text(
                  'Purchase Date',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _selectPurchaseDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today,
                            color: Colors.grey[600], size: 20),
                        const SizedBox(width: 12),
                        Text(
                          _purchaseDate == null
                              ? 'Pick a date'
                              : DateFormat('MMM dd, yyyy')
                                  .format(_purchaseDate!),
                          style: TextStyle(
                            color: _purchaseDate == null
                                ? Colors.grey[400]
                                : Colors.black87,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Warranty Duration
                const Text(
                  'Warranty Duration (Months)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _warrantyDurationController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: '12',
                    hintStyle: TextStyle(color: Colors.grey[400]),
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
                      borderSide:
                          const BorderSide(color: Colors.blue, width: 2),
                    ),
                  ),
                  onChanged: (value) => _calculateExpiryDate(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter warranty duration';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Expiry Date (Auto-calculated)
                const Text(
                  'Expiry Date (Auto-calculated)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today,
                          color: Colors.grey[600], size: 20),
                      const SizedBox(width: 12),
                      Text(
                        _expiryDate == null
                            ? 'Pick a date'
                            : DateFormat('MMM dd, yyyy').format(_expiryDate!),
                        style: TextStyle(
                          color: _expiryDate == null
                              ? Colors.grey[400]
                              : Colors.black87,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Notes
                const Text(
                  'Notes',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notesController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Any additional details...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
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
                      borderSide:
                          const BorderSide(color: Colors.blue, width: 2),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: Colors.grey[400]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveWarranty,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Save Product',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
