import 'package:flutter/material.dart';
import 'package:grovo_app/screens/request_worker_screen.dart';
import 'package:grovo_app/screens/my_requests_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:grovo_app/screens/accepted_workers_screen.dart';

class FarmerWorkDashboard extends StatelessWidget {
  final User user;
  const FarmerWorkDashboard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Work Management'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildMainTile(
              context,
              icon: Icons.add_circle_outline,
              title: 'Request a Worker',
              subtitle: 'Create a new work request',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RequestWorkerScreen(user: user), // ✅ pass again
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            _buildMainTile(
              context,
              icon: Icons.list_alt_outlined,
              title: 'My Requests',
              subtitle: 'View and manage your requests',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyRequestsScreen()),
                );
              },
            ),
            const SizedBox(height: 20),
            _buildMainTile(
              context,
              icon: Icons.work_outline,
              title: 'Accepted Workers',
              subtitle: 'Manage accepted or ongoing jobs',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AcceptedWorkersScreen(user: user),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainTile(BuildContext context,
      {required IconData icon,
        required String title,
        required String subtitle,
        required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, size: 40, color: Colors.green[800]),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: TextStyle(color: Colors.grey[700])),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16)
            ],
          ),
        ),
      ),
    );
  }
}
