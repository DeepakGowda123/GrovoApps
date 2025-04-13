import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsWidget extends StatelessWidget {
  final User? user;

  const NotificationsWidget({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: user!.uid)
          .orderBy('timestamp', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Notifications',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AllNotificationsScreen(user: user),
                        ),
                      );
                    },
                    child: const Text('View All'),
                  ),
                ],
              ),
            ),
            ...snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final bool isRead = data['read'] ?? false;
              final timestamp = data['timestamp'] as Timestamp;

              return NotificationItem(
                title: data['title'] ?? 'Notification',
                message: data['message'] ?? '',
                time: timestamp.toDate(),
                isRead: isRead,
                notificationId: doc.id,
                orderId: data['orderId'],
              );
            }).toList(),
          ],
        );
      },
    );
  }
}

class NotificationItem extends StatelessWidget {
  final String title;
  final String message;
  final DateTime time;
  final bool isRead;
  final String notificationId;
  final String? orderId;

  const NotificationItem({
    Key? key,
    required this.title,
    required this.message,
    required this.time,
    required this.isRead,
    required this.notificationId,
    this.orderId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      color: isRead ? null : Colors.blue.shade50,
      child: InkWell(
        onTap: () {
          // Mark as read
          if (!isRead) {
            FirebaseFirestore.instance
                .collection('notifications')
                .doc(notificationId)
                .update({'read': true});
          }

          // If this notification is related to an order, navigate to order details
          if (orderId != null) {
            // Navigate to order detail
            // You'll need to implement order details screen for farmers
            _showOrderDetailsDialog(context, orderId!);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isRead)
                const Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child: Icon(Icons.circle, size: 12, color: Colors.blue),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(message),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(time),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  void _showOrderDetailsDialog(BuildContext context, String orderId) {
    FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .get()
        .then((snapshot) {
      if (snapshot.exists) {
        final orderData = snapshot.data()!;
        final DateTime orderTime = (orderData['timestamp'] as Timestamp).toDate();

        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Order #${orderId.substring(0, 8)}'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _detailRow('Product', orderData['productName']),
                    _detailRow('Quantity', orderData['quantity'].toString()),
                    _detailRow('Unit Price', '₹${orderData['price']}'),
                    _detailRow('Total Price', '₹${orderData['totalPrice']}'),
                    _detailRow('Status', orderData['status'] ?? 'paid'),
                    _detailRow('Order Date', _formatDetailDate(orderTime)),
                    _detailRow('Order ID', orderId),
                    _detailRow('Payment ID', orderData['paymentId'] ?? 'N/A'),

                    const SizedBox(height: 16),
                    _buildStatusTimeline(orderData['status'] ?? 'paid'),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      }
    });
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatDetailDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }

  Widget _buildStatusTimeline(String currentStatus) {
    final statuses = ['paid', 'order received', 'processing', 'shipped', 'delivered'];
    final currentIndex = statuses.indexOf(currentStatus);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Order Status:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...List.generate(statuses.length, (index) {
          final isCompleted = index <= currentIndex;
          return Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted ? Colors.green : Colors.grey,
                ),
                child: isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 12)
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                statuses[index],
                style: TextStyle(
                  fontWeight: currentIndex == index ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (index < statuses.length - 1)
                Container(
                  height: 30,
                  width: 2,
                  margin: const EdgeInsets.only(left: 9),
                  color: index < currentIndex ? Colors.green : Colors.grey.shade300,
                ),
            ],
          );
        }),
      ],
    );
  }
}

class AllNotificationsScreen extends StatelessWidget {
  final User? user;

  const AllNotificationsScreen({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: () {
              _markAllAsRead(context);
            },
            tooltip: 'Mark all as read',
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('Please log in to view notifications'))
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: user!.uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No notifications found'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final bool isRead = data['read'] ?? false;
              final timestamp = data['timestamp'] as Timestamp;

              return NotificationItem(
                title: data['title'] ?? 'Notification',
                message: data['message'] ?? '',
                time: timestamp.toDate(),
                isRead: isRead,
                notificationId: doc.id,
                orderId: data['orderId'],
              );
            },
          );
        },
      ),
    );
  }

  void _markAllAsRead(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark all as read?'),
        content: const Text('This will mark all your notifications as read.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Get all unread notifications for this user
              FirebaseFirestore.instance
                  .collection('notifications')
                  .where('userId', isEqualTo: user!.uid)
                  .where('read', isEqualTo: false)
                  .get()
                  .then((snapshot) {
                // Create a batch write to update all at once
                final batch = FirebaseFirestore.instance.batch();

                for (var doc in snapshot.docs) {
                  batch.update(doc.reference, {'read': true});
                }

                // Commit the batch
                return batch.commit();
              }).then((_) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All notifications marked as read')),
                );
              });
            },
            child: const Text('Mark All'),
          ),
        ],
      ),
    );
  }
}