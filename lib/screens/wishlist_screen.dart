import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WishlistScreen extends StatefulWidget {
  @override
  _WishlistScreenState createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final String farmerId = FirebaseAuth.instance.currentUser!.uid;
  List<Map<String, dynamic>> wishlistProducts = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchWishlistProducts();
  }

  Future<void> fetchWishlistProducts() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      // Get farmer's wishlist
      DocumentSnapshot farmerDoc = await FirebaseFirestore.instance
          .collection('farmers')
          .doc(farmerId)
          .get();

      if (farmerDoc.exists && (farmerDoc.data() as Map<String, dynamic>).containsKey('wishlist')) {
        List<String> wishlist = List<String>.from((farmerDoc.data() as Map<String, dynamic>)['wishlist']);

        // Fetch product details in parallel
        List<Future<DocumentSnapshot>> productFutures = wishlist
            .map((id) => FirebaseFirestore.instance.collection('products').doc(id).get())
            .toList();

        List<DocumentSnapshot> productDocs = await Future.wait(productFutures);

        List<Map<String, dynamic>> fetchedProducts = [];
        for (var i = 0; i < productDocs.length; i++) {
          if (productDocs[i].exists) {
            var data = productDocs[i].data() as Map<String, dynamic>;
            // Add the document ID to the product data
            fetchedProducts.add({
              'id': productDocs[i].id,
              ...data,
            });
          }
        }

        setState(() {
          wishlistProducts = fetchedProducts;
          isLoading = false;
        });
      } else {
        setState(() {
          wishlistProducts = [];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Failed to load wishlist. Please try again.';
        isLoading = false;
      });
    }
  }

  Future<void> removeFromWishlist(String productId) async {
    try {
      // Update Firestore
      await FirebaseFirestore.instance.collection('farmers').doc(farmerId).update({
        'wishlist': FieldValue.arrayRemove([productId])
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Product removed from wishlist'),
          duration: Duration(seconds: 2),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () => addBackToWishlist(productId),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove from wishlist'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> addBackToWishlist(String productId) async {
    try {
      await FirebaseFirestore.instance.collection('farmers').doc(farmerId).update({
        'wishlist': FieldValue.arrayUnion([productId])
      });
      fetchWishlistProducts(); // Refresh the list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to restore product'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Wishlist"),
        backgroundColor: Colors.green,
        actions: [
          if (!isLoading && wishlistProducts.isNotEmpty)
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: fetchWishlistProducts,
            ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : error != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(error!, style: TextStyle(color: Colors.red)),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: fetchWishlistProducts,
              child: Text('Retry'),
            ),
          ],
        ),
      )
          : wishlistProducts.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "Your wishlist is empty",
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              "Add items to your wishlist to see them here",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      )
          : ListView.builder(
        itemCount: wishlistProducts.length,
        padding: EdgeInsets.all(8),
        itemBuilder: (context, index) {
          var product = wishlistProducts[index];
          return Card(
            elevation: 2,
            margin: EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              contentPadding: EdgeInsets.all(8),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  product['image'],
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[300],
                      child: Icon(Icons.image_not_supported),
                    );
                  },
                ),
              ),
              title: Text(
                product['name'],
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 4),
                  Text(
                    "Brand: ${product['brand'] ?? 'N/A'}",
                    style: TextStyle(color: Colors.grey),
                  ),
                  Row(
                    children: [
                      Text(
                        "₹${product['discount price'] ?? product['price']}",
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (product['price'] != product['discount price'])
                        Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Text(
                            "₹${product['price']}",
                            style: TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              trailing: IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () {
                  removeFromWishlist(product['id']);
                  setState(() {
                    wishlistProducts.removeAt(index);
                  });
                },
              ),
            ),
          );
        },
      ),
    );
  }
}