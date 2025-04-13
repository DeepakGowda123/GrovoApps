import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'add_product_screen.dart';
import 'order_management_screen.dart';
import 'profile_setting_screen.dart';
import 'payments_screen.dart';
import 'notifications_screen.dart';

class VendorDashboardScreen extends StatelessWidget {
  final User user;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  VendorDashboardScreen({required this.user});

  // Fetch vendor details from Firestore
  Future<Map<String, dynamic>> getVendorDetails() async {
    DocumentSnapshot vendorDoc =
    await _firestore.collection('vendors').doc(user.uid).get();
    return vendorDoc.data() as Map<String, dynamic>;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: FutureBuilder<Map<String, dynamic>>(
          future: getVendorDetails(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Text(
                "Welcome!",
                style: TextStyle(color: Colors.black),
              );
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return Text(
                "Error loading profile",
                style: TextStyle(color: Colors.black),
              );
            }

            var vendorData = snapshot.data!;
            return Text(
              "Hello, ${vendorData['name']}",
              style: TextStyle(color: Colors.black),
            );
          },
        ),
        actions: [
          // IconButton(
          //   icon: Icon(Icons.notifications, color: Colors.black),
          //   onPressed: () {
          //     // Navigate to Notifications Screen
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(
          //         builder: (context) => NotificationsScreen(user: user), // Pass user here
          //       ),
          //     );
          //   },
          // ),
          IconButton(
            icon: Icon(Icons.account_circle, color: Colors.black),
            onPressed: () {
              // Navigate to Profile Management Screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileSettingsScreen(user: user), // Pass user here
                ),
              );
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search Bar
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: "Search for products or orders",
                            prefixIcon: Icon(Icons.search),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),

                      // Featured Banner
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Boost Your Sales",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      "Add new products or manage orders with ease.",
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.trending_up,
                                  color: Colors.white, size: 50),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 20),

                      // Grid Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          children: [
                            _buildDashboardOption(
                              context,
                              "Profile Management",
                              Icons.person,
                              Colors.green,
                                  () {
                                // Navigate to Profile Management Screen
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ProfileSettingsScreen(user: user), // Pass user here
                                  ),
                                );
                              },
                            ),
                            _buildDashboardOption(
                              context,
                              "Add Products",
                              Icons.add_circle,
                              Colors.blue,
                                  () {
                                // Navigate to Add Products Screen
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        AddProductScreen(user: user), // Pass user here
                                  ),
                                );
                              },
                            ),
                            _buildDashboardOption(
                              context,
                              "Order Fulfillment",
                              Icons.shopping_cart,
                              Colors.orange,
                                  () {
                                // Navigate to Order Fulfillment Screen
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        OrderManagementScreen(user: user), // Pass user here
                                  ),
                                );
                              },
                            ),
                            _buildDashboardOption(
                              context,
                              "Payments",
                              Icons.payment,
                              Colors.purple,
                                  () {
                                // Navigate to Payments Screen
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        PaymentsScreen(user: user), // Pass user here
                                  ),
                                );
                              },
                            ),
                            _buildDashboardOption(
                              context,
                              "Notifications",
                              Icons.notifications,
                              Colors.red,
                                  () {
                                // Navigate to Notifications Screen
                                // Navigator.push(
                                //   context,
                                //   // MaterialPageRoute(
                                //   //   builder: (context) =>
                                //   //       //NotificationsScreen(user: user), // Pass user here
                                //   // ),
                                // );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      // Fixed bottom navigation bar added here
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildBottomNavItem(Icons.home, "Home", Colors.orange, () {
                // Add the action for the "Home" navigation here
              }),
              _buildBottomNavItem(Icons.food_bank, "Products", Colors.green, () {
                // Add the action for the "Products" navigation here
              }),
              _buildBottomNavItem(Icons.shopping_cart, "Orders", Colors.blue, () {
                // Add the action for the "Orders" navigation here
              }),
              _buildBottomNavItem(Icons.payment, "Payments", Colors.purple, () {
                // Add the action for the "Payments" navigation here
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardOption(BuildContext context, String title,
      IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 8,
            ),
          ],
        ),
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.white),
            SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
