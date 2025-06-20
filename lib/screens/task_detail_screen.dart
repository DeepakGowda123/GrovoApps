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



  @override
  void initState() {
    super.initState();
    _checkIfAlreadyAccepted();
    _fetchLandlordInfo();
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
      _hasRatedLandlord = snapshot.data()?['workerRated'] == true;
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

  Future<void> _completeTask() async {
    setState(() => _loading = true);

    try {
      final landlordId = widget.task['landlordId'];
      final workerUid = FirebaseAuth.instance.currentUser!.uid;

      // Update task status to completed
      await FirebaseFirestore.instance
          .collection('farmers')
          .doc(landlordId)
          .collection('workerRequests')
          .doc(widget.taskId)
          .update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });

      // Update in worker's accepted requests
      await FirebaseFirestore.instance
          .collection('farmers')
          .doc(workerUid)
          .collection('acceptedRequests')
          .doc(widget.taskId)
          .update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Task marked as completed!')),
      );

      // 👉 Show landlord rating dialog after completion
      await _showLandlordRatingDialog();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to complete task: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }



  Future<void> _showLandlordRatingDialog() async {
    if (_hasRatedLandlord) return; // 👈 Prevent showing dialog again


    final landlordId = widget.task['landlordId'];
    final workerId = FirebaseAuth.instance.currentUser!.uid;
    final taskId = widget.taskId;
    double rating = 3;
    final TextEditingController reviewController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rate the Landlord'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
              decoration: const InputDecoration(hintText: 'Leave a review'),
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
            child: const Text('Submit'),
          ),
        ],
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
    final landlordRef = FirebaseFirestore.instance.collection('farmers').doc(landlordId);

    final ratingData = {
      'workerId': workerId,
      'rating': rating,
      'review': review,
      'taskId': taskId,
      'timestamp': FieldValue.serverTimestamp(),
    };

    final docSnapshot = await landlordRef.get();
    final current = docSnapshot.data()?['ratingAsLandlord'];

    double totalRating = current?['totalRating'] ?? 0.0;
    int totalReviews = current?['totalReviews'] ?? 0;

    totalRating = ((totalRating * totalReviews) + rating) / (totalReviews + 1);

    await landlordRef.update({
      'ratingAsLandlord.totalRating': totalRating,
      'ratingAsLandlord.totalReviews': totalReviews + 1,
      'ratingAsLandlord.reviews': FieldValue.arrayUnion([ratingData])
    });

    // ✅ Mark task as rated by worker
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
                      ? '$totalRating ($totalReviews reviews)'
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

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final taskStatus = task['status'] ?? 'paid';

    return Scaffold(
      appBar: AppBar(title: const Text('Task Details')),
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
                    Text(
                      'Task Information',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
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

            const SizedBox(height: 20),

            // Action Buttons
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

            if (_isTaskAccepted && taskStatus == 'accepted')
              ElevatedButton.icon(
                onPressed: _loading ? null : _completeTask,
                icon: const Icon(Icons.task_alt),
                label: Text(_loading ? 'Completing...' : 'Mark as Completed'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),

            if (taskStatus == 'accepted')
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '✅ You have accepted this task. Complete the work and mark it as finished.',
                        style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),

            if (taskStatus == 'completed')
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '🎉 Task completed! You can now rate each other.',
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
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