import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class OrderManagementScreen extends StatefulWidget {
  final User? user;
  const OrderManagementScreen({Key? key, this.user}) : super(key: key); // Fixed

  @override
  _OrderManagementScreenState createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Status options for dropdown
  final List<String> _statusOptions = [
    'paid',
    'order received',
    'processing',
    'shipped',
    'delivered'
  ];

  @override
  Widget build(BuildContext context) {
    final currentVendorId = _auth.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Management'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('orders')
            .where('vendorId', isEqualTo: currentVendorId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No orders found'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final orderData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              final orderId = snapshot.data!.docs[index].id;

              return OrderCard(
                orderData: orderData,
                orderId: orderId,
                statusOptions: _statusOptions,
                onStatusUpdate: (newStatus) => _updateOrderStatus(orderId, orderData['farmerId'], newStatus),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _updateOrderStatus(String orderId, String farmerId, String newStatus) async {
    try {
      // Update order status in Firestore
      await _firestore.collection('orders').doc(orderId).update({
        'status': newStatus,
      });

      // Send notification to farmer
      _sendStatusUpdateNotification(farmerId, orderId, newStatus);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order status updated to $newStatus')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e')),
      );
    }
  }

  Future<void> _sendStatusUpdateNotification(String farmerId, String orderId, String newStatus) async {
    // In a real app, you would use Firebase Cloud Messaging here
    // For now, we'll just store a notification in Firestore
    await _firestore.collection('notifications').add({
      'userId': farmerId,
      'title': 'Order Status Update',
      'message': 'Your order is now $newStatus',
      'orderId': orderId,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });
  }
}

class OrderCard extends StatelessWidget {
  final Map<String, dynamic> orderData;
  final String orderId;
  final List<String> statusOptions;
  final Function(String) onStatusUpdate;

  const OrderCard({
    Key? key,
    required this.orderData,
    required this.orderId,
    required this.statusOptions,
    required this.onStatusUpdate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final DateTime orderTime = (orderData['timestamp'] as Timestamp).toDate();
    final String currentStatus = orderData['status'] ?? 'paid';

    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${orderId.substring(0, 8)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '₹${orderData['totalPrice']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Product: ${orderData['productName']}'),
            Text('Quantity: ${orderData['quantity']}'),
            Text('Date: ${_formatDate(orderTime)}'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Status:'),
                DropdownButton<String>(
                  value: currentStatus,
                  items: statusOptions.map((status) {
                    return DropdownMenuItem<String>(
                      value: status,
                      child: Text(status),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    if (newValue != null && newValue != currentStatus) {
                      onStatusUpdate(newValue);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }
}

