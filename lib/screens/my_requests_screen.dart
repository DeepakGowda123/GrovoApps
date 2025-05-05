import 'package:flutter/material.dart';

class MyRequestsScreen extends StatelessWidget {
  const MyRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy data
    final List<Map<String, dynamic>> requests = [
      {
        'id': 'REQ1234',
        'workType': 'Plowing',
        'location': 'Village A',
        'startDate': '2025-05-10',
        'status': 'Pending',
        'worker': null,
      },
      {
        'id': 'REQ5678',
        'workType': 'Harvesting',
        'location': 'Village B',
        'startDate': '2025-05-08',
        'status': 'Accepted',
        'worker': 'Raju Singh',
      },
      {
        'id': 'REQ9999',
        'workType': 'Irrigation',
        'location': 'Village C',
        'startDate': '2025-05-01',
        'status': 'Completed',
        'worker': 'Amit Kumar',
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('My Requests')),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final request = requests[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: CircleAvatar(child: Text('${index + 1}')),
              title: Text('${request['workType']} (${request['location']})'),
              subtitle: Text('Start: ${request['startDate']}'),
              trailing: _buildStatusChip(request['status']),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RequestDetailScreen(request: request),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
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
    return Chip(label: Text(status), backgroundColor: color.withOpacity(0.2), labelStyle: TextStyle(color: color));
  }
}

class RequestDetailScreen extends StatelessWidget {
  final Map<String, dynamic> request;

  const RequestDetailScreen({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final isCompleted = request['status'] == 'Completed';
    final isAccepted = request['worker'] != null;

    return Scaffold(
      appBar: AppBar(title: Text('Request ${request['id']}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Work Type: ${request['workType']}'),
            Text('Location: ${request['location']}'),
            Text('Start Date: ${request['startDate']}'),
            const SizedBox(height: 12),
            Text('Status: ${request['status']}'),
            if (isAccepted) ...[
              const SizedBox(height: 10),
              Text('Assigned Worker: ${request['worker']}'),
            ],
            const Spacer(),
            if (!isCompleted && isAccepted)
              ElevatedButton(
                onPressed: () {
                  // TODO: mark as complete
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Marked as Complete (mock)')),
                  );
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
