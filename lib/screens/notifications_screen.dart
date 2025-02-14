import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import for the User class

class NotificationsScreen extends StatelessWidget {
  final User user; // Firebase User

  NotificationsScreen({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Notifications"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Content for Notifications Screen
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text("Notifications Screen Content goes here..."),
            ),
            // Add your content here
          ],
        ),
      ),
      // Static Bottom Navigation Bar
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
