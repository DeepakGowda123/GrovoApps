import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class TaskDetailScreen extends StatefulWidget {
  final String taskId;
  final Map<String, dynamic> task;

  const TaskDetailScreen({
    super.key,
    required this.task,
    required this.taskId,
  });

  @override
  _TaskDetailScreenState createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  bool _isTaskAccepted = false;
  bool _loading = false;
  Map<String, dynamic>? _landlordInfo;
  bool _hasRatedLandlord = false;
  Map<String, dynamic>? _taskData; // Store real-time task data

  @override
  void initState() {
    super.initState();
    _checkIfAlreadyAccepted();
    _fetchLandlordInfo();
    _listenToTaskUpdates(); // Listen for real-time updates
  }

  // Listen to real-time task updates
  void _listenToTaskUpdates() {
    final currentUid = FirebaseAuth.instance.currentUser!.uid;

    FirebaseFirestore.instance
        .collection('farmers')
        .doc(currentUid)
        .collection('acceptedRequests')
        .doc(widget.taskId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        setState(() {
          _taskData = snapshot.data();
          _hasRatedLandlord = _taskData?['workerRated'] == true;
        });

        // Check if task just got completed and worker hasn't rated yet
        final status = _taskData?['status'];
        if (status == 'completed' && !_hasRatedLandlord) {
          // Small delay to ensure UI is built before showing dialog
          Future.delayed(const Duration(milliseconds: 500), () {
            _showLandlordRatingDialog();
          });
        }
      }
    });
  }

  Future<void> _fetchLandlordInfo() async {
    try {
      final landlordId = widget.task['landlordId'];
      if (landlordId != null) {
        final landlordDoc = await FirebaseFirestore.instance
            .collection('farmers')
            .doc(landlordId)
            .get();

        if (landlordDoc.exists) {
          setState(() {
            _landlordInfo = landlordDoc.data();
          });
        }
      }
    } catch (e) {
      print('Error fetching landlord info: $e');
    }
  }

  Future<void> _checkIfAlreadyAccepted() async {
    final currentUid = FirebaseAuth.instance.currentUser!.uid;

    final snapshot = await FirebaseFirestore.instance
        .collection('farmers')
        .doc(currentUid)
        .collection('acceptedRequests')
        .doc(widget.taskId)
        .get();

    setState(() {
      _isTaskAccepted = snapshot.exists;
      if (snapshot.exists) {
        _taskData = snapshot.data();
        _hasRatedLandlord = _taskData?['workerRated'] == true;
      }
    });
  }

  Future<void> _acceptTask() async {
    setState(() => _loading = true);

    final worker = FirebaseAuth.instance.currentUser!;
    final workerUid = worker.uid;

    final workerDoc = await FirebaseFirestore.instance
        .collection('farmers')
        .doc(workerUid)
        .get();

    final workerData = workerDoc.data() ?? {};

    final acceptedTaskData = {
      ...widget.task,
      'taskId': widget.taskId,
      'status': 'accepted',
      'acceptedAt': FieldValue.serverTimestamp(),
    };

    try {
      // Get landlord ID directly from task data
      final landlordId = widget.task['landlordId'];

      if (landlordId == null) {
        throw 'Landlord ID not found in task data!';
      }

      // 1. Update the task under the landlord's requests
      await FirebaseFirestore.instance
          .collection('farmers')
          .doc(landlordId)
          .collection('workerRequests')
          .doc(widget.taskId)
          .update({
        'status': 'accepted',
        'acceptedBy': workerUid,
        'acceptedWorkerName': workerData['name'] ?? '',
        'acceptedWorkerMobile': workerData['mobile'] ?? '',
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      // 2. Save a copy under worker's acceptedRequests
      await FirebaseFirestore.instance
          .collection('farmers')
          .doc(workerUid)
          .collection('acceptedRequests')
          .doc(widget.taskId)
          .set(acceptedTaskData);

      setState(() => _isTaskAccepted = true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Task accepted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to accept task: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _showLandlordRatingDialog() async {
    if (_hasRatedLandlord) return; // Prevent showing dialog again

    final landlordId = widget.task['landlordId'];
    final workerId = FirebaseAuth.instance.currentUser!.uid;
    final taskId = widget.taskId;
    double rating = 3;
    final TextEditingController reviewController = TextEditingController();

    await showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing without rating
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Rate the Landlord'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please rate your experience with the landlord:'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    onPressed: () {
                      setDialogState(() {
                        rating = (index + 1).toDouble();
                      });
                    },
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.orange,
                      size: 32,
                    ),
                  );
                }),
              ),
              Text(
                '${rating.toInt()}/5 stars',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reviewController,
                decoration: const InputDecoration(
                  hintText: 'Leave a review (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _submitLandlordRating(
                  landlordId,
                  workerId,
                  rating,
                  reviewController.text,
                  taskId,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('⭐ Rating submitted successfully!')),
                );
              },
              child: const Text('Submit Rating'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitLandlordRating(
      String landlordId,
      String workerId,
      double rating,
      String review,
      String taskId,
      ) async {
    try {
      final landlordRef = FirebaseFirestore.instance.collection('farmers').doc(landlordId);

      // Use regular Timestamp instead of server timestamp for arrays
      final ratingData = {
        'workerId': workerId,
        'rating': rating,
        'review': review,
        'taskId': taskId,
        'timestamp': Timestamp.now(), // This is fine for arrays
      };

      // Get current document data
      final docSnapshot = await landlordRef.get();
      final currentData = docSnapshot.data();
      final current = currentData?['ratingAsLandlord'];

      if (current == null) {
        // Create the whole map if it doesn't exist
        await landlordRef.set({
          ...currentData ?? {}, // Preserve existing data
          'ratingAsLandlord': {
            'totalRating': rating,
            'totalReviews': 1,
            'reviews': [ratingData],
          },
        }, SetOptions(merge: true)); // Use merge to avoid overwriting other fields
      } else {
        // Update existing values
        double currentTotalRating = (current['totalRating'] ?? 0.0).toDouble();
        int currentTotalReviews = (current['totalReviews'] ?? 0).toInt();

        // Calculate new average rating
        double newTotalRating = ((currentTotalRating * currentTotalReviews) + rating) / (currentTotalReviews + 1);

        await landlordRef.update({
          'ratingAsLandlord.totalRating': newTotalRating,
          'ratingAsLandlord.totalReviews': currentTotalReviews + 1,
          'ratingAsLandlord.reviews': FieldValue.arrayUnion([ratingData]),
        });
      }

      // Mark task as rated by worker
      await FirebaseFirestore.instance
          .collection('farmers')
          .doc(workerId)
          .collection('acceptedRequests')
          .doc(taskId)
          .update({'workerRated': true});

      await FirebaseFirestore.instance
          .collection('farmers')
          .doc(landlordId)
          .collection('workerRequests')
          .doc(taskId)
          .update({'workerRated': true});

      setState(() {
        _hasRatedLandlord = true;
      });

      print('✅ Rating submitted successfully!');
    } catch (e) {
      print('❌ Error submitting rating: $e');
      // Show error to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to submit rating: $e')),
      );
    }
  }


  Widget _buildLandlordInfo() {
    if (_landlordInfo == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Loading landlord information...'),
        ),
      );
    }

    final landlordRating = _landlordInfo!['ratingAsLandlord'];
    final totalRating = landlordRating?['totalRating'] ?? 0.0;
    final totalReviews = landlordRating?['totalReviews'] ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Landlord Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('👨‍🌾 Name: ${_landlordInfo!['name'] ?? 'N/A'}'),
            Text('📱 Mobile: ${_landlordInfo!['mobile'] ?? 'N/A'}'),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.orange, size: 20),
                const SizedBox(width: 4),
                Text(
                  totalRating > 0
                      ? '${totalRating.toStringAsFixed(1)} ($totalReviews reviews)'
                      : 'No ratings yet',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final currentTaskData = _taskData ?? widget.task;
    final taskStatus = currentTaskData['status'] ?? 'paid';
    final paymentReleased = currentTaskData['paymentReleased'] == true;
    final amount = widget.task['amount'] ?? '0';

    if (taskStatus == 'accepted') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: const Column(
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Task Accepted',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              '✅ You have accepted this task. Please complete the work as agreed. The landlord will mark it as completed once done.',
              style: TextStyle(color: Colors.blue, fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (taskStatus == 'completed') {
      return Column(
        children: [
          // Completion Status Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              children: [
                const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Task Completed! 🎉',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Great job! The landlord has marked this task as completed.',
                  style: TextStyle(color: Colors.green, fontSize: 14),
                ),
                if (!_hasRatedLandlord) ...[
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _showLandlordRatingDialog,
                    icon: const Icon(Icons.star),
                    label: const Text('Rate Landlord'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(40),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Payment Release Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: paymentReleased ? Colors.green.shade50 : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: paymentReleased ? Colors.green.shade200 : Colors.orange.shade200,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      paymentReleased ? Icons.account_balance_wallet : Icons.schedule,
                      color: paymentReleased ? Colors.green : Colors.orange,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        paymentReleased ? 'Payment Released! 💰' : 'Payment Processing ⏳',
                        style: TextStyle(
                          color: paymentReleased ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  paymentReleased
                      ? '✅ ₹$amount has been released to your account via Razorpay.'
                      : '⏳ Payment of ₹$amount will be released shortly via Razorpay.',
                  style: TextStyle(
                    color: paymentReleased ? Colors.green : Colors.orange,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final currentTaskData = _taskData ?? task;
    final taskStatus = currentTaskData['status'] ?? 'paid';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        backgroundColor: taskStatus == 'completed' ? Colors.green.shade100 : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task Information Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Task Information',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: taskStatus == 'completed'
                                ? Colors.green.shade100
                                : taskStatus == 'accepted'
                                ? Colors.blue.shade100
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            taskStatus.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: taskStatus == 'completed'
                                  ? Colors.green.shade700
                                  : taskStatus == 'accepted'
                                  ? Colors.blue.shade700
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('👨‍🌾 Work Type: ${task['workType'] ?? ''}',
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 6),
                    Text('📍 Location: ${task['location'] ?? ''}'),
                    Text('📅 Start: ${task['startDate'] ?? ''}'),
                    Text('📅 End: ${task['endDate'] ?? ''}'),
                    Text('⏰ Duration: ${task['workDuration'] ?? ''}'),
                    Text('👤 Gender: ${task['gender'] ?? ''}'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Text(
                        '💰 Payment: ₹${task['amount'] ?? ''}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Landlord Information Card
            _buildLandlordInfo(),

            const SizedBox(height: 16),

            // Status Card (replaces old action buttons logic)
            _buildStatusCard(),

            const SizedBox(height: 16),

            // Accept Task Button (only for unpaid tasks)
            if (taskStatus == 'paid' && !_isTaskAccepted)
              ElevatedButton.icon(
                onPressed: _loading ? null : _acceptTask,
                icon: const Icon(Icons.check_circle_outline),
                label: Text(_loading ? 'Accepting...' : 'Accept Task'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),

            const SizedBox(height: 20),

            // Map Placeholder
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('Map will be displayed here', style: TextStyle(color: Colors.grey)),
                    Text('(Add Google Maps API key to enable)', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

