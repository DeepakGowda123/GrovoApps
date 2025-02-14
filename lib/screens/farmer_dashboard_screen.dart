import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class FarmerDashboardScreen extends StatefulWidget {
  final User user;

  FarmerDashboardScreen({required this.user});

  @override
  _FarmerDashboardScreenState createState() => _FarmerDashboardScreenState();
}

class _FarmerDashboardScreenState extends State<FarmerDashboardScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late Razorpay _razorpay;
  List<Map<String, dynamic>> products = []; // Updated type definition

  // Updated Categories based on business requirements
  List<Map<String, String>> categories = [
    {'name': 'Fertilizers', 'image': 'assets/icons/fertilizer.png'},
    {'name': 'Pesticides', 'image': 'assets/icons/pesticide.png'},
    {'name': 'Machineries', 'image': 'assets/icons/machinery.png'},
  ];

  String? farmerName;
  String? farmerMobile;
  String? farmerEmail;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    _loadProfile();
    _loadProducts();
  }

  Future<void> _loadProfile() async {
    var user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot farmerDoc =
      await _firestore.collection('farmers').doc(user.uid).get();

      if (farmerDoc.exists) {
        var data = farmerDoc.data() as Map<String, dynamic>;
        setState(() {
          farmerName = data['name']?.toString() ?? 'User';
          farmerMobile = data['mobile']?.toString() ?? '';
          farmerEmail = user.email;
        });
      }
    }
  }

  Future<void> _loadProducts() async {
    try {
      QuerySnapshot querySnapshot = await _firestore.collection('products').get();
      setState(() {
        products = querySnapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          return {
            'name': data['name']?.toString() ?? 'Unknown Product',
            'price': data['price']?.toString() ?? '0',
            'discount': data['discount']?.toString() ?? '0',
            'image': data['image']?.toString() ?? 'https://via.placeholder.com/150',
          };
        }).toList();
      });
    } catch (e) {
      print('Error loading products: $e');
      // Handle error appropriately
    }
  }

  void _searchProducts(String query) {
    setState(() {
      searchQuery = query;
    });
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Payment Successful")));
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Payment Failed")));
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("External Wallet Used")));
  }

  @override
  void dispose() {
    super.dispose();
    _razorpay.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Farmer Dashboard'),
        elevation: 0,
        backgroundColor: Colors.green,
        actions: [
          IconButton(icon: Icon(Icons.notifications), onPressed: () {}),
          IconButton(icon: Icon(Icons.shopping_cart), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile & Weather Info
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, size: 40, color: Colors.green),
                      ),
                      SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, ${farmerName ?? 'User'}',
                            style: TextStyle(fontSize: 20, color: Colors.white),
                          ),
                          Text(
                            '31°C | Few Clouds ☁',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                      Spacer(),
                      Icon(Icons.account_balance_wallet, color: Colors.white),
                      SizedBox(width: 5),
                      Text('0 Coins', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                  SizedBox(height: 10),
                  // Search Bar
                  TextField(
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'Search products here',
                      prefixIcon: Icon(Icons.search),
                      suffixIcon: Icon(Icons.mic, color: Colors.orange),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: _searchProducts,
                  ),
                ],
              ),
            ),

            // Category Section
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white,
                          child: Image.asset(
                            category['image'] ?? 'assets/icons/default.png',
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(Icons.error, color: Colors.red);
                            },
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          category['name'] ?? 'Unknown',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Product Grid
            Padding(
              padding: EdgeInsets.all(10),
              child: GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.7,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  var product = products[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Image.network(
                            product['image'] ?? 'https://via.placeholder.com/150',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(child: Icon(Icons.error));
                            },
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product['name'] ?? 'Unknown Product',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '₹${product['price'] ?? '0'}',
                                style: TextStyle(color: Colors.green),
                              ),
                              Text(
                                'Saved ₹${product['discount'] ?? '0'}',
                                style: TextStyle(color: Colors.orange, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.local_hospital), label: 'Crop Doctor'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'My Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Agri Store'),
        ],
      ),
    );
  }
}