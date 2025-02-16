import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WishlistService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Add product to wishlist
  Future<void> addToWishlist(String productId, Map<String, dynamic> productData) async {
    String? userId = _auth.currentUser?.uid;
    if (userId != null) {
      await _firestore.collection('farmers').doc(userId)
          .collection('wishlist')
          .doc(productId)
          .set(productData);
    }
  }

  // Remove product from wishlist
  Future<void> removeFromWishlist(String productId) async {
    String? userId = _auth.currentUser?.uid;
    if (userId != null) {
      await _firestore.collection('farmers').doc(userId)
          .collection('wishlist')
          .doc(productId)
          .delete();
    }
  }

  // Check if product is in wishlist
  Stream<bool> isProductInWishlist(String productId) {
    String? userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value(false);

    return _firestore.collection('farmers').doc(userId)
        .collection('wishlist')
        .doc(productId)
        .snapshots()
        .map((doc) => doc.exists);
  }
}
