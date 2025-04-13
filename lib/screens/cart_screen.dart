// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:razorpay_flutter/razorpay_flutter.dart';
// import 'package:upi_india/upi_india.dart';
//
//
// class CartScreen extends StatefulWidget {
//   @override
//   _CartScreenState createState() => _CartScreenState();
// }
//
// class _CartScreenState extends State<CartScreen> {
//   final String farmerId = FirebaseAuth.instance.currentUser!.uid;
//   List<Map<String, dynamic>> cartItems = [];
//   bool isLoading = true;
//   String? error;
//   double totalAmount = 0;
//
//   // Add UPI instance
//   late Future<List<UpiApp>> _future;
//   late Razorpay _razorpay;
//
//
//   @override
//   void initState() {
//     super.initState();
//     fetchCartItems();
//     _future = UpiIndia().getAllUpiApps();
//     _initializeRazorpay();
//
//   }
//
//   void _initializeRazorpay() {
//     _razorpay = Razorpay();
//     _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
//     _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
//     _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
//   }
//
//   @override
//   void dispose() {
//     _razorpay.clear();
//     super.dispose();
//   }
//
//   void _handlePaymentSuccess(PaymentSuccessResponse response) {
//     _showPaymentResultDialog('Payment Successful!', true);
//     // Clear cart and update order status
//     _processSuccessfulPayment();
//   }
//
//   void _handlePaymentError(PaymentFailureResponse response) {
//     _showPaymentResultDialog('Payment Failed: ${response.message}', false);
//   }
//
//   void _handleExternalWallet(ExternalWalletResponse response) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text("External Wallet Selected: ${response.walletName}")),
//     );
//   }
//
//   Future<void> _startRazorpayPayment() async {
//     var options = {
//       'key': 'YOUR_RAZORPAY_KEY',
//       'amount': (totalAmount * 100).toInt(), // Convert to paise
//       'name': 'Farmer Store',
//       'description': 'Payment for cart items',
//       // 'prefill': {
//       //   'contact': farmerMobile,
//       //   'email': farmerEmail,
//       // }
//     };
//
//     try {
//       _razorpay.open(options);
//     } catch (e) {
//       _showPaymentResultDialog('Error: ${e.toString()}', false);
//     }
//   }
//
//   Future<void> _startUpiPayment(UpiApp app) async {
//     final UpiIndia upiIndia = UpiIndia();
//
//     final UpiResponse response = await upiIndia.startTransaction(
//       app: app,
//       receiverUpiId: "your-merchant-upi-id@upi", // Replace with your UPI ID
//       receiverName: "Farmer Store",
//       transactionRefId: "TXN${DateTime.now().millisecondsSinceEpoch}",
//       transactionNote: 'Payment for Cart Items',
//       amount: totalAmount,
//     );
//
//     _handleUpiResponse(response);
//   }
//
//   void _handleUpiResponse(UpiResponse response) {
//     switch (response.status) {
//       case UpiPaymentStatus.SUCCESS:
//         _showPaymentResultDialog('Payment Successful!', true);
//         _processSuccessfulPayment();
//         break;
//       case UpiPaymentStatus.SUBMITTED:
//         _showPaymentResultDialog('Payment Submitted', true);
//         break;
//       case UpiPaymentStatus.FAILURE:
//         _showPaymentResultDialog('Payment Failed!', false);
//         break;
//       default:
//         _showPaymentResultDialog('Payment Failed!', false);
//         break;
//     }
//   }
//
//   Future<void> _processSuccessfulPayment() async {
//     try {
//       // Create order document
//       await FirebaseFirestore.instance.collection('orders').add({
//         'farmerId': farmerId,
//         'items': cartItems,
//         'totalAmount': totalAmount,
//         'status': 'paid',
//         'timestamp': FieldValue.serverTimestamp(),
//       });
//
//       // Clear cart
//       await FirebaseFirestore.instance
//           .collection('farmers')
//           .doc(farmerId)
//           .update({'cart': []});
//
//       // Refresh cart
//       fetchCartItems();
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error processing order: ${e.toString()}')),
//       );
//     }
//   }
//
//   void _showPaymentResultDialog(String message, bool success) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text(success ? 'Success' : 'Error'),
//           content: Text(message),
//           icon: Icon(
//             success ? Icons.check_circle : Icons.error,
//             color: success ? Colors.green : Colors.red,
//             size: 48,
//           ),
//           actions: [
//             TextButton(
//               child: Text('OK'),
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//
//   void _showPaymentOptions() {
//     showModalBottomSheet(
//       context: context,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (BuildContext context) {
//         return Container(
//           padding: EdgeInsets.all(16),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text(
//                 'Select Payment Method',
//                 style: TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               SizedBox(height: 20),
//               // Razorpay Option
//               ListTile(
//                 leading: Image.asset(
//                   'assets/razorpay_icon.png',
//                   width: 32,
//                   height: 32,
//                 ),
//                 title: Text('Pay with Razorpay'),
//                 subtitle: Text('Credit/Debit Card, NetBanking, etc.'),
//                 onTap: () {
//                   Navigator.pop(context);
//                   _startRazorpayPayment();
//                 },
//               ),
//               Divider(),
//               // UPI Apps
//               ListTile(
//                 title: Text('UPI Payment Apps'),
//               ),
//               FutureBuilder<List<UpiApp>>(
//                 future: _future,
//                 builder: (context, snapshot) {
//                   if (snapshot.hasError) {
//                     return Padding(
//                       padding: EdgeInsets.all(16),
//                       child: Text('Error: ${snapshot.error}'),
//                     );
//                   }
//
//                   if (!snapshot.hasData) {
//                     return Center(child: CircularProgressIndicator());
//                   }
//
//                   return GridView.count(
//                     shrinkWrap: true,
//                     crossAxisCount: 4,
//                     childAspectRatio: 1,
//                     children: snapshot.data!.map((UpiApp app) {
//                       return InkWell(
//                         onTap: () {
//                           Navigator.pop(context);
//                           _startUpiPayment(app);
//                         },
//                         child: Column(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             Image.memory(
//                               app.icon,
//                               height: 48,
//                               width: 48,
//                             ),
//                             SizedBox(height: 4),
//                             Text(
//                               app.name,
//                               textAlign: TextAlign.center,
//                               style: TextStyle(fontSize: 12),
//                             ),
//                           ],
//                         ),
//                       );
//                     }).toList(),
//                   );
//                 },
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
//
//   Future<void> fetchCartItems() async {
//     try {
//       setState(() {
//         isLoading = true;
//         error = null;
//       });
//
//       // Get farmer's cart
//       DocumentSnapshot farmerDoc = await FirebaseFirestore.instance
//           .collection('farmers')
//           .doc(farmerId)
//           .get();
//
//       if (farmerDoc.exists && (farmerDoc.data() as Map<String, dynamic>).containsKey('cart')) {
//         List<dynamic> cart = List.from((farmerDoc.data() as Map<String, dynamic>)['cart']);
//
//         // Fetch product details for each cart item
//         List<Map<String, dynamic>> items = [];
//         double total = 0;
//
//         for (var cartItem in cart) {
//           DocumentSnapshot productDoc = await FirebaseFirestore.instance
//               .collection('products')
//               .doc(cartItem['productId'])
//               .get();
//
//           if (productDoc.exists) {
//             var productData = productDoc.data() as Map<String, dynamic>;
//             var item = {
//               'id': productDoc.id,
//               'quantity': cartItem['quantity'],
//               ...productData,
//             };
//             items.add(item);
//
//             // Calculate total (using discount price if available)
//             double itemPrice = (productData['discount price'] ?? productData['price']).toDouble();
//             total += itemPrice * cartItem['quantity'];
//           }
//         }
//
//         setState(() {
//           cartItems = items;
//           totalAmount = total;
//           isLoading = false;
//         });
//       } else {
//         setState(() {
//           cartItems = [];
//           totalAmount = 0;
//           isLoading = false;
//         });
//       }
//     } catch (e) {
//       setState(() {
//         error = 'Failed to load cart. Please try again.';
//         isLoading = false;
//       });
//     }
//   }
//
//   Future<void> updateQuantity(String productId, int newQuantity) async {
//     try {
//       // Get current cart
//       DocumentSnapshot farmerDoc = await FirebaseFirestore.instance
//           .collection('farmers')
//           .doc(farmerId)
//           .get();
//
//       List<dynamic> currentCart = List.from((farmerDoc.data() as Map<String, dynamic>)['cart']);
//
//       // Update quantity for the specific product
//       int itemIndex = currentCart.indexWhere((item) => item['productId'] == productId);
//
//       if (itemIndex != -1) {
//         if (newQuantity <= 0) {
//           // Remove item if quantity is 0 or less
//           currentCart.removeAt(itemIndex);
//         } else {
//           currentCart[itemIndex]['quantity'] = newQuantity;
//         }
//
//         // Update Firestore
//         await FirebaseFirestore.instance
//             .collection('farmers')
//             .doc(farmerId)
//             .update({'cart': currentCart});
//
//         // Refresh cart items
//         fetchCartItems();
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Failed to update quantity'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }
//
//   Future<void> removeFromCart(String productId) async {
//     try {
//       // Get current cart
//       DocumentSnapshot farmerDoc = await FirebaseFirestore.instance
//           .collection('farmers')
//           .doc(farmerId)
//           .get();
//
//       List<dynamic> currentCart = List.from((farmerDoc.data() as Map<String, dynamic>)['cart']);
//
//       // Remove the item
//       currentCart.removeWhere((item) => item['productId'] == productId);
//
//       // Update Firestore
//       await FirebaseFirestore.instance
//           .collection('farmers')
//           .doc(farmerId)
//           .update({'cart': currentCart});
//
//       // Show success message
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Removed from cart')),
//       );
//
//       // Refresh cart items
//       fetchCartItems();
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Failed to remove item'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Shopping Cart"),
//         backgroundColor: Colors.green,
//         actions: [
//           if (!isLoading && cartItems.isNotEmpty)
//             IconButton(
//               icon: Icon(Icons.refresh),
//               onPressed: fetchCartItems,
//             ),
//         ],
//       ),
//       body: isLoading
//           ? Center(child: CircularProgressIndicator())
//           : error != null
//           ? Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(error!, style: TextStyle(color: Colors.red)),
//             SizedBox(height: 16),
//             ElevatedButton(
//               onPressed: fetchCartItems,
//               child: Text('Retry'),
//             ),
//           ],
//         ),
//       )
//           : cartItems.isEmpty
//           ? Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
//             SizedBox(height: 16),
//             Text(
//               "Your cart is empty",
//               style: TextStyle(fontSize: 18, color: Colors.grey),
//             ),
//             SizedBox(height: 8),
//             Text(
//               "Add items to your cart to see them here",
//               style: TextStyle(color: Colors.grey),
//             ),
//           ],
//         ),
//       )
//           : Column(
//         children: [
//           Expanded(
//             child: ListView.builder(
//               itemCount: cartItems.length,
//               padding: EdgeInsets.all(8),
//               itemBuilder: (context, index) {
//                 var item = cartItems[index];
//                 return Card(
//                   elevation: 2,
//                   margin: EdgeInsets.symmetric(vertical: 4),
//                   child: ListTile(
//                     contentPadding: EdgeInsets.all(8),
//                     leading: ClipRRect(
//                       borderRadius: BorderRadius.circular(8),
//                       child: Image.network(
//                         item['image'],
//                         width: 80,
//                         height: 80,
//                         fit: BoxFit.cover,
//                         errorBuilder: (context, error, stackTrace) {
//                           return Container(
//                             width: 80,
//                             height: 80,
//                             color: Colors.grey[300],
//                             child: Icon(Icons.image_not_supported),
//                           );
//                         },
//                       ),
//                     ),
//                     title: Text(
//                       item['name'],
//                       style: TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                     subtitle: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           "₹${item['discount price'] ?? item['price']}",
//                           style: TextStyle(
//                             color: Colors.green,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         Row(
//                           children: [
//                             IconButton(
//                               icon: Icon(Icons.remove_circle_outline),
//                               onPressed: () => updateQuantity(
//                                   item['id'], item['quantity'] - 1),
//                             ),
//                             Text(
//                               item['quantity'].toString(),
//                               style: TextStyle(fontSize: 16),
//                             ),
//                             IconButton(
//                               icon: Icon(Icons.add_circle_outline),
//                               onPressed: () => updateQuantity(
//                                   item['id'], item['quantity'] + 1),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                     trailing: IconButton(
//                       icon: Icon(Icons.delete_outline, color: Colors.red),
//                       onPressed: () => removeFromCart(item['id']),
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//           // Total amount and checkout button
//           Container(
//             padding: EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black12,
//                   blurRadius: 4,
//                   offset: Offset(0, -2),
//                 ),
//               ],
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Text(
//                       'Total Amount:',
//                       style: TextStyle(
//                         fontSize: 14,
//                         color: Colors.grey[600],
//                       ),
//                     ),
//                     Text(
//                       '₹${totalAmount.toStringAsFixed(2)}',
//                       style: TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.green,
//                       ),
//                     ),
//                   ],
//                 ),
//                 ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.green,
//                     padding: EdgeInsets.symmetric(
//                       horizontal: 32,
//                       vertical: 16,
//                     ),
//                   ),
//                   onPressed: () {
//                     // Implement checkout functionality
//                     print('Proceed to checkout');
//                   },
//                   child: Text('Checkout'),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }



//=================================================================================================


//
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
//
// class CartScreen extends StatefulWidget {
//   @override
//   _CartScreenState createState() => _CartScreenState();
// }
//
// class _CartScreenState extends State<CartScreen> {
//   final String farmerId = FirebaseAuth.instance.currentUser!.uid;
//   List<Map<String, dynamic>> cartItems = [];
//   bool isLoading = true;
//   String? error;
//   double totalAmount = 0;
//
//   @override
//   void initState() {
//     super.initState();
//     fetchCartItems();
//   }
//
//   Future<void> fetchCartItems() async {
//     try {
//       setState(() {
//         isLoading = true;
//         error = null;
//       });
//
//       // Get farmer's cart
//       DocumentSnapshot farmerDoc = await FirebaseFirestore.instance
//           .collection('farmers')
//           .doc(farmerId)
//           .get();
//
//       if (farmerDoc.exists && (farmerDoc.data() as Map<String, dynamic>).containsKey('cart')) {
//         List<dynamic> cart = List.from((farmerDoc.data() as Map<String, dynamic>)['cart']);
//
//         // Fetch product details for each cart item
//         List<Map<String, dynamic>> items = [];
//         double total = 0;
//
//         for (var cartItem in cart) {
//           DocumentSnapshot productDoc = await FirebaseFirestore.instance
//               .collection('products')
//               .doc(cartItem['productId'])
//               .get();
//
//           if (productDoc.exists) {
//             var productData = productDoc.data() as Map<String, dynamic>;
//             var item = {
//               'id': productDoc.id,
//               'quantity': cartItem['quantity'],
//               ...productData,
//             };
//             items.add(item);
//
//             // Calculate total (using discount price if available)
//             double itemPrice = (productData['discount price'] ?? productData['price']).toDouble();
//             total += itemPrice * cartItem['quantity'];
//           }
//         }
//
//         setState(() {
//           cartItems = items;
//           totalAmount = total;
//           isLoading = false;
//         });
//       } else {
//         setState(() {
//           cartItems = [];
//           totalAmount = 0;
//           isLoading = false;
//         });
//       }
//     } catch (e) {
//       setState(() {
//         error = 'Failed to load cart. Please try again.';
//         isLoading = false;
//       });
//     }
//   }
//
//   Future<void> updateQuantity(String productId, int newQuantity) async {
//     try {
//       // Get current cart
//       DocumentSnapshot farmerDoc = await FirebaseFirestore.instance
//           .collection('farmers')
//           .doc(farmerId)
//           .get();
//
//       List<dynamic> currentCart = List.from((farmerDoc.data() as Map<String, dynamic>)['cart']);
//
//       // Update quantity for the specific product
//       int itemIndex = currentCart.indexWhere((item) => item['productId'] == productId);
//
//       if (itemIndex != -1) {
//         if (newQuantity <= 0) {
//           // Remove item if quantity is 0 or less
//           currentCart.removeAt(itemIndex);
//         } else {
//           currentCart[itemIndex]['quantity'] = newQuantity;
//         }
//
//         // Update Firestore
//         await FirebaseFirestore.instance
//             .collection('farmers')
//             .doc(farmerId)
//             .update({'cart': currentCart});
//
//         // Refresh cart items
//         fetchCartItems();
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Failed to update quantity'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }
//
//   Future<void> removeFromCart(String productId) async {
//     try {
//       // Get current cart
//       DocumentSnapshot farmerDoc = await FirebaseFirestore.instance
//           .collection('farmers')
//           .doc(farmerId)
//           .get();
//
//       List<dynamic> currentCart = List.from((farmerDoc.data() as Map<String, dynamic>)['cart']);
//
//       // Remove the item
//       currentCart.removeWhere((item) => item['productId'] == productId);
//
//       // Update Firestore
//       await FirebaseFirestore.instance
//           .collection('farmers')
//           .doc(farmerId)
//           .update({'cart': currentCart});
//
//       // Show success message
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Removed from cart')),
//       );
//
//       // Refresh cart items
//       fetchCartItems();
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Failed to remove item'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Shopping Cart"),
//         backgroundColor: Colors.green,
//         actions: [
//           if (!isLoading && cartItems.isNotEmpty)
//             IconButton(
//               icon: Icon(Icons.refresh),
//               onPressed: fetchCartItems,
//             ),
//         ],
//       ),
//       body: isLoading
//           ? Center(child: CircularProgressIndicator())
//           : error != null
//           ? Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(error!, style: TextStyle(color: Colors.red)),
//             SizedBox(height: 16),
//             ElevatedButton(
//               onPressed: fetchCartItems,
//               child: Text('Retry'),
//             ),
//           ],
//         ),
//       )
//           : cartItems.isEmpty
//           ? Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
//             SizedBox(height: 16),
//             Text(
//               "Your cart is empty",
//               style: TextStyle(fontSize: 18, color: Colors.grey),
//             ),
//             SizedBox(height: 8),
//             Text(
//               "Add items to your cart to see them here",
//               style: TextStyle(color: Colors.grey),
//             ),
//           ],
//         ),
//       )
//           : Column(
//         children: [
//           Expanded(
//             child: ListView.builder(
//               itemCount: cartItems.length,
//               padding: EdgeInsets.all(8),
//               itemBuilder: (context, index) {
//                 var item = cartItems[index];
//                 return Card(
//                   elevation: 2,
//                   margin: EdgeInsets.symmetric(vertical: 4),
//                   child: ListTile(
//                     contentPadding: EdgeInsets.all(8),
//                     leading: ClipRRect(
//                       borderRadius: BorderRadius.circular(8),
//                       child: Image.network(
//                         item['image'],
//                         width: 80,
//                         height: 80,
//                         fit: BoxFit.cover,
//                         errorBuilder: (context, error, stackTrace) {
//                           return Container(
//                             width: 80,
//                             height: 80,
//                             color: Colors.grey[300],
//                             child: Icon(Icons.image_not_supported),
//                           );
//                         },
//                       ),
//                     ),
//                     title: Text(
//                       item['name'],
//                       style: TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                     subtitle: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           "₹${item['discount price'] ?? item['price']}",
//                           style: TextStyle(
//                             color: Colors.green,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         Row(
//                           children: [
//                             IconButton(
//                               icon: Icon(Icons.remove_circle_outline),
//                               onPressed: () => updateQuantity(
//                                   item['id'], item['quantity'] - 1),
//                             ),
//                             Text(
//                               item['quantity'].toString(),
//                               style: TextStyle(fontSize: 16),
//                             ),
//                             IconButton(
//                               icon: Icon(Icons.add_circle_outline),
//                               onPressed: () => updateQuantity(
//                                   item['id'], item['quantity'] + 1),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                     trailing: IconButton(
//                       icon: Icon(Icons.delete_outline, color: Colors.red),
//                       onPressed: () => removeFromCart(item['id']),
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//           // Total amount and checkout button
//           Container(
//             padding: EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black12,
//                   blurRadius: 4,
//                   offset: Offset(0, -2),
//                 ),
//               ],
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Text(
//                       'Total Amount:',
//                       style: TextStyle(
//                         fontSize: 14,
//                         color: Colors.grey[600],
//                       ),
//                     ),
//                     Text(
//                       '₹${totalAmount.toStringAsFixed(2)}',
//                       style: TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.green,
//                       ),
//                     ),
//                   ],
//                 ),
//                 ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.green,
//                     padding: EdgeInsets.symmetric(
//                       horizontal: 32,
//                       vertical: 16,
//                     ),
//                   ),
//                   onPressed: () {
//                     // Implement checkout functionality
//                     print('Proceed to checkout');
//                   },
//                   child: Text('Checkout'),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//


import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart'; // Add this import

class CartScreen extends StatefulWidget {
  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final String farmerId = FirebaseAuth.instance.currentUser!.uid;
  List<Map<String, dynamic>> cartItems = [];
  bool isLoading = true;
  String? error;
  double totalAmount = 0;

  // Initialize Razorpay
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    fetchCartItems();

    // Set up Razorpay instance
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear(); // Removes all listeners
    super.dispose();
  }

  Future<void> fetchCartItems() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      // Get farmer's cart
      DocumentSnapshot farmerDoc = await FirebaseFirestore.instance
          .collection('farmers')
          .doc(farmerId)
          .get();

      if (farmerDoc.exists && (farmerDoc.data() as Map<String, dynamic>).containsKey('cart')) {
        List<dynamic> cart = List.from((farmerDoc.data() as Map<String, dynamic>)['cart']);

        // Fetch product details for each cart item
        List<Map<String, dynamic>> items = [];
        double total = 0;

        for (var cartItem in cart) {
          DocumentSnapshot productDoc = await FirebaseFirestore.instance
              .collection('products')
              .doc(cartItem['productId'])
              .get();

          if (productDoc.exists) {
            var productData = productDoc.data() as Map<String, dynamic>;

            // Include vendor ID in the cart item
            var item = {
              'id': productDoc.id,
              'quantity': cartItem['quantity'],
              'vendorId': productData['vendorId'], // Make sure this field exists in your product documents
              ...productData,
            };
            items.add(item);

            // Calculate total (using discount price if available)
            double itemPrice = (productData['discount price'] ?? productData['price']).toDouble();
            total += itemPrice * cartItem['quantity'];
          }
        }

        setState(() {
          cartItems = items;
          totalAmount = total;
          isLoading = false;
        });
      } else {
        setState(() {
          cartItems = [];
          totalAmount = 0;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Failed to load cart. Please try again.';
        isLoading = false;
      });
    }
  }

  Future<void> updateQuantity(String productId, int newQuantity) async {
    try {
      // Get current cart
      DocumentSnapshot farmerDoc = await FirebaseFirestore.instance
          .collection('farmers')
          .doc(farmerId)
          .get();

      List<dynamic> currentCart = List.from((farmerDoc.data() as Map<String, dynamic>)['cart']);

      // Update quantity for the specific product
      int itemIndex = currentCart.indexWhere((item) => item['productId'] == productId);

      if (itemIndex != -1) {
        if (newQuantity <= 0) {
          // Remove item if quantity is 0 or less
          currentCart.removeAt(itemIndex);
        } else {
          currentCart[itemIndex]['quantity'] = newQuantity;
        }

        // Update Firestore
        await FirebaseFirestore.instance
            .collection('farmers')
            .doc(farmerId)
            .update({'cart': currentCart});

        // Refresh cart items
        fetchCartItems();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update quantity'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> removeFromCart(String productId) async {
    try {
      // Get current cart
      DocumentSnapshot farmerDoc = await FirebaseFirestore.instance
          .collection('farmers')
          .doc(farmerId)
          .get();

      List<dynamic> currentCart = List.from((farmerDoc.data() as Map<String, dynamic>)['cart']);

      // Remove the item
      currentCart.removeWhere((item) => item['productId'] == productId);

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('farmers')
          .doc(farmerId)
          .update({'cart': currentCart});

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Removed from cart')),
      );

      // Refresh cart items
      fetchCartItems();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove item'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Checkout process with Razorpay
  Future<void> startCheckout() async {
    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Your cart is empty!')),
      );
      return;
    }

    try {
      // Group cart items by vendor
      Map<String, List<Map<String, dynamic>>> vendorProducts = {};
      Map<String, double> vendorTotals = {};

      // Calculate totals per vendor
      for (var item in cartItems) {
        String vendorId = item['vendorId'];
        if (!vendorProducts.containsKey(vendorId)) {
          vendorProducts[vendorId] = [];
          vendorTotals[vendorId] = 0;
        }
        vendorProducts[vendorId]!.add(item);

        // Calculate using discount price if available
        double itemPrice = (item['discount price'] ?? item['price']).toDouble();
        vendorTotals[vendorId] = (vendorTotals[vendorId] ?? 0) +
            (itemPrice * item['quantity']);
      }

      // Create transfer data for all vendors
      List<Map<String, dynamic>> transfers = [];

      // Get UPI IDs for each vendor
      for (String vendorId in vendorProducts.keys) {
        DocumentSnapshot vendorDoc =
        await FirebaseFirestore.instance.collection('vendors').doc(vendorId).get();

        if (vendorDoc.exists) {
          Map<String, dynamic> vendorData = vendorDoc.data() as Map<String, dynamic>;
          String? upiId = vendorData['upiId'];

          if (upiId != null && upiId.isNotEmpty) {
            transfers.add({
              'account': upiId,
              'amount': (vendorTotals[vendorId]! * 100).toInt(), // Convert to paisa
              'currency': 'INR',
              'description': 'Payment for ${vendorData['shopName'] ?? 'products'}'
            });
          } else {
            // If vendor doesn't have UPI ID, show error
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('One or more vendors do not have a valid payment method. Please try again later.'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
        }
      }

      // Get farmer details for prefill
      DocumentSnapshot farmerDoc = await FirebaseFirestore.instance
          .collection('farmers')
          .doc(farmerId)
          .get();

      Map<String, dynamic> farmerData = {};
      if (farmerDoc.exists) {
        farmerData = farmerDoc.data() as Map<String, dynamic>;
      }

      // Create payment options for Razorpay
      var options = {
        'key': 'rzp_test_TTR8Gdu8mLDJUe', // Replace with your actual Razorpay key
        'amount': (totalAmount * 100).toInt(), // Convert to paisa
        'name': 'Farm Products',
        'description': 'Payment for farm products',
        'prefill': {
          'contact': farmerData['mobile'] ?? '',
          'email': farmerData['email'] ?? '',
          'name': farmerData['name'] ?? '',
        },
        'external': {
          'wallets': ['paytm', 'gpay', 'phonepe'],
        },
        'transfers': transfers,
      };

      _razorpay.open(options);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error starting checkout: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Payment success handler
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    // Create order entries for each vendor's products
    for (var item in cartItems) {
      String vendorId = item['vendorId'];
      double itemPrice = (item['discount price'] ?? item['price']).toDouble();

      // Create order document
      await FirebaseFirestore.instance.collection('orders').add({
        'farmerId': farmerId,
        'vendorId': vendorId,
        'productId': item['id'],
        'productName': item['name'],
        'quantity': item['quantity'],
        'price': itemPrice,
        'totalPrice': itemPrice * item['quantity'],
        'status': 'paid',
        'paymentId': response.paymentId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }

    // Clear farmer's cart
    await FirebaseFirestore.instance
        .collection('farmers')
        .doc(farmerId)
        .update({'cart': []});

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment successful! Your order has been placed.'),
        backgroundColor: Colors.green,
      ),
    );

    // Refresh cart
    setState(() {
      cartItems = [];
      totalAmount = 0;
    });
  }

  // Payment error handler
  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment failed: ${response.message ?? "Error occurred"}'),
        backgroundColor: Colors.red,
      ),
    );
  }

  // External wallet handler
  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment processing with ${response.walletName}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Shopping Cart"),
        backgroundColor: Colors.green,
        actions: [
          if (!isLoading && cartItems.isNotEmpty)
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: fetchCartItems,
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
              onPressed: fetchCartItems,
              child: Text('Retry'),
            ),
          ],
        ),
      )
          : cartItems.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "Your cart is empty",
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              "Add items to your cart to see them here",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      )
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: cartItems.length,
              padding: EdgeInsets.all(8),
              itemBuilder: (context, index) {
                var item = cartItems[index];
                return Card(
                  elevation: 2,
                  margin: EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(8),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        item['image'],
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
                      item['name'],
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "₹${item['discount price'] ?? item['price']}",
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.remove_circle_outline),
                              onPressed: () => updateQuantity(
                                  item['id'], item['quantity'] - 1),
                            ),
                            Text(
                              item['quantity'].toString(),
                              style: TextStyle(fontSize: 16),
                            ),
                            IconButton(
                              icon: Icon(Icons.add_circle_outline),
                              onPressed: () => updateQuantity(
                                  item['id'], item['quantity'] + 1),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => removeFromCart(item['id']),
                    ),
                  ),
                );
              },
            ),
          ),
          // Total amount and checkout button
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Total Amount:',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '₹${totalAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                  onPressed: startCheckout, // Connect to our Razorpay checkout function
                  child: Text('Checkout'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
