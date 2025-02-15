import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'add_product_screen.dart';

class ViewProductsScreen extends StatefulWidget {
  final User user;

  ViewProductsScreen({required this.user});

  @override
  _ViewProductsScreenState createState() => _ViewProductsScreenState();
}

class _ViewProductsScreenState extends State<ViewProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All Categories';
  String _availabilityFilter = 'All';
  String _searchQuery = '';
  int totalStock = 0;
  String mostAddedCategory = '';
  Set<String> _selectedProducts = {}; // Store selected product IDs
  bool _isSelectionMode = false; // Track selection mode


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          "My Products",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, size: 30, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddProductScreen(user: widget.user),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Analytics Dashboard
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('products')
                  .where('vendorId', isEqualTo: widget.user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final products = snapshot.data!.docs;
                totalStock = 0;
                mostAddedCategory = '';

                // Calculate total stock and most added category
                Map<String, int> categoryCount = {};
                products.forEach((product) {
                  totalStock += (product['availability'] as num).toInt();

                  String category = product['category'] ?? 'Unknown';
                  categoryCount[category] = (categoryCount[category] ?? 0) + 1;
                });

                // Find the most added category
                if (categoryCount.isNotEmpty) {
                  var mostAddedCategoryEntry = categoryCount.entries
                      .reduce((curr, next) => curr.value > next.value ? curr : next);
                  mostAddedCategory = mostAddedCategoryEntry.key;
                }

                return Container(
                  padding: EdgeInsets.all(16),
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 10, offset: Offset(0, 4))],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          Text("Total Products", style: TextStyle(color: Colors.grey)),
                          SizedBox(height: 5),
                          Text("${products.length}", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        children: [
                          Text("Total Stock", style: TextStyle(color: Colors.grey)),
                          SizedBox(height: 5),
                          Text("$totalStock", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        children: [
                          Text("Most Added Category", style: TextStyle(color: Colors.grey)),
                          SizedBox(height: 5),
                          Text(mostAddedCategory, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

            // Search and Filters Section
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (query) {
                        setState(() {
                          _searchQuery = query.toLowerCase();
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Search Products',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: Colors.blue),
                        ),
                        prefixIcon: Icon(Icons.search, color: Colors.blue),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  _buildFilterDropdown(
                    value: _selectedCategory,
                    items: ['All Categories', 'Fertilizer', 'Herbicides', 'Fungicides', 'Nutrients', 'Insecticides', 'Seeds', 'Machinery'],
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value!;
                      });
                    },
                  ),
                  SizedBox(width: 10),
                  _buildFilterDropdown(
                    value: _availabilityFilter,
                    items: ['All', 'In Stock', 'Out of Stock'],
                    onChanged: (value) {
                      setState(() {
                        _availabilityFilter = value!;
                      });
                    },
                  ),
                ],
              ),
            ),

            // Product List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('products')
                    .where('vendorId', isEqualTo: widget.user.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text("No products available."));
                  }

                  final products = snapshot.data!.docs;

                  // Apply search and filter logic
                  final filteredProducts = products.where((product) {
                    final name = product['name'].toLowerCase();
                    final matchesSearch = name.contains(_searchQuery);
                    final category = _selectedCategory == 'All Categories' || product['category'] == _selectedCategory;
                    final availability = _availabilityFilter == 'All'
                        ? true
                        : (_availabilityFilter == 'In Stock' ? product['availability'] > 0 : product['availability'] == 0);

                    return matchesSearch && category && availability;
                  }).toList();

                  return ListView.builder(
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      return _buildProductCard(product);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),



      // Bottom Navigation Bar for Bulk Actions
      bottomNavigationBar: _isSelectionMode
          ? BottomAppBar(
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text("${_selectedProducts.length} selected", style: TextStyle(fontSize: 16)),
            ElevatedButton.icon(
              icon: Icon(Icons.delete, color: Colors.white),
              label: Text("Delete Selected"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => _showBulkDeleteBottomSheet(context),
            ),
            ElevatedButton.icon(
              icon: Icon(Icons.clear, color: Colors.white),
              label: Text("Cancel"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
              onPressed: () {
                setState(() {
                  _selectedProducts.clear();
                  _isSelectionMode = false;
                });
              },
            ),
          ],
        ),
      )
          : null,
    );
  }

  Widget _buildFilterDropdown({
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: DropdownButton<String>(
        value: value,
        icon: Icon(Icons.filter_list, color: Colors.blue),
        iconSize: 24,
        style: TextStyle(color: Colors.black),
        onChanged: onChanged,
        underline: SizedBox(),
        items: items.map((category) => DropdownMenuItem<String>(value: category, child: Text(category))).toList(),
      ),
    );
  }

  Widget _buildProductCard(DocumentSnapshot product) {
    bool isSelected = _selectedProducts.contains(product.id); // Check if selected

    return GestureDetector(
      onLongPress: () {
        setState(() {
          _isSelectionMode = true;
          _selectedProducts.add(product.id);
        });
      },
      onTap: () {
        if (_isSelectionMode) {
          setState(() {
            if (_selectedProducts.contains(product.id)) {
              _selectedProducts.remove(product.id);
              if (_selectedProducts.isEmpty) {
                _isSelectionMode = false; // Exit selection mode if none are selected
              }
            } else {
              _selectedProducts.add(product.id);
            }
          });
        }
      },
      child: Card(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 8,
        shadowColor: Colors.grey.withOpacity(0.2),
        color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.white, // Highlight selected items
        child: ListTile(
          contentPadding: EdgeInsets.all(16),
          leading: Stack(
            clipBehavior: Clip.none,
            children: [
              product['image'] != null && product['image'].isNotEmpty
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  product['image'],
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return SizedBox(
                      width: 60,
                      height: 60,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image, color: Colors.grey),
                ),
              )
                  : Icon(Icons.image, color: Colors.blue, size: 60),
              if (product['availability'] == 0)
                Positioned(
                  top: -5,
                  right: -10,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "Out of Stock",
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          title: Text(product['name'] ?? '', style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text("Price: \$${product['price']} - Available: ${product['availability']} items"),
          trailing: _isSelectionMode
              ? Icon(
            isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isSelected ? Colors.blue : Colors.grey,
          )
              : Wrap(
            spacing: 10,
            children: [
              IconButton(
                icon: Icon(Icons.edit, color: Colors.orange),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddProductScreen(
                        user: widget.user,
                        productId: product.id,
                        existingProductData: product,
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  _showDeleteConfirmationBottomSheet(context, product);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }




  void _showDeleteConfirmationBottomSheet(BuildContext context, DocumentSnapshot product) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Delete Product", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Text("Are you sure you want to delete this product?"),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("Cancel"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        if (product['image'] != null) {
                          String imageUrl = product['image'];
                          Reference imageRef = FirebaseStorage.instance.refFromURL(imageUrl);
                          await imageRef.delete();
                        }
                        await FirebaseFirestore.instance.collection('products').doc(product.id).delete();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Product deleted successfully")));
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to delete product: $e")));
                      }
                      Navigator.pop(context);
                    },
                    child: Text("Delete"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }


  void _showBulkDeleteBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Delete Selected Products", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Text("Are you sure you want to delete ${_selectedProducts.length} products?"),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("Cancel"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        for (String productId in _selectedProducts) {
                          DocumentSnapshot product = await FirebaseFirestore.instance.collection('products').doc(productId).get();
                          if (product.exists && product['image'] != null) {
                            String imageUrl = product['image'];
                            Reference imageRef = FirebaseStorage.instance.refFromURL(imageUrl);
                            await imageRef.delete();
                          }
                          await FirebaseFirestore.instance.collection('products').doc(productId).delete();
                        }
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Products deleted successfully")));
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to delete products: $e")));
                      }
                      setState(() {
                        _selectedProducts.clear();
                        _isSelectionMode = false;
                      });
                      Navigator.pop(context);
                    },
                    child: Text("Delete"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

}
