// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
//
// class WorkScreen extends StatefulWidget {
//   final User user;
//   const WorkScreen({super.key, required this.user});
//
//   @override
//   State<WorkScreen> createState() => _WorkScreenState();
// }
//
// class _WorkScreenState extends State<WorkScreen> with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//   final Color _primaryColor = const Color(0xFF4CAF50);
//
//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 3, vsync: this);
//   }
//
//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F5F5),
//       appBar: AppBar(
//         elevation: 0,
//         backgroundColor: Colors.white,
//         title: const Text(
//           'Work Tasks',
//           style: TextStyle(
//             color: Color(0xFF424242),
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         bottom: TabBar(
//           controller: _tabController,
//           labelColor: _primaryColor,
//           unselectedLabelColor: Colors.grey,
//           indicatorColor: _primaryColor,
//           tabs: const [
//             Tab(text: 'Upcoming'),
//             Tab(text: 'In Progress'),
//             Tab(text: 'Completed'),
//           ],
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.search_rounded, color: Color(0xFF424242)),
//             onPressed: () {},
//           ),
//           IconButton(
//             icon: const Icon(Icons.filter_list_rounded, color: Color(0xFF424242)),
//             onPressed: () {},
//           ),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton(
//         backgroundColor: _primaryColor,
//         child: const Icon(Icons.add),
//         onPressed: () {},
//         elevation: 2,
//       ),
//       body: TabBarView(
//         controller: _tabController,
//         children: [
//           _buildTasksList('upcoming'),
//           _buildTasksList('in-progress'),
//           _buildTasksList('completed'),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildTasksList(String type) {
//     // Sample task data
//     final List<Map<String, dynamic>> tasks = [
//       {
//         'title': 'Harvest Corn Field',
//         'date': 'Today, 2:00 PM',
//         'priority': 'High',
//         'icon': Icons.agriculture,
//       },
//       {
//         'title': 'Check Irrigation System',
//         'date': 'Tomorrow, 9:00 AM',
//         'priority': 'Medium',
//         'icon': Icons.water_drop,
//       },
//       {
//         'title': 'Fertilize North Section',
//         'date': 'May 8, 10:00 AM',
//         'priority': 'Low',
//         'icon': Icons.grass,
//       },
//       {
//         'title': 'Meet With Suppliers',
//         'date': 'May 10, 1:30 PM',
//         'priority': 'Medium',
//         'icon': Icons.people,
//       },
//     ];
//
//     return AnimatedList(
//       initialItemCount: tasks.length,
//       padding: const EdgeInsets.all(16),
//       itemBuilder: (context, index, animation) {
//         final task = tasks[index];
//         return SlideTransition(
//           position: Tween<Offset>(
//             begin: const Offset(1, 0),
//             end: Offset.zero,
//           ).animate(CurvedAnimation(
//             parent: animation,
//             curve: Curves.easeOutQuint,
//           )),
//           child: _buildTaskCard(task),
//         );
//       },
//     );
//   }
//
//   Widget _buildTaskCard(Map<String, dynamic> task) {
//     // Priority color mapping
//     final Map<String, Color> priorityColors = {
//       'High': Colors.redAccent,
//       'Medium': Colors.orangeAccent,
//       'Low': Colors.greenAccent,
//     };
//
//     return Container(
//       margin: const EdgeInsets.only(bottom: 16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Material(
//         color: Colors.transparent,
//         borderRadius: BorderRadius.circular(16),
//         clipBehavior: Clip.antiAlias,
//         child: InkWell(
//           onTap: () {},
//           splashColor: _primaryColor.withOpacity(0.1),
//           highlightColor: _primaryColor.withOpacity(0.05),
//           child: Padding(
//             padding: const EdgeInsets.all(16),
//             child: Row(
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: _primaryColor.withOpacity(0.1),
//                     shape: BoxShape.circle,
//                   ),
//                   child: Icon(
//                     task['icon'],
//                     color: _primaryColor,
//                     size: 24,
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         task['title'],
//                         style: const TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w600,
//                           color: Color(0xFF424242),
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         task['date'],
//                         style: TextStyle(
//                           fontSize: 14,
//                           color: Colors.grey[600],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                   decoration: BoxDecoration(
//                     color: priorityColors[task['priority']]!.withOpacity(0.2),
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: Text(
//                     task['priority'],
//                     style: TextStyle(
//                       fontSize: 12,
//                       fontWeight: FontWeight.w500,
//                       color: priorityColors[task['priority']]!.withOpacity(0.8),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }


//=========================================================================================================



import 'package:flutter/material.dart';
import 'package:grovo_app/screens/farmer_work_dashboard.dart';
import 'package:grovo_app/screens/available_tasks_screen.dart';

class WorkScreen extends StatelessWidget {
  final dynamic user; // Adjust type as needed
  const WorkScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Work'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildWorkTile(
              context,
              icon: Icons.engineering,
              label: 'Hire Workers',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FarmerWorkDashboard()),
                );
              },
            ),
            _buildWorkTile(
              context,
              icon: Icons.work_outline,
              label: 'Find Work',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AvailableTasksScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkTile(BuildContext context,
      {required IconData icon,
        required String label,
        required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: Colors.green[700]),
              const SizedBox(height: 12),
              Text(label,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
