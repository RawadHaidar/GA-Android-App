import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class ObserverHomePage extends StatefulWidget {
  const ObserverHomePage({super.key});

  @override
  State<ObserverHomePage> createState() => _ObserverHomePageState();
}

class _ObserverHomePageState extends State<ObserverHomePage> {
  final TextEditingController _serialNumberController = TextEditingController();
  late Stream<DocumentSnapshot<Map<String, dynamic>>> _deviceDataStream;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Map<String, dynamic>? _previousData;

  @override
  void initState() {
    super.initState();
    _serialNumberController.text = '123456'; // Default serial number
    _initializeStream();
    _initializeNotifications();
  }

  /// Initialize the local notifications plugin
  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _localNotificationsPlugin.initialize(initializationSettings);
  }

  /// Send a local notification
  Future<void> _sendNotification(String title, String body) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'fall_notifications_channel', // Channel ID
      'Fall Notifications', // Channel name
      channelDescription: 'Notifications for fall-related events',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);

    await _localNotificationsPlugin.show(
      0, // Notification ID
      title,
      body,
      notificationDetails,
    );
  }

  void _initializeStream() {
    setState(() {
      _deviceDataStream = FirebaseFirestore.instance
          .collection('devices')
          .doc(_serialNumberController.text)
          .snapshots();
    });
  }

  void _updateSerialNumber() {
    _initializeStream();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Serial Number updated to: ${_serialNumberController.text}'),
      ),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    final dateTime = timestamp.toDate();
    return DateFormat('MMMM dd, yyyy \'at\' hh:mm:ss a z').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Observer Home Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Current Serial Number:'),
            TextField(
              controller: _serialNumberController,
              decoration: const InputDecoration(
                labelText: 'Serial Number',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) =>
                  _updateSerialNumber(), // Update the stream when serial number changes
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateSerialNumber,
              child: const Text('Update Serial Number'),
            ),
            const SizedBox(height: 20),
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _deviceDataStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Text(
                      'No data available for the selected serial number.');
                }

                final data = snapshot.data!.data()!;

                // Compare with previous data to detect changes
                if (_previousData != null) {
                  if (_previousData!['falldetected'] != data['falldetected']) {
                    _sendNotification(
                      'Fall Detected',
                      'A fall was detected at ${_formatTimestamp(data['falldetected'])}.',
                    );
                  }
                  if (_previousData!['fallpredicted'] !=
                      data['fallpredicted']) {
                    _sendNotification(
                      'Fall Predicted',
                      'A fall is predicted at ${_formatTimestamp(data['fallpredicted'])}.',
                    );
                  }
                  if (_previousData!['walkdeterioration'] !=
                      data['walkdeterioration']) {
                    _sendNotification(
                      'Walk Deterioration',
                      'Walk deterioration detected at ${_formatTimestamp(data['walkdeterioration'])}.',
                    );
                  }
                }

                // Update previous data
                _previousData = Map<String, dynamic>.from(data);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Serial Number: ${data['serialNumber'] ?? 'N/A'}',
                      style: const TextStyle(fontSize: 25),
                    ),
                    Text(
                      'Activity: ${data['activity'] ?? 'N/A'}',
                      style: const TextStyle(fontSize: 25),
                    ),
                    Text(
                      'Fall Detected: ${_formatTimestamp(data['falldetected'])}',
                      style: const TextStyle(fontSize: 25),
                    ),
                    Text(
                      'Fall Predicted: ${_formatTimestamp(data['fallpredicted'])}',
                      style: const TextStyle(fontSize: 25),
                    ),
                    Text(
                      'Walk Deterioration: ${_formatTimestamp(data['walkdeterioration'])}',
                      style: const TextStyle(fontSize: 25),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
