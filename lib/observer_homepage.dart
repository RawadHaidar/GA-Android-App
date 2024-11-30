import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ObserverHomePage extends StatefulWidget {
  const ObserverHomePage({super.key});

  @override
  State<ObserverHomePage> createState() => _ObserverHomePageState();
}

class _ObserverHomePageState extends State<ObserverHomePage> {
  final TextEditingController _serialNumberController = TextEditingController();
  late Stream<DocumentSnapshot<Map<String, dynamic>>> _deviceDataStream;

  @override
  void initState() {
    super.initState();
    _serialNumberController.text = '123456'; // Default serial number
    _initializeStream();
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
                    // Text('Timestamp: ${_formatTimestamp(data['timestamp'])}'),
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
