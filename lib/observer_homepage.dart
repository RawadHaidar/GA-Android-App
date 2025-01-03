import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:kicare_ml_firebase_server1/view_notifications_page.dart';

class ObserverHomePage extends StatefulWidget {
  const ObserverHomePage({super.key});

  @override
  State<ObserverHomePage> createState() => _ObserverHomePageState();
}

class _ObserverHomePageState extends State<ObserverHomePage> {
  final TextEditingController _serialNumberController = TextEditingController();
  final List<String> _serialNumbers = [];
  final List<Map<String, String>> _notifications = [];
  final Map<String, Map<String, dynamic>?> _previousData = {};

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  /// Initialize Flutter Local Notifications
  void _initializeNotifications() {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings =
        InitializationSettings(android: androidSettings);
    _localNotifications.initialize(initializationSettings);
  }

  /// Show a local notification
  Future<void> _showNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'fall_notifications_channel',
      'Fall Notifications',
      channelDescription: 'Notifications for fall detections and predictions',
      importance: Importance.max,
      priority: Priority.high,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);
    await _localNotifications.show(
      0,
      title,
      body,
      notificationDetails,
    );
  }

  /// Format Firestore Timestamp into readable string
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    final dateTime = timestamp.toDate();
    return DateFormat('MMMM dd, yyyy hh:mm:ss a').format(dateTime);
  }

  /// Remove a serial number
  void _removeSerialNumber(String serialNumber) {
    setState(() {
      _serialNumbers.remove(serialNumber);
      _previousData.remove(serialNumber);
    });
  }

  /// Add a new serial number
  void _addSerialNumber() {
    final serialNumber = _serialNumberController.text.trim();
    if (serialNumber.isNotEmpty && !_serialNumbers.contains(serialNumber)) {
      setState(() {
        _serialNumbers.add(serialNumber);
      });
      _serialNumberController.clear();
    }
  }

  /// Check for changes and add notifications
  void _checkForNotifications(String serialNumber, Map<String, dynamic> data) {
    final previous = _previousData[serialNumber];
    if (previous != null) {
      if (previous['falldetected'] != data['falldetected'] &&
          data['falldetected'] != null) {
        final notification = {
          'serialNumber': serialNumber,
          'message': 'Fall detected',
          'time': _formatTimestamp(data['falldetected']),
        };
        _notifications.add(notification);
        _showNotification('Fall Detected',
            'Serial: $serialNumber at ${notification['time']}');
      }
      if (previous['fallpredicted'] != data['fallpredicted'] &&
          data['fallpredicted'] != null) {
        final notification = {
          'serialNumber': serialNumber,
          'message': 'Fall predicted',
          'time': _formatTimestamp(data['fallpredicted']),
        };
        _notifications.add(notification);
        _showNotification('Fall Predicted',
            'Serial: $serialNumber at ${notification['time']}');
      }
    }
    _previousData[serialNumber] = Map<String, dynamic>.from(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Observer Home Page'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      NotificationsPage(notifications: _notifications),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                "Type your device serial number to get machine learning output from the cloud database."),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _serialNumberController,
                    decoration: InputDecoration(
                      labelText: 'Enter Serial Number',
                      hintText: 'e.g., 123456',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).primaryColor,
                          width: 2,
                        ),
                      ),
                      prefixIcon: Icon(
                        Icons.device_hub,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addSerialNumber,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _serialNumbers.length,
                itemBuilder: (context, index) {
                  final serialNumber = _serialNumbers[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    child: ListTile(
                      title:
                          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('devices')
                            .doc(serialNumber)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (!snapshot.hasData || !snapshot.data!.exists) {
                            return Text(
                              'No data for Serial Number: $serialNumber',
                              style: const TextStyle(fontSize: 16),
                            );
                          }

                          final data = snapshot.data!.data()!;
                          _checkForNotifications(serialNumber, data);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Serial Number: ${data['serialNumber'] ?? 'N/A'}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Last Updated: ${_formatTimestamp(data['timestamp'])}',
                              ),
                              Text(
                                'Activity: ${data['activity']}',
                              ),
                              Text(
                                'Fall Detected: ${_formatTimestamp(data['falldetected'])}',
                              ),
                              Text(
                                'Fall Predicted: ${_formatTimestamp(data['fallpredicted'])}',
                              ),
                              Text(
                                'Walk Deterioration: ${_formatTimestamp(data['walkdeterioration'])}',
                              ),
                            ],
                          );
                        },
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeSerialNumber(serialNumber),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
