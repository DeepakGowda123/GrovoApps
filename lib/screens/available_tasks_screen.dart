import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:grovo_app/screens/task_detail_screen.dart';

class AvailableTasksScreen extends StatefulWidget {
  const AvailableTasksScreen({super.key});

  @override
  State<AvailableTasksScreen> createState() => _AvailableTasksScreenState();
}

class _AvailableTasksScreenState extends State<AvailableTasksScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _isVerified = false;
  String? _aadharNumber;
  String? _userPhone;
  List<Map<String, dynamic>> _availableTasks = [];
  List<Map<String, dynamic>> _acceptedTasks = [];
  List<Map<String, dynamic>> _completedTasks = [];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkAadharStatus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkAadharStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('farmers').doc(user.uid).get();

    if (doc.exists) {
      final data = doc.data();
      final verified = data?['aadharVerified'];
      final aadhar = data?['aadharNumber'];

      if (verified == true && aadhar != null) {
        setState(() {
          _isVerified = true;
          _aadharNumber = aadhar;
        });

        await _fetchAllTasks();
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _verifyPhoneNumber(String phoneNumber) async {
    _showSnackBar('Sending OTP to $phoneNumber...');
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
        await _storeVerification();
      },
      verificationFailed: (e) {
        _showSnackBar('Verification failed: ${e.message}');
      },
      codeSent: (verificationId, _) => _showOtpDialog(verificationId),
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  void _showOtpDialog(String verificationId) {
    final TextEditingController _otpController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Enter OTP'),
        content: TextField(
          controller: _otpController,
          maxLength: 6,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'Enter 6-digit code'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            child: const Text('Verify'),
            onPressed: () async {
              try {
                final credential = PhoneAuthProvider.credential(
                  verificationId: verificationId,
                  smsCode: _otpController.text.trim(),
                );
                await FirebaseAuth.instance.signInWithCredential(credential);
                Navigator.pop(context);
                await _storeVerification();
              } catch (e) {
                _showSnackBar('Invalid OTP ❌');
              }
            },
          )
        ],
      ),
    );
  }

  Future<void> _storeVerification() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('farmers').doc(user.uid).set({
      'aadharVerified': true,
      'aadharNumber': _aadharNumber,
    }, SetOptions(merge: true));

    setState(() {
      _isVerified = true;
    });

    await _fetchAllTasks();

    _showSnackBar('Verification complete ✅');
  }

  Future<void> _fetchAllTasks() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Fetch available tasks (not accepted by anyone)
    await _fetchAvailableTasks();

    // Fetch worker's accepted/completed tasks
    await _fetchWorkerTasks();
  }

  Future<void> _fetchAvailableTasks() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final farmersSnapshot = await FirebaseFirestore.instance.collection('farmers').get();
    final List<Map<String, dynamic>> tasks = [];

    for (var farmerDoc in farmersSnapshot.docs) {
      if (farmerDoc.id == user.uid) continue; // Skip own tasks

      final workerRequests = await FirebaseFirestore.instance
          .collection('farmers')
          .doc(farmerDoc.id)
          .collection('workerRequests')
          .get();

      for (var taskDoc in workerRequests.docs) {
        final data = taskDoc.data();
        if (data['status'] == 'paid') { // Only available tasks
          tasks.add({
            ...data,
            'id': taskDoc.id,
            'landlordId': farmerDoc.id, // Ensure landlordId is included
          });
        }
      }
    }

    setState(() => _availableTasks = tasks);
  }

  Future<void> _fetchWorkerTasks() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Fetch all tasks accepted by this worker
    final acceptedTasksSnapshot = await FirebaseFirestore.instance
        .collection('farmers')
        .doc(user.uid)
        .collection('acceptedRequests')
        .get();

    final List<Map<String, dynamic>> acceptedTasks = [];
    final List<Map<String, dynamic>> completedTasks = [];

    for (var taskDoc in acceptedTasksSnapshot.docs) {
      final data = taskDoc.data();
      final taskWithId = {
        ...data,
        'id': taskDoc.id,
      };

      if (data['status'] == 'accepted') {
        acceptedTasks.add(taskWithId);
      } else if (data['status'] == 'completed') {
        completedTasks.add(taskWithId);
      }
    }

    setState(() {
      _acceptedTasks = acceptedTasks;
      _completedTasks = completedTasks;
    });
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _buildVerificationPrompt() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text(
            'Aadhar Verification',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            keyboardType: TextInputType.number,
            maxLength: 12,
            decoration: const InputDecoration(
              labelText: 'Enter 12-digit Aadhar Number',
              border: OutlineInputBorder(),
            ),
            onChanged: (val) => _aadharNumber = val,
          ),
          const SizedBox(height: 12),
          TextField(
            keyboardType: TextInputType.phone,
            maxLength: 10,
            decoration: const InputDecoration(
              labelText: 'Phone Number (for OTP)',
              border: OutlineInputBorder(),
            ),
            onChanged: (val) => _userPhone = val,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              if (_aadharNumber?.length != 12) {
                _showSnackBar('Enter valid Aadhar number');
                return;
              }
              if (_userPhone?.length != 10) {
                _showSnackBar('Enter valid phone number');
                return;
              }
              _verifyPhoneNumber('+91$_userPhone');
            },
            icon: const Icon(Icons.message),
            label: const Text('Send OTP'),
          )
        ],
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task, {String? statusLabel, Color? statusColor}) {
    if (task == null) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Row(
          children: [
            Expanded(
              child: Text(
                '${task['workType']} - ₹${task['amount']}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (statusLabel != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor?.withOpacity(0.1) ?? Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor ?? Colors.grey),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: statusColor ?? Colors.grey.shade700,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text('📍 ${task['location']} • ⏰ ${task['workDuration']}'),
            Text('📅 ${task['startDate']} - ${task['endDate']}'),
            if (task['status'] == 'completed' && task['paymentReleased'] == true)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: const Text(
                  '💰 Payment Released',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TaskDetailScreen(
                task: task,
                taskId: task['id'],
              ),
            ),
          ).then((_) {
            // Refresh tasks when coming back from task detail screen
            _fetchAllTasks();
          });
        },
      ),
    );
  }

  Widget _buildTaskList(List<Map<String, dynamic>> tasks, {String? emptyMessage, String? statusLabel, Color? statusColor}) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.task_alt,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage ?? 'No tasks available',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchAllTasks,
      child: ListView.builder(
        itemCount: tasks.length,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemBuilder: (context, index) {
          return _buildTaskCard(
            tasks[index],
            statusLabel: statusLabel,
            statusColor: statusColor,
          );
        },
      ),
    );
  }

  Widget _buildVerifiedBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified, color: Colors.green, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Verified User\nAadhar: XXXX XXXX ${_aadharNumber?.substring(_aadharNumber!.length - 4)}',
              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBarView() {
    return Column(
      children: [
        _buildVerifiedBanner(),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey.shade600,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.blue,
            ),
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.work_outline, size: 16),
                    const SizedBox(width: 4),
                    Text('Available (${_availableTasks.length})'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.schedule, size: 16),
                    const SizedBox(width: 4),
                    Text('Accepted (${_acceptedTasks.length})'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, size: 16),
                    const SizedBox(width: 4),
                    Text('Completed (${_completedTasks.length})'),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildTaskList(
                _availableTasks,
                emptyMessage: 'No available tasks at the moment',
              ),
              _buildTaskList(
                _acceptedTasks,
                emptyMessage: 'No accepted tasks',
                statusLabel: 'IN PROGRESS',
                statusColor: Colors.blue,
              ),
              _buildTaskList(
                _completedTasks,
                emptyMessage: 'No completed tasks yet',
                statusLabel: 'COMPLETED',
                statusColor: Colors.green,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          if (_isVerified)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchAllTasks,
            ),
        ],
      ),
      body: !_isVerified
          ? _buildVerificationPrompt()
          : _buildTabBarView(),
    );
  }
}