// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'vendor_dashboard_screen.dart'; // Import the vendor dashboard for the bottom nav bar
//
// class ProfileSettingsScreen extends StatelessWidget {
//   final User user;
//
//   ProfileSettingsScreen({required this.user});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Profile Settings"),
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           children: [
//             // Your content for ProfileSettingsScreen
//             Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Text("Profile Settings Content goes here..."),
//             ),
//             // Add your content here
//           ],
//         ),
//       ),
//       // Bottom navigation bar is static on every screen
//       bottomNavigationBar: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 16.0),
//         child: Container(
//           padding: EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(12),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.grey.withOpacity(0.2),
//                 spreadRadius: 2,
//                 blurRadius: 8,
//               ),
//             ],
//           ),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: [
//               _buildBottomNavItem(Icons.home, "Home", Colors.orange),
//               _buildBottomNavItem(Icons.food_bank, "Products", Colors.green),
//               _buildBottomNavItem(Icons.shopping_cart, "Orders", Colors.blue),
//               _buildBottomNavItem(Icons.payment, "Payments", Colors.purple),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildBottomNavItem(IconData icon, String label, Color color) {
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Icon(icon, color: color, size: 28),
//         SizedBox(height: 4),
//         Text(
//           label,
//           style: TextStyle(
//             fontSize: 12,
//             color: Colors.black,
//           ),
//         ),
//       ],
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileSettingsScreen extends StatefulWidget {
  final User user;

  ProfileSettingsScreen({required this.user});

  @override
  _ProfileSettingsScreenState createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Controllers for text fields
  late TextEditingController _nameController;
  late TextEditingController _shopNameController;
  late TextEditingController _mobileController;
  late TextEditingController _locationController;
  late TextEditingController _gstNumberController;
  late TextEditingController _upiIdController;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _shopNameController = TextEditingController();
    _mobileController = TextEditingController();
    _locationController = TextEditingController();
    _gstNumberController = TextEditingController();
    _upiIdController = TextEditingController();

    // Load vendor data
    _loadVendorData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shopNameController.dispose();
    _mobileController.dispose();
    _locationController.dispose();
    _gstNumberController.dispose();
    _upiIdController.dispose();
    super.dispose();
  }

  // Load vendor data from Firestore
  Future<void> _loadVendorData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      DocumentSnapshot vendorDoc =
      await _firestore.collection('vendors').doc(widget.user.uid).get();

      if (vendorDoc.exists) {
        Map<String, dynamic> data = vendorDoc.data() as Map<String, dynamic>;

        setState(() {
          _nameController.text = data['name'] ?? '';
          _shopNameController.text = data['shopName'] ?? '';
          _mobileController.text = data['mobile'] ?? '';
          _locationController.text = data['location'] ?? '';
          _gstNumberController.text = data['gstNumber'] ?? '';
          _upiIdController.text = data['upiId'] ?? '';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading profile: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Save vendor data to Firestore
  Future<void> _saveVendorData() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await _firestore.collection('vendors').doc(widget.user.uid).update({
        'name': _nameController.text,
        'shopName': _shopNameController.text,
        'mobile': _mobileController.text,
        'location': _locationController.text,
        'gstNumber': _gstNumberController.text,
        'upiId': _upiIdController.text,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Error updating profile: $e';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile')),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  // Validate UPI ID format
  String? _validateUpiId(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your UPI ID';
    }

    // Basic UPI ID validation (username@provider)
    final RegExp upiRegExp = RegExp(r'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+$');
    if (!upiRegExp.hasMatch(value)) {
      return 'Please enter a valid UPI ID (e.g., username@upi)';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile Settings'),
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red),
                  ),
                ),

              Text(
                'Personal Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),

              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              TextFormField(
                controller: _mobileController,
                decoration: InputDecoration(
                  labelText: 'Mobile Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your mobile number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),

              Text(
                'Business Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),

              TextFormField(
                controller: _shopNameController,
                decoration: InputDecoration(
                  labelText: 'Shop Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your shop name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your location';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              TextFormField(
                controller: _gstNumberController,
                decoration: InputDecoration(
                  labelText: 'GST Number',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your GST number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),

              Text(
                'Payment Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),

              // UPI ID field with validation
              TextFormField(
                controller: _upiIdController,
                decoration: InputDecoration(
                  labelText: 'UPI ID',
                  border: OutlineInputBorder(),
                  hintText: 'username@upi',
                  helperText: 'Enter your payment UPI ID (e.g., mobile@paytm)',
                ),
                validator: _validateUpiId,
              ),
              SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveVendorData,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: _isSaving
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}