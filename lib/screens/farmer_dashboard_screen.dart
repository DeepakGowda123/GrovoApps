import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter_carousel_slider/carousel_slider.dart';
import 'wishlist_screen.dart';
import 'cart_screen.dart';
import 'weather_service.dart';

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

  // Add these new weather-related variables
  final WeatherService _weatherService = WeatherService();
  WeatherInfo? _weatherInfo;
  String? _weatherError;

  List<Map<String, dynamic>> products = [];
  Map<String, List<Map<String, dynamic>>> _categorizedProducts = {};
  final String farmerId = FirebaseAuth.instance.currentUser!.uid; // Get logged-in farmer ID
  List<String> wishlist = []; // Store wishlist locally for UI update



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

  //brands logo
  List<Map<String, String>> brands = [
    {'name': 'BAYER', 'image': 'assets/brands/brand1.png'},
    {'name': 'SYNGENTA', 'image': 'assets/brands/brand2.png'},
    {'name': 'BASF', 'image': 'assets/brands/brand7.png'},
    {'name': 'FMC', 'image': 'assets/brands/brand4.png'},
    {'name': 'ADAMA', 'image': 'assets/brands/brand5.png'},
    {'name': 'IFFCO', 'image': 'assets/brands/brand8.png'},
  ];


  String? farmerName;
  String? farmerMobile;
  String? farmerEmail;
  String searchQuery = '';
  //String weatherInfo = 'Loading...'; // Default value while loading

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    _loadProfile();
    _loadProducts();
    fetchWishlist(); // Load wishlist when screen opens
    _loadWeather(); // Call the function to load weather data
    //_getLocationAndFetchWeather();
  }

  // Add this new weather loading function
  Future<void> _loadWeather() async {
    try {
      setState(() => _weatherError = null);
      final weatherInfo = await _weatherService.getWeather();
      setState(() => _weatherInfo = weatherInfo);
    } on WeatherException catch (e) {
      setState(() => _weatherError = e.toString());
    }
  }


  // add to cart
  Future<void> addToCart(String productId, double price) async {
    try {
      // First check if the farmer document exists and has a cart field
      final farmerDoc = await _firestore.collection('farmers').doc(widget.user.uid).get();

      if (!farmerDoc.exists) {
        throw Exception('Farmer document not found');
      }

      final cartItem = {
        'productId': productId,
        'price': price,  // Include price
        'quantity': 1,
        //'timestamp': FieldValue.serverTimestamp()
      };

      if (!(farmerDoc.data() as Map<String, dynamic>).containsKey('cart')) {
        // If cart doesn't exist, create it
        await _firestore.collection('farmers').doc(widget.user.uid).set({
          'cart': [cartItem]
        }, SetOptions(merge: true));
      } else {
        // If cart exists, add to it
        await _firestore.collection('farmers').doc(widget.user.uid).update({
          'cart': FieldValue.arrayUnion([cartItem])
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added to cart')),
      );
    } catch (e) {
      print('Error adding to cart: $e');  // Log the error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add to cart: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Fetch wishlist from Firestore
  Future<void> fetchWishlist() async {
    DocumentSnapshot farmerDoc = await _firestore.collection('farmers').doc(widget.user.uid).get();
    if (farmerDoc.exists && (farmerDoc.data() as Map<String, dynamic>).containsKey('wishlist')) {
      setState(() {
        wishlist = List<String>.from((farmerDoc.data() as Map<String, dynamic>)['wishlist']);
      });
    }
  }

  /// Toggle Wishlist (Add/Remove)
  Future<void> toggleWishlist(String productId) async {
    final farmerRef = _firestore.collection('farmers').doc(widget.user.uid);

    try {
      if (wishlist.contains(productId)) {
        await farmerRef.update({
          'wishlist': FieldValue.arrayRemove([productId])
        });
        setState(() {
          wishlist.remove(productId);
        });
      } else {
        await farmerRef.update({
          'wishlist': FieldValue.arrayUnion([productId])
        });
        setState(() {
          wishlist.add(productId);
        });
      }

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(wishlist.contains(productId)
              ? 'Added to wishlist'
              : 'Removed from wishlist'),
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating wishlist'),
          backgroundColor: Colors.red,
        ),
      );
    }
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

      // Create a Map to store products by category
      Map<String, List<Map<String, dynamic>>> categorizedProducts = {};

      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        String category = data['category'] ?? 'Unknown';
        String imageUrl = data['image'] ?? 'https://via.placeholder.com/150';

        if (!categorizedProducts.containsKey(category)) {
          categorizedProducts[category] = [];
        }

        categorizedProducts[category]!.add({
          'id': doc.id,  // Add this line
          'name': data['name'] ?? 'Unknown Product',
          'price': data['price'] ?? 0,
          'discountPrice': data['discount price'] ?? data['price'], // Handle Discount
          'image': imageUrl,
          'brand': data['brand'] ?? 'Unknown Brand',
          'shopName': data['shopName'] ?? 'Unknown Shop',
          'availability': data['availability'] ?? 0,
        });
      }

      setState(() {
        _categorizedProducts = categorizedProducts;
      });

    } catch (e) {
      print('🔥 Error loading products: $e');
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

  Widget buildWishlistButton(String productId) {
    bool isWishlisted = wishlist.contains(productId);
    return IconButton(
      icon: Icon(
        isWishlisted ? Icons.favorite : Icons.favorite_border,
        color: isWishlisted ? Colors.red : Colors.grey,
      ),
      onPressed: () => toggleWishlist(productId),
    );
  }

  // Add this new weather display widget
  Widget _buildWeatherInfo() {
    if (_weatherError != null) {
      return Text(
        _weatherError!,
        style: TextStyle(fontSize: 14, color: Colors.red[300]),
      );
    }

    if (_weatherInfo == null) {
      return Text(
        'Loading weather...',
        style: TextStyle(fontSize: 14, color: Colors.white70),
      );
    }

    return GestureDetector(
      onTap: _loadWeather, // Refresh weather on tap
      child: Row(
        children: [
          // Icon and Temperature
          Text(
            '${_weatherInfo!.weatherIcon} ${_weatherInfo!.temperature.toStringAsFixed(1)}°C',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          SizedBox(width: 4),

          // Description Text (Wrapped in Expanded to prevent overflow)
          Expanded(
            child: Text(
              _weatherInfo!.description,
              style: TextStyle(fontSize: 14, color: Colors.white70),
              overflow: TextOverflow.ellipsis, // Ensures text doesn't overflow
            ),
          ),
        ],
      ),
    );
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
            IconButton(
              icon: Icon(Icons.favorite),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => WishlistScreen()),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.shopping_cart),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CartScreen()),
                );
              },
            ),
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
                  Expanded(  // Wrap the column with Expanded to ensure it doesn't overflow
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hello, ${farmerName ?? 'User'}',
                            style: TextStyle(fontSize: 20, color: Colors.white)),
                        _buildWeatherInfo(),
                      ],
                    ),
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


        // Grid-Based Categories (Second Display)
        Padding(
        padding: EdgeInsets.all(16),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Text(
    "Categories",
    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),
    SizedBox(height: 10),
    GridView.builder(
    shrinkWrap: true,
    physics: NeverScrollableScrollPhysics(), // Prevents scrolling inside GridView
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 3, // 3 columns
    crossAxisSpacing: 10,
    mainAxisSpacing: 10,
    childAspectRatio: 0.9, // Adjust size
    ),
    itemCount: categories.length,
    itemBuilder: (context, index) {
    var category = categories[index];
    return GestureDetector(
      onTap: () {
        // Navigate to category-specific product list (To be implemented)
        print("Selected Category: ${category['name']}");
      },
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 5,
                ),
              ],
            ),
            child: Image.asset(
              category['image']!,
              width: 50,
              height: 50,
              fit: BoxFit.contain,
            ),
          ),
          SizedBox(height: 5),
          Text(
            category['name']!,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
    },
    ),
    ],
    ),
        ),

                // Brands Section
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Brands",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(), // Prevents grid from scrolling
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3, // 3 brands per row
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.0,
                        ),
                        itemCount: brands.length,
                        itemBuilder: (context, index) {
                          var brand = brands[index];
                          return GestureDetector(
                            onTap: () {
                              print("Selected Brand: ${brand['name']}");
                            },
                            child: Column(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: Image.asset(
                                    brand['image']!,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  brand['name']!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // ALL PRODUCTS SECTION
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "ALL PRODUCTS",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),

                      // Loop through each category and display its products
                      Column(
                        children: _categorizedProducts.entries.map((entry) {
                          String categoryName = entry.key;
                          List<Map<String, dynamic>> productsList = entry.value;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                categoryName,
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 8),

                              Container(
                                height: MediaQuery.of(context).size.height * 0.32, // More height for details
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: productsList.length,
                                  itemBuilder: (context, index) {
                                    var product = productsList[index];

                                    // Calculate discount percentage
                                    double discountPercent = ((product['price'] - product['discountPrice']) / product['price']) * 100;
                                    String discountText = "${discountPercent.toStringAsFixed(0)}% OFF"; // Round off

                                    return Card(
                                      margin: EdgeInsets.only(right: 10, bottom: 10), // Added bottom spacing
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        side: BorderSide(color: Colors.black26, width: 0.8), // Light black border
                                      ),
                                      color: Theme.of(context).scaffoldBackgroundColor, // Matches screen color
                                      child: Container(
                                        width: MediaQuery.of(context).size.width * 0.42,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100], // Card background
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: Colors.black26, width: 0.8), // Light black border
                                          boxShadow: [
                                            BoxShadow(color: Colors.black12, blurRadius: 5),
                                          ],
                                        ),
                                        child: Stack(
                                          children: [
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                // Product Image with Discount Badge
                                                Stack(
                                                  children: [
                                                    ClipRRect(
                                                      borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                                                      child: Image.network(
                                                        product['image'],
                                                        height: MediaQuery.of(context).size.height * 0.15,
                                                        width: double.infinity,
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (context, error, stackTrace) {
                                                          return Container(
                                                            height: MediaQuery.of(context).size.height * 0.15,
                                                            color: Colors.grey[300],
                                                            child: Icon(Icons.image_not_supported, size: 50),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                    // Discount Badge
                                                    Positioned(
                                                      top: 8,
                                                      left: 8,
                                                      child: Container(
                                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color: Colors.orange,
                                                          borderRadius: BorderRadius.circular(5),
                                                        ),
                                                        child: Text(
                                                          discountText,
                                                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),

                                                // Product Details
                                                Padding(
                                                  padding: EdgeInsets.all(8),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        product['name'],
                                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                      SizedBox(height: 3),
                                                      Text(
                                                        product['brand'],
                                                        style: TextStyle(fontSize: 12, color: Colors.grey),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                      SizedBox(height: 5),

                                                      // Prices
                                                      Row(
                                                        children: [
                                                          Text(
                                                            "₹${product['discountPrice']}",
                                                            style: TextStyle(
                                                              fontWeight: FontWeight.bold,
                                                              fontSize: 14,
                                                              color: Colors.green,
                                                            ),
                                                          ),
                                                          SizedBox(width: 5),
                                                          Text(
                                                            "₹${product['price']}",
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: Colors.grey,
                                                              decoration: TextDecoration.lineThrough,
                                                            ),
                                                          ),
                                                        ],
                                                      ),

                                                      SizedBox(height: 5),

                                                      // Availability & Shop
                                                      Text(
                                                        "From: ${product['shopName']}",
                                                        style: TextStyle(fontSize: 12, color: Colors.grey),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),

                                                      Text(
                                                        "Stock: ${product['availability']}",
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: product['availability'] > 0 ? Colors.blue : Colors.red,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),

                                            // add to cart icon
                                            Positioned(
                                              bottom: 8,
                                              right: 8,
                                              child: ElevatedButton.icon(
                                                icon: Icon(Icons.shopping_cart, size: 16),
                                                label: Text('Add'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.green,
                                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                ),
                                                onPressed: () => addToCart(product['id'], product['discountPrice']),
                                              ),
                                            ),

                                            // Heart Icon for Favorites
                                            Positioned(
                                              top: 8,
                                              right: 8,
                                              child: buildWishlistButton(product['id'] ?? product['name']), // Using name as fallback ID
                                            ),
                                          ],
                                        ),
                                      ),
                                    );

                                  },
                                ),
                              ),
                              SizedBox(height: 20), // Space between categories
                            ],
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                // More sections (Grid Categories, Brands, Products) can be added here...
              ],
          ),
        ),
    );
  }
}