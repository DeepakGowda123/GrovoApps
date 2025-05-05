import 'package:flutter/material.dart';

class AvailableTasksScreen extends StatelessWidget {
  const AvailableTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isAadharVerified = true; // Mocked value — link this to user profile

    if (!isAadharVerified) {
      return Scaffold(
        appBar: AppBar(title: const Text('Available Tasks')),
        body: const Center(
          child: Text(
            'Please complete Aadhar verification to access work opportunities.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final List<Map<String, dynamic>> tasks = [
      {
        'id': 'REQ1234',
        'workType': 'Plowing',
        'location': 'Village A',
        'payment': '₹1500',
        'duration': '2 days',
        'status': 'Open',
      },
      {
        'id': 'REQ5678',
        'workType': 'Harvesting',
        'location': 'Village B',
        'payment': '₹2000',
        'duration': '3 days',
        'status': 'Open',
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Available Tasks')),
      body: ListView.builder(
        itemCount: tasks.length,
        padding: const EdgeInsets.all(12),
        itemBuilder: (context, index) {
          final task = tasks[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              title: Text('${task['workType']} - ${task['payment']}'),
              subtitle: Text('${task['location']} • ${task['duration']}'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 18),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TaskDetailScreen(task: task),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class TaskDetailScreen extends StatelessWidget {
  final Map<String, dynamic> task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final isTaskAccepted = false; // Replace with real logic from backend

    return Scaffold(
      appBar: AppBar(title: Text('Task ${task['id']}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Work Type: ${task['workType']}'),
            Text('Location: ${task['location']}'),
            Text('Payment: ${task['payment']}'),
            Text('Duration: ${task['duration']}'),
            const SizedBox(height: 20),
            if (!isTaskAccepted)
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Task Accepted! (mock)')),
                  );
                },
                child: const Text('Accept Task'),
              ),
            if (isTaskAccepted)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Waiting for landlord verification...'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Verification requested.')),
                      );
                    },
                    child: const Text('Request Verification'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
