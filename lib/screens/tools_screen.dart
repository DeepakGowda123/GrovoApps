import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ToolsScreen extends StatelessWidget {
  final User user;
  const ToolsScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final Color _primaryColor = const Color(0xFF4CAF50);
    final tools = [
      {
        'title': 'Weather Forecast',
        'icon': Icons.cloud,
        'description': 'Weather forecast for your location',
        'color': Colors.blueAccent,
      },
      {
        'title': 'Crop Calendar',
        'icon': Icons.calendar_today,
        'description': 'Plan your planting and harvesting',
        'color': Colors.orangeAccent,
      },
      {
        'title': 'Soil Analytics',
        'icon': Icons.landscape,
        'description': 'Check soil conditions and analytics',
        'color': Colors.brown,
      },
      {
        'title': 'Equipment Tracker',
        'icon': Icons.construction,
        'description': 'Track maintenance and usage',
        'color': Colors.deepPurpleAccent,
      },
      {
        'title': 'Market Prices',
        'icon': Icons.trending_up,
        'description': 'Check current market prices',
        'color': Colors.teal,
      },
      {
        'title': 'Pest Identification',
        'icon': Icons.bug_report,
        'description': 'Identify pests and find solutions',
        'color': Colors.redAccent,
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Tools',
          style: TextStyle(
            color: Color(0xFF424242),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Color(0xFF424242)),
            onPressed: () {},
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: GridView.builder(
          key: const ValueKey('tools_grid'),
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.9,
          ),
          itemCount: tools.length,
          itemBuilder: (context, index) {
            final tool = tools[index];
            return _buildToolCard(
              title: tool['title'] as String,
              icon: tool['icon'] as IconData,
              description: tool['description'] as String,
              color: tool['color'] as Color,
              onTap: () {
                _showToolDetails(context, tool);
              },
            );
          },
        ),
      ),
    );
  }

  void _showToolDetails(BuildContext context, Map<String, dynamic> tool) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(24),
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: (tool['color'] as Color).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                tool['icon'] as IconData,
                                color: tool['color'] as Color,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                tool['title'] as String,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF424242),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'About this tool',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF424242),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${tool['description']}\n\nThis feature is coming soon in the next app update. We\'re currently developing this tool to help farmers like you improve productivity and decision making.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'What to expect',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF424242),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildFeatureItem(
                          'Real-time data updates',
                          'Get the latest information instantly',
                          Icons.update,
                          Colors.blueAccent,
                        ),
                        _buildFeatureItem(
                          'Customizable alerts',
                          'Set notifications for important changes',
                          Icons.notifications_active,
                          Colors.orangeAccent,
                        ),
                        _buildFeatureItem(
                          'Detailed analytics',
                          'View comprehensive reports and insights',
                          Icons.analytics,
                          Colors.greenAccent,
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Notify me when available',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        // Add padding at the bottom to prevent overflow with the safe area
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFeatureItem(
      String title,
      String description,
      IconData icon,
      Color color,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF424242),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolCard({
    required String title,
    required IconData icon,
    required String description,
    required Color color,
    required Function() onTap,
  }) {
    return Hero(
      tag: 'tool_$title',
      child: Material(
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        color: Colors.white,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF424242),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}