// lib/services/notification_service.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

// Top-level function to handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Need to ensure Firebase is initialized
  // await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

// This is the HeadsUpNotification widget.
class HeadsUpNotification extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, // This will handle tapping the notification
      child: Container(
        padding: const EdgeInsets.all(16.0),
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
        decoration: BoxDecoration(
          color: Colors.blueAccent, // You can change the color here
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // The notification title and message
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification['title'] ?? '',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  notification['message'] ?? '',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.0,
                  ),
                ),
              ],
            ),
            // Close button
            IconButton(
              icon: Icon(Icons.close, color: Colors.white),
              onPressed: onDismiss, // This will remove the notification
            ),
          ],
        ),
      ),
    );
  }
}






class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Create a notification channel for Android
  final AndroidNotificationChannel _channel = const AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description: 'This channel is used for important notifications.', // description
    importance: Importance.high,
    playSound: true,
  );

  // Stream controller to manage the in-app notifications stream
  final StreamController<Map<String, dynamic>> _notificationStreamController =
  StreamController<Map<String, dynamic>>.broadcast();

  // Global key for accessing the overlay entry
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  OverlayEntry? _overlayEntry;

  // Public getter for the notification stream
  Stream<Map<String, dynamic>> get notificationStream => _notificationStreamController.stream;

  // Initialize notification settings
  Future<void> initialize() async {
    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) {
        _handleNotificationTap(notificationResponse.payload);
      },
    );

    // Create the notification channel on Android
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Initialize FCM
    await _initializeFCM();
  }

  Future<void> _initializeFCM() async {
    // Request permission for iOS
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Set up handlers for different app states
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // App in foreground state
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleForegroundMessage(message);
    });

    // App in background but opened
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message.data.toString());
    });

    // Get the token
    String? token = await _fcm.getToken();
    if (token != null) {
      print("FCM Token: $token");
      _saveFCMToken(token);
    }

    // Listen for token refresh
    _fcm.onTokenRefresh.listen((String token) {
      _saveFCMToken(token);
    });

    // Check if app was opened from a notification
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage.data.toString());
    }
  }

  Future<void> _saveFCMToken(String token) async {
    // Save token to Firestore
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    // Store notification in Firestore if needed
    _saveNotificationToFirestore(message);

    // Show heads-up notification if notification payload exists
    if (notification != null && android != null) {
      _flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            icon: android.smallIcon ?? '@mipmap/ic_launcher',
            priority: Priority.high,
            importance: Importance.high,
            playSound: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.toString(),
      );

      // Also show in-app notification
      showInAppNotification({
        'title': notification.title,
        'message': notification.body,
        'data': message.data,
      });
    }
  }

  Future<void> _saveNotificationToFirestore(RemoteMessage message) async {
    final user = _auth.currentUser;
    if (user != null) {
      final notification = message.notification;
      if (notification != null) {
        await _firestore.collection('notifications').add({
          'userId': user.uid,
          'title': notification.title,
          'message': notification.body,
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
          'orderId': message.data['orderId'],
          'type': message.data['type'] ?? 'general',
        });
      }
    }
  }

  void _handleNotificationTap(String? payload) {
    // Navigate to the appropriate screen based on payload
    if (payload != null && payload.contains('orderId')) {
      // Parse the payload and navigate to order details
      // You'll need to implement this based on your app's navigation
      print("Should navigate to order with payload: $payload");
    }
  }

  // Fetch unread notifications from Firestore for the current user
  Stream<List<DocumentSnapshot>> getUnreadNotificationsStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  // Mark a notification as read in Firestore
  Future<void> markAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({'read': true});
  }

  // Add a new in-app notification and play sound
  void showInAppNotification(Map<String, dynamic> notification) {
    _notificationStreamController.add(notification); // Emit the notification to the stream
    _playNotificationSound(); // Play sound

    // Here you would show the heads-up notification UI
    // This would integrate with your HeadsUpNotification widget
    _showHeadsUpNotification(notification);
  }

  // Show a heads-up notification using your custom widget
  void _showHeadsUpNotification(Map<String, dynamic> notification) {
    // Only show if navigator key is attached to a context
    if (navigatorKey.currentContext != null) {
      // Remove any existing overlay
      _removeHeadsUpNotification();

      // Create a new overlay entry with your HeadsUpNotification widget
      _overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Material(
            color: Colors.transparent,
            child: SafeArea(
              child: Builder(
                builder: (context) {
                  return HeadsUpNotification(
                    notification: notification,
                    onTap: () {
                      _removeHeadsUpNotification();
                      _handleNotificationTap(notification['data'].toString());
                    },
                    onDismiss: _removeHeadsUpNotification,
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Insert the overlay
      if (_overlayEntry != null) {
        Overlay.of(navigatorKey.currentContext!).insert(_overlayEntry!);
      }
    }
  }


  // Remove heads-up notification overlay
  void _removeHeadsUpNotification() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
  }

  // Play the notification sound
  Future<void> _playNotificationSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/notification.mp3'));
    } catch (e) {
      print("Error playing notification sound: $e");
    }
  }

  // Function to show all unread notifications when app opens
  Future<void> showUnreadNotifications() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final unreadDocs = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .where('read', isEqualTo: false)
        .get();

    for (var doc in unreadDocs.docs) {
      final data = doc.data();
      showInAppNotification({
        'title': data['title'],
        'message': data['message'],
        'data': {'orderId': data['orderId']},
      });
      // Add a small delay between notifications to avoid overlap
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  // Send a test notification (for debugging)
  Future<void> sendTestNotification() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Create a test notification in Firestore
    final docRef = await _firestore.collection('notifications').add({
      'userId': user.uid,
      'title': 'Test Notification',
      'message': 'This is a test notification',
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
      'type': 'test',
    });

    // Show the notification
    showInAppNotification({
      'title': 'Test Notification',
      'message': 'This is a test notification',
      'data': {'notificationId': docRef.id},
    });
  }

  // Dispose the controller and other resources
  void dispose() {
    _notificationStreamController.close();
    _audioPlayer.dispose();
    _removeHeadsUpNotification();
  }
}