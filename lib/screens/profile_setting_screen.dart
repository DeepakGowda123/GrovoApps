import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'vendor_dashboard_screen.dart'; // Import the vendor dashboard for the bottom nav bar

class ProfileSettingsScreen extends StatelessWidget {
  final User user;

  ProfileSettingsScreen({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profile Settings"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Your content for ProfileSettingsScreen
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text("Profile Settings Content goes here..."),
            ),
            // Add your content here
          ],
        ),
      ),
      // Bottom navigation bar is static on every screen
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
              _buildBottomNavItem(Icons.home, "Home", Colors.orange),
              _buildBottomNavItem(Icons.food_bank, "Products", Colors.green),
              _buildBottomNavItem(Icons.shopping_cart, "Orders", Colors.blue),
              _buildBottomNavItem(Icons.payment, "Payments", Colors.purple),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(IconData icon, String label, Color color) {
    return Column(
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
    );
  }
}
