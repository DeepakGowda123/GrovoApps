// lib/widgets/heads_up_notification.dart
import 'package:flutter/material.dart';

class HeadsUpNotification extends StatefulWidget {
  final Map<String, dynamic> notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const HeadsUpNotification({
    Key? key,
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  }) : super(key: key);

  @override
  _HeadsUpNotificationState createState() => _HeadsUpNotificationState();
}

class _HeadsUpNotificationState extends State<HeadsUpNotification> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    _animationController.forward();

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _animationController.reverse().then((_) {
          widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnimation,
      child: Material(
        elevation: 8,
        child: InkWell(
          onTap: () {
            _animationController.reverse().then((_) {
              widget.onTap();
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Icon(Icons.notifications, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.notification['title'] ?? 'New Notification',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.notification['message'] ?? '',
                        style: const TextStyle(fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _animationController.reverse().then((_) {
                      widget.onDismiss();
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
