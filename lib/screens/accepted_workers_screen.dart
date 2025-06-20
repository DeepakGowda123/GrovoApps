import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AcceptedWorkersScreen extends StatelessWidget {
  final User user;
  const AcceptedWorkersScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final userId = user.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accepted Workers'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('farmers')
            .doc(userId)
            .collection('workerRequests')
            .where('status', whereIn: ['accepted', 'ongoing'])
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No accepted workers yet.'));
          }

          final tasks = snapshot.data!.docs;

          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index].data() as Map<String, dynamic>;
              final docId = tasks[index].id;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(task['workType'] ?? 'Work'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Worker: ${task['acceptedWorkerName'] ?? 'N/A'}'),
                      Text('Status: ${task['status']}'),
                      Text('Location: ${task['location']}'),
                      Text('Amount: ₹${task['amount']}'),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'Mark Ongoing') {
                        await _updateStatus(userId, docId, task, 'ongoing');
                      } else if (value == 'Mark Completed') {
                        // Show loading indicator
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );

                        try {
                          await _showPaymentAndRatingDialog(context, task, docId);
                          Navigator.pop(context); // Close loading indicator
                          await _updateStatus(userId, docId, task, 'completed');
                        } catch (e) {
                          Navigator.pop(context); // Close loading indicator
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      if (task['status'] == 'accepted')
                        const PopupMenuItem(
                          value: 'Mark Ongoing',
                          child: Text('Mark Ongoing'),
                        ),
                      const PopupMenuItem(
                        value: 'Mark Completed',
                        child: Text('Mark Completed'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _updateStatus(String landlordId, String taskId, Map<String, dynamic> task, String newStatus) async {
    final workerId = task['acceptedBy'];

    // Use batch write for atomic updates
    final batch = FirebaseFirestore.instance.batch();

    // Update landlord's document
    final landlordTaskRef = FirebaseFirestore.instance
        .collection('farmers')
        .doc(landlordId)
        .collection('workerRequests')
        .doc(taskId);
    batch.update(landlordTaskRef, {'status': newStatus});

    // Update worker's document
    final workerTaskRef = FirebaseFirestore.instance
        .collection('farmers')
        .doc(workerId)
        .collection('acceptedRequests')
        .doc(taskId);
    batch.update(workerTaskRef, {'status': newStatus});

    await batch.commit();
  }

  Future<void> _showPaymentAndRatingDialog(BuildContext context, Map<String, dynamic> task, String docId) async {
    final workerId = task['acceptedBy'];
    final workerName = task['acceptedWorkerName'] ?? 'Worker';
    final landlordId = task['landlordId'];
    final amount = task['amount'];

    final TextEditingController reviewController = TextEditingController();
    double rating = 3.0;

    await showDialog(
      context: context,
      barrierDismissible: false, // Prevent accidental dismissal
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Task Completed'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('₹$amount released to $workerName'),
                  const SizedBox(height: 20),
                  const Text('Rate the Worker'),
                  Slider(
                    value: rating,
                    onChanged: (value) => setState(() => rating = value),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: rating.toStringAsFixed(1),
                  ),
                  TextField(
                    controller: reviewController,
                    decoration: const InputDecoration(hintText: 'Write a review...'),
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    Navigator.pop(context);

                    try {
                      await _submitRatingToWorker(
                        workerId,
                        landlordId,
                        rating,
                        reviewController.text,
                        docId, // Use the document ID consistently
                      );

                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                          content: Text('Rating & Payment Completed!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text('Failed to submit rating: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      rethrow; // Re-throw to handle in the calling function
                    }
                  },
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitRatingToWorker(
      String workerId,
      String landlordId,
      double rating,
      String review,
      String taskId,
      ) async {
    print('---- Submitting Rating ----');
    print('workerId: $workerId');
    print('landlordId: $landlordId');
    print('rating: $rating');
    print('review: $review');
    print('taskId: $taskId');

    try {
      // First, get the landlord's name
      String landlordName = 'Unknown Landlord';
      try {
        final landlordDoc = await FirebaseFirestore.instance
            .collection('farmers')
            .doc(landlordId)
            .get();

        if (landlordDoc.exists) {
          final landlordData = landlordDoc.data();
          landlordName = landlordData?['name'] ?? 'Unknown Landlord';
          print('✅ Fetched landlord name: $landlordName');
        }
      } catch (e) {
        print('Warning: Could not fetch landlord name: $e');
      }

      final workerRef = FirebaseFirestore.instance.collection('farmers').doc(workerId);

      final ratingData = {
        'landlordId': landlordId,
        'landlordName': landlordName,
        'rating': rating,
        'review': review,
        'taskId': taskId,
        'timestamp': Timestamp.now(), // Use Timestamp.now() instead of FieldValue.serverTimestamp()
      };

      print('Attempting to write to worker: $workerId');
      print('Rating data to write: $ratingData');

      // Check if worker document exists first
      final workerDocSnapshot = await workerRef.get();
      print('Worker document exists: ${workerDocSnapshot.exists}');

      if (workerDocSnapshot.exists) {
        final currentData = workerDocSnapshot.data();
        print('Current worker data keys: ${currentData?.keys.toList()}');

        final currentRatingData = currentData?['ratingAsWorker'] ?? {};
        print('Current rating data: $currentRatingData');

        final currentTotalRating = (currentRatingData['totalRating'] ?? 0).toDouble();
        final currentTotalReviews = (currentRatingData['totalReviews'] ?? 0).toInt();
        final currentReviews = List<Map<String, dynamic>>.from(currentRatingData['reviews'] ?? []);

        final newTotalReviews = currentTotalReviews + 1;
        final newAverageRating = ((currentTotalRating * currentTotalReviews) + rating) / newTotalReviews;

        // Add the new review to the existing reviews
        currentReviews.add(ratingData);

        final updateData = {
          'ratingAsWorker': {
            'totalRating': newAverageRating,
            'totalReviews': newTotalReviews,
            'reviews': currentReviews,
          }
        };

        print('Update data: $updateData');

        // Use merge: true to ensure we don't overwrite other fields
        await workerRef.set(updateData, SetOptions(merge: true));

        print('✅ Rating data written successfully');

        // Verify the write by reading it back
        final verifyDoc = await workerRef.get();
        final verifyData = verifyDoc.data();
        print('✅ Verified written data: ${verifyData?['ratingAsWorker']}');

      } else {
        // Worker document doesn't exist, create it with rating data
        print('Creating new worker document with rating data');
        final newDocData = {
          'ratingAsWorker': {
            'totalRating': rating,
            'totalReviews': 1,
            'reviews': [ratingData],
          }
        };

        await workerRef.set(newDocData, SetOptions(merge: true));
        print('✅ Created new worker document with rating');
      }

    } catch (e) {
      print('❌ Error submitting rating: $e');
      print('❌ Error type: ${e.runtimeType}');
      print('❌ Stack trace: ${StackTrace.current}');
      throw Exception('Failed to submit rating: $e');
    }
  }
}