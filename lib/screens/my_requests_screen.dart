import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyRequestsScreen extends StatelessWidget {
  const MyRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Center(child: Text('Not logged in'));
    }

    final farmerId = currentUser.uid;
    final requestsRef = FirebaseFirestore.instance
        .collection('farmers')
        .doc(farmerId)
        .collection('workerRequests')
        .orderBy('timestamp', descending: true);

    return Scaffold(
      appBar: AppBar(title: const Text('My Requests')),
      body: StreamBuilder<QuerySnapshot>(
        stream: requestsRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Error loading requests'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No requests yet.'));

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  title: Text('${data['workType']} (${data['location'] ?? "Unknown"})'),
                  subtitle: Text('Start: ${data['startDate'] ?? "-"}'),
                  trailing: _buildStatusChip(data['status']),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RequestDetailScreen(
                          requestId: doc.id,
                          requestData: data,
                          farmerId: farmerId,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(String? status) {
    final s = status ?? 'Unknown';
    Color color;
    switch (s) {
      case 'Pending':
        color = Colors.orange;
        break;
      case 'Accepted':
        color = Colors.blue;
        break;
      case 'Completed':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }
    return Chip(
      label: Text(s),
      backgroundColor: color.withOpacity(0.2),
      labelStyle: TextStyle(color: color),
    );
  }
}



class RequestDetailScreen extends StatelessWidget {
  final String farmerId;
  final String requestId;
  final Map<String, dynamic> requestData;

  const RequestDetailScreen({
    super.key,
    required this.farmerId,
    required this.requestId,
    required this.requestData,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = requestData['status'] == 'Completed';
    final isAccepted = requestData['status'] == 'Accepted' || requestData['workerId'] != null;

    return Scaffold(
      appBar: AppBar(title: Text('Request Details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Work Type: ${requestData['workType']}'),
            Text('Location: ${requestData['location']}'),
            Text('Start Date: ${requestData['startDate']}'),
            Text('Status: ${requestData['status']}'),
            const SizedBox(height: 10),
            if (isAccepted) Text('Assigned Worker ID: ${requestData['workerId'] ?? 'Unknown'}'),
            const Spacer(),
            if (!isCompleted && isAccepted)
              ElevatedButton(
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('farmers')
                      .doc(farmerId)
                      .collection('workerRequests')
                      .doc(requestId)
                      .update({'status': 'Completed'});

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Marked as Complete')),
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text('Mark as Complete'),
              ),
            if (isCompleted)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Give Rating'),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(5, (i) => const Icon(Icons.star_border)),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Thank you for rating! (mock)')),
                      );
                    },
                    child: const Text('Submit Rating'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
