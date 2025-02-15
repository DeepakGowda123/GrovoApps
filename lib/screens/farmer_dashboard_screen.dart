import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter_carousel_slider/carousel_slider.dart';

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
  List<Map<String, dynamic>> products = [];

  // Updated Categories
  // Updated Categories
  List<Map<String, String>> categories = [
    {'name': 'Fertilizers', 'image': 'assets/icons/fertilizer.png'},
    {'name': 'Herbicides', 'image': 'assets/icons/herbicide.png'},
    {'name': 'Fungicides', 'image': 'assets/icons/fungicide.png'},
    {'name': 'Nutrients', 'image': 'assets/icons/nutrient.png'},
    {'name': 'Insecticides', 'image': 'assets/icons/insecticide.png'},
    {'name': 'Seeds', 'image': 'assets/icons/seeds.png'},
    {'name': 'Machinery', 'image': 'assets/icons/machinery.png'},
  ];

  List<String> promoImages = [
    'assets/banners/banner1.jpg',
    'assets/banners/banner2.jpeg',
    'assets/banners/banner3.jpeg',
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
      QuerySnapshot querySnapshot =
      await _firestore.collection('products').get();
      setState(() {
        products = querySnapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          return {
            'name': data['name'] ?? 'Unknown Product',
            'price': data['price'] ?? '0',
            'discount': data['discount'] ?? '0',
            'image': data['image'] ?? 'https://via.placeholder.com/150',
          };
        }).toList();
      });
    } catch (e) {
      print('Error loading products: $e');
    }
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
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
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
                          Text('Hello, ${farmerName ?? 'User'}',
                              style: TextStyle(fontSize: 20, color: Colors.white)),
                          Text('31°C | Few Clouds ☁',
                              style: TextStyle(color: Colors.white)),
                        ],
                      ),
                      Spacer(),
                      Icon(Icons.account_balance_wallet, color: Colors.white),
                      SizedBox(width: 5),
                      Text('0 Coins', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                  SizedBox(height: 10),
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
                  ),
                ],
              ),
            ),

            // Horizontal Categories
            SizedBox(
              height: 110,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: categories.map((category) {
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black12, blurRadius: 5)
                            ],
                          ),
                          child: Image.asset(
                            category['image']!,
                            width: 50,
                            height: 50,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(Icons.error, color: Colors.red);
                            },
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(category['name']!,
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            // Auto Sliding Promotional Banner
            Container(
              height: 180,
              child: CarouselSlider(
                slideTransform: CubeTransform(),
                slideIndicator: CircularSlideIndicator(
                  padding: EdgeInsets.only(bottom: 10),
                ),
                enableAutoSlider: true, // ✅ Enable auto-sliding
                autoSliderDelay: Duration(seconds: 5), // ✅ Change slide every 2 seconds
                autoSliderTransitionTime: Duration(milliseconds: 2500), // ✅ Smooth transition
                unlimitedMode: true, // ✅ Enables infinite looping
                children: promoImages.map((image) {
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 5),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        image,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: Icon(Icons.image_not_supported, size: 50),
                          );
                        },
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            // More sections (Grid Categories, Brands, Products) can be added here...
          ],
        ),
      ),
    );
  }
}