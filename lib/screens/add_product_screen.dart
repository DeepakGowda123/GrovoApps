import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'dart:io';
import 'view_products_screen.dart';

class AddProductScreen extends StatefulWidget {
  final User user;
  final String? productId;
  final DocumentSnapshot? existingProductData;

  AddProductScreen({
    required this.user,
    this.productId,
    this.existingProductData,
  });

  @override
  _AddProductScreenState createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _discountPriceController = TextEditingController();
  final TextEditingController _availabilityController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  String _selectedCategory = 'Fertilizer';
  File? _selectedImage;
  bool _isUploading = false;
  String? _shopName;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  void initState() {
    super.initState();
    _fetchShopName();

    // If editing an existing product, pre-fill fields
    if (widget.existingProductData != null) {
      final productData = widget.existingProductData!.data() as Map<String, dynamic>? ?? {};

      _nameController.text = productData['name'] ?? '';
      _descriptionController.text = productData['description'] ?? '';
      _priceController.text = productData['price']?.toString() ?? '';
      _discountPriceController.text = productData.containsKey('discountPrice') ? productData['discountPrice'].toString() : '';
      _availabilityController.text = productData['availability']?.toString() ?? '';
      _brandController.text = productData.containsKey('brand') ? productData['brand'] : '';
      _selectedCategory = productData['category'] ?? 'Fertilizer';
    }
  }

  Future<void> _fetchShopName() async {
    try {
      final shopData = await _firestore
          .collection('vendors')
          .doc(widget.user.uid)
          .get();

      if (shopData.exists && shopData.data() != null) {
        setState(() {
          _shopName = shopData.data()!['shopName'] ?? 'Unknown Shop';
        });
      } else {
        setState(() {
          _shopName = 'Unknown Shop';
        });
      }
    } catch (error) {
      print('Error fetching shop name: $error');
      setState(() {
        _shopName = 'Unknown Shop';
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _deleteOldImageIfNeeded() async {
    if (widget.existingProductData != null && widget.existingProductData!['image'] != null) {
      try {
        String oldImageUrl = widget.existingProductData!['image'];
        Reference oldImageRef = _storage.refFromURL(oldImageUrl);
        await oldImageRef.delete();
      } catch (error) {
        print('Failed to delete old image: $error');
      }
    }
  }

  Future<String> _uploadImage(File image) async {
    String fileName =
        '${widget.user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    Reference ref = _storage.ref().child('product_images').child(fileName);
    await ref.putFile(
      image,
      SettableMetadata(customMetadata: {'vendorId': widget.user.uid}),
    );
    return await ref.getDownloadURL();
  }


  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isUploading = true;
    });

    try {
      // If editing and a new image is selected, delete the old image
      if (widget.productId != null && _selectedImage != null) {
        await _deleteOldImageIfNeeded();
      }

      // Determine image URL: upload if new image is selected, otherwise use the existing image URL
      String imageUrl = widget.existingProductData != null && _selectedImage == null
          ? widget.existingProductData!['image']
          : await _uploadImage(_selectedImage!);

      if (widget.productId != null) {
        // Update existing product
        await _firestore.collection('products').doc(widget.productId).update({
          'name': _nameController.text,
          'description': _descriptionController.text,
          'price': double.parse(_priceController.text),
          'discount price': double.parse(_priceController.text),
          'availability': int.parse(_availabilityController.text),
          'category': _selectedCategory,
          'brand': _brandController.text,
          'image': imageUrl,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } else {
        // Add a new product
        await _firestore.collection('products').add({
          'vendorId': widget.user.uid,
          'shopName': _shopName ?? 'Unknown Shop',
          'name': _nameController.text,
          'description': _descriptionController.text,
          'price': double.parse(_priceController.text),
          'discount price': double.parse(_priceController.text),
          'availability': int.parse(_availabilityController.text),
          'category': _selectedCategory,
          'brand': _brandController.text,
          'image': imageUrl,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }


      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 120,
                  child: Lottie.asset(
                    'assets/product_success1.json',
                    repeat: false,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Product added/updated successfully!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('OK'),
                ),
              ],
            ),
          );
        },
      );

      // Reset the form
      _formKey.currentState!.reset();
      setState(() {
        _selectedImage = null;
        _isUploading = false;
      });
    } catch (error) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add/update product: $error')),
      );
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.productId == null ? "Add Product" : "Edit Product"),
        actions: [
          IconButton(
            icon: Icon(Icons.list),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ViewProductsScreen(user: widget.user)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(_nameController, 'Product Name', 'Enter product name'),
              SizedBox(height: 16),
              _buildTextField(_descriptionController, 'Description', 'Enter product details', maxLines: 3),
              SizedBox(height: 16),
              _buildTextField(_priceController, 'Current Price', 'Enter product price', keyboardType: TextInputType.number),
              SizedBox(height: 16),
              _buildTextField(_discountPriceController, 'Discount Price (Optional)', 'Enter discount price', keyboardType: TextInputType.number),
              SizedBox(height: 16),
              _buildTextField(_availabilityController, 'Stock Quantity', 'Enter stock quantity', keyboardType: TextInputType.number),
              SizedBox(height: 16),
              _buildDropdown(),
              SizedBox(height: 16),
              _buildTextField(_brandController, 'Brand Name', 'Enter brand name'),
              SizedBox(height: 16),
              _buildImagePicker(),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: !_isUploading ? _saveProduct : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isUploading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(widget.productId == null ? "Add Product" : "Update Product", style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint, {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label, hintText: hint, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
      validator: (value) => value!.isEmpty ? 'Please enter $label' : null,
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: InputDecoration(labelText: 'Category', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
      items: ['Fertilizer', 'Herbicides', 'Fungicides', 'Nutrients', 'Insecticides', 'Seeds', 'Machinery']
          .map((category) => DropdownMenuItem(value: category, child: Text(category)))
          .toList(),
      onChanged: (value) => setState(() => _selectedCategory = value!),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 150,
        decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(12)),
        child: _selectedImage == null && widget.existingProductData != null && widget.existingProductData!['image'] != null
            ? Image.network(widget.existingProductData!['image'], fit: BoxFit.cover)
            : _selectedImage != null
            ? Image.file(_selectedImage!, fit: BoxFit.cover)
            : Center(child: Icon(Icons.add_photo_alternate, size: 50)),
      ),
    );
  }
}
