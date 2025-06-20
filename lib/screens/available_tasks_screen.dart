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

class _AvailableTasksScreenState extends State<AvailableTasksScreen> {
  bool _isLoading = true;
  bool _isVerified = false;
  String? _aadharNumber;
  String? _userPhone;
  List<Map<String, dynamic>> _availableTasks = [];

  @override
  void initState() {
    super.initState();
    _checkAadharStatus();
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

        await _fetchAvailableTasks();
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

    await _fetchAvailableTasks();

    _showSnackBar('Verification complete ✅');
  }

  Future<void> _fetchAvailableTasks() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final farmersSnapshot = await FirebaseFirestore.instance.collection('farmers').get();

    final List<Map<String, dynamic>> tasks = [];

    for (var farmerDoc in farmersSnapshot.docs) {
      if (farmerDoc.id == user.uid) continue;

      final workerRequests = await FirebaseFirestore.instance
          .collection('farmers')
          .doc(farmerDoc.id)
          .collection('workerRequests')
          .get();

      for (var taskDoc in workerRequests.docs) {
        final data = taskDoc.data();
        if (data['status'] == 'paid') {
          tasks.add({...data, 'id': taskDoc.id});
        }
      }
    }

    setState(() => _availableTasks = tasks);
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

  Widget _buildTaskList() {
    return ListView.builder(
      itemCount: _availableTasks.length,
      padding: const EdgeInsets.all(12),
      itemBuilder: (context, index) {
        final task = _availableTasks[index];

        // Defensive null check
        if (task == null) {
          return const SizedBox.shrink(); // Or show error widget
        }

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            title: Text('${task['workType']} - ₹${task['amount']}'),
            subtitle: Text('${task['location']} • ${task['workDuration']}'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 18),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TaskDetailScreen(
                    task: task,
                    taskId: task['id'], // ✅ FIXED: Use task['id'] instead of doc.id
                  ),
                ),
              );
            },
          ),
        );
      },
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Available Tasks')),
      body: !_isVerified ? _buildVerificationPrompt() : Column(children: [_buildVerifiedBanner(),Expanded(child: _buildTaskList()),
      ]
      ) ,
    );
  }
}